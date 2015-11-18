// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2015, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.
//
//  updated by Robert Yang on 15/8/27.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSLogger.h"
#import "WBDNSLogFile.h"
#import "WBDNSConfigManager.h"
#import "WBDNSTools.h"
#import <UIKit/UIKit.h>

NSUInteger const WBDNS_DEFAULT_MAX_LOG_FILE_SIZE = 512*1024; //512KB

NSUInteger const WBDNS_DEFAULT_MAX_LOG_FILE_NUM = 10;

@implementation WBDNSLogger
{
    NSUInteger _maxFileSize;
    NSUInteger _maxFileNum;
    NSString *_logDirectory;
    NSDateFormatter *_dateFormatter;
    NSFileHandle *_currentFileHandle;
    WBDNSLogFile *_currentLogFile;
    dispatch_queue_t _loggerQueue;
    dispatch_source_t _currentLogFileVnode;
    NSMutableDictionary *_runningUploadTask;
}


+ (instancetype)sharedInstance {
    static WBDNSLogger* sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WBDNSLogger alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithLogDirectory:nil];
}

- (void)dealloc {
    if (_currentFileHandle) {
        [_currentFileHandle synchronizeFile];
        [_currentFileHandle closeFile];
        _currentFileHandle = nil;
    }
    
    if (_currentLogFileVnode) {
        dispatch_source_cancel(_currentLogFileVnode);
        _currentLogFileVnode = NULL;
    }
}

- (instancetype)initWithLogDirectory:(NSString *)logDirectory {
    if ((self = [super init])) {
        _maxFileNum = WBDNS_DEFAULT_MAX_LOG_FILE_NUM;
        _maxFileSize = WBDNS_DEFAULT_MAX_LOG_FILE_SIZE;
        
        if (logDirectory) {
            _logDirectory = [logDirectory copy];
        } else {
            _logDirectory = [[self defaultLogDirectory] copy];
        }
        
        _dateFormatter = [[NSDateFormatter alloc]init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        _loggerQueue = dispatch_queue_create([@"com.weibo.dnscache.fileLogger" UTF8String], NULL);
        _runningUploadTask = [NSMutableDictionary dictionary];
        [self getLogDirectory];
    }
    
    return self;
}

- (NSString *)defaultLogDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *logDirectory = [baseDir stringByAppendingPathComponent:@"WBDNSLogs"];
    
    return logDirectory;
}

- (NSString *) getLogDirectory {
    if (![[NSFileManager defaultManager] fileExistsAtPath:_logDirectory]) {
        NSError *err = nil;
        
        if (![[NSFileManager defaultManager] createDirectoryAtPath:_logDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&err]) {
            NSLog(@"ERROR:%s:%d Error creating logDirectory: %@",__func__,__LINE__, err);
        }
    }
    return _logDirectory;
}


- (void)logMessage:(NSString*)message {
    if (message == nil) {
        NSLog(@"ERROR:%s:%d Error message is nil",__func__,__LINE__);
        return;
    }
    NSData *logData = [message dataUsingEncoding:NSUTF8StringEncoding];
    dispatch_async(_loggerQueue, ^{
        @try {
            [[self currentLogFileHandle] writeData:logData];
            [self maybeRollLogFileDueToSize];
        }
        @catch (NSException *exception) {
            NSLog(@"ERROR:%s:%d writeing data to file failed.",__func__,__LINE__);
        }
    });
}

- (NSFileHandle *)currentLogFileHandle {
    if (_currentFileHandle == nil) {
        NSString *logFilePath = [[self currentLogFile] filePath];
        _currentFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        [_currentFileHandle seekToEndOfFile];
        
        if (_currentFileHandle) {
            // Here we are monitoring the log file. In case if it would be deleted ormoved
            // somewhere we want to roll it and use a new one.
            _currentLogFileVnode = dispatch_source_create(
                                                          DISPATCH_SOURCE_TYPE_VNODE,
                                                          [_currentFileHandle fileDescriptor],
                                                          DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME,
                                                          _loggerQueue
                                                          );
            
            dispatch_source_set_event_handler(_currentLogFileVnode, ^{ @autoreleasepool {
                [self rollLogFileNow];
            } });
            
            dispatch_resume(_currentLogFileVnode);
        }
    }
    return _currentFileHandle;
}

-(WBDNSLogFile *) currentLogFile {
    if (_currentLogFile == nil) {
        NSArray *sortedLogFiles = [self sortedLogFiles];
        
        if ([sortedLogFiles count] > 0) {
            WBDNSLogFile* recentFile = [sortedLogFiles firstObject];
            if (recentFile.fileSize < WBDNS_DEFAULT_MAX_LOG_FILE_SIZE) {
                _currentLogFile = recentFile;
            }
        }
        
        if (_currentLogFile == nil) {
            NSString *currentLogFilePath = [self createNewLogFile];
            _currentLogFile = [[WBDNSLogFile alloc] initWithPath:currentLogFilePath];
        }
    }
    
    return _currentLogFile;
}

- (void)rollLogFileNow {
    if (_currentFileHandle == nil) {
        return;
    }
    
    [_currentFileHandle synchronizeFile];
    [_currentFileHandle closeFile];
    _currentFileHandle = nil;
    _currentLogFile = nil;
    
    if (_currentLogFileVnode) {
        dispatch_source_cancel(_currentLogFileVnode);
        _currentLogFileVnode = NULL;
    }
}



- (void)maybeRollLogFileDueToSize {
    // This method is called from logMessage.
    // Keep it FAST.
    // Note: Use direct access to maximumFileSize variable.
    // We specifically wrote our own getter/setter method to allow us to do this (for performance reasons).
    
    if (_maxFileNum > 0) {
        unsigned long long fileSize = [_currentFileHandle offsetInFile];
        
        if (fileSize >= _maxFileSize) {
            [self rollLogFileNow];
        }
    }
}



- (NSString *)newLogFileName {
    
    NSString *formattedDate = [_dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat:@"WBDNS %@.log", formattedDate];
}

/**
 * Generates a new unique log file path, and creates the corresponding log file.
 **/
- (NSString *)createNewLogFile {
    NSString *fileName = [self newLogFileName];
    NSString *logsDirectory = [self getLogDirectory];
    
    NSUInteger attempt = 1;
    
    do {
        NSString *actualFileName = fileName;
        
        if (attempt > 1) {
            NSString *extension = [actualFileName pathExtension];
            
            actualFileName = [actualFileName stringByDeletingPathExtension];
            actualFileName = [actualFileName stringByAppendingFormat:@" %lu", (unsigned long)attempt];
            
            if (extension.length) {
                actualFileName = [actualFileName stringByAppendingPathExtension:extension];
            }
        }
        
        NSString *filePath = [logsDirectory stringByAppendingPathComponent:actualFileName];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            
            NSDictionary *attributes = nil;
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:attributes];
            
            // Since we just created a new log file, we may need to delete some old log files
            [self deleteOldLogFiles];
            
            return filePath;
        } else {
            attempt++;
        }
    } while (YES);
}

- (void)deleteOldLogFiles {
    NSArray *sortedLogFileInfos = [self sortedLogFiles];
    NSUInteger firstIndexToDelete = NSNotFound;
    
    if (_maxFileNum) {
        if (firstIndexToDelete == NSNotFound) {
            firstIndexToDelete = _maxFileNum;
        } else {
            firstIndexToDelete = MIN(firstIndexToDelete, _maxFileNum);
        }
    }
    
    if (firstIndexToDelete != NSNotFound) {
        // removing all logfiles starting with firstIndexToDelete
        for (NSUInteger i = firstIndexToDelete; i < sortedLogFileInfos.count; i++) {
            WBDNSLogFile *logFileInfo = sortedLogFileInfos[i];
            [[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:nil];
        }
    }
}

-(NSArray *)sortedLogFiles {
    NSArray* sortedLogFiles = [[self unsortedLogFiles]sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *date1 = [obj1 createDate];
        NSDate *date2 = [obj2 createDate];
        
        NSComparisonResult result = [date1 compare:date2];
        
        if (result == NSOrderedAscending) {
            return NSOrderedDescending;
        }
        
        if (result == NSOrderedDescending) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
        
    }];
    return sortedLogFiles;
}

- (void)uploadLogFiles {
    dispatch_async(_loggerQueue, ^{
        [self rollLogFileNow];
        NSArray* array = [self unsortedLogFiles];
        for (WBDNSLogFile* logFile in array) {
            [self uploadLogFile:logFile];
        }
    });
}

- (void)uploadLogFile:(WBDNSLogFile *)logFile {
    dispatch_async(_loggerQueue, ^{
        
        if (logFile == nil) {
            NSLog(@"ERROR:%s:%d input logFile is nil.",__func__, __LINE__);
            return;
        }
        
        if (logFile.filePath == nil) {
            NSLog(@"ERROR:%s:%d input logFile.filePath is nil.",__func__, __LINE__);
            return;
        }
        
        if (_runningUploadTask[logFile.filePath]) {
            return;
        }
        
        NSString * filePath = logFile.filePath;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSLog(@"WARNING:%s:%d input logFile is not exist.",__func__, __LINE__);
            return;
        }
        
        [_runningUploadTask setObject:@"NonNull" forKey:filePath];
        if ([filePath isEqualToString:_currentLogFile.filePath]) {
            [self rollLogFileNow];
        }
        NSString* urlPrefix = [[WBDNSConfigManager sharedInstance] getLogServerUrl];
        
        NSString *identifierForVendor = [[UIDevice currentDevice].identifierForVendor UUIDString];
        NSString *secureCode = [WBDNSTools md5:[NSString stringWithFormat:@"%@%@",identifierForVendor,@"iheRFsFhLE9h9TRHVRLLBD6eS9ccQdLe"]];
        NSString* urlString = [NSString stringWithFormat:@"%@?c=httpdns&did=%@&s=%@",urlPrefix,identifierForVendor, [secureCode lowercaseString]];
        NSURL* url = [NSURL URLWithString:urlString];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
        
        [request setHTTPMethod:@"POST"];
        
//        NSString* boundary = @"1342578690";
//        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8;boundary=%@", boundary];
        NSString *contentType = @"application/x-www-form-urlencoded";
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        NSData* data = [self getUploadbody2:[NSData dataWithContentsOfFile:logFile.filePath]];
        
        NSURLSession* session = [NSURLSession sharedSession];
        session.sessionDescription = urlPrefix;
        NSURLSessionUploadTask* dataTask = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(_loggerQueue, ^{
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                if (httpResponse.statusCode == 200) {
                    //This function need to be executed in _loggerQueue, as it may conflict with other file operation.
                    [self removeFile:logFile];
                }
                else
                {
                    [[WBDNSConfigManager sharedInstance]setServerUrlFailedTimes:session.sessionDescription];
                    NSLog(@"ERROR:%s:%d: upload file failed. reason:%@", __func__,__LINE__, error.localizedDescription);
                }
                [_runningUploadTask removeObjectForKey:filePath];
            });
        }];
        [dataTask resume];
        [session finishTasksAndInvalidate];
    });
    
}

- (NSData *)getUploadBody:(NSString *)boundary fileData:(NSData *)fileData {
    NSMutableData *postData = [NSMutableData data];
    [postData appendData: [[NSString stringWithFormat:@"--%@\r\n", boundary]
                           dataUsingEncoding:NSUTF8StringEncoding]];//开始标志
    
    [postData appendData: [[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"File1\";filename=\"httpdns.log\"\r\nContent-type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];//name是页面文件的参数，type是文件类型
    [postData appendData:fileData];// 文件数据
    [postData appendData: [[NSString stringWithFormat:@"\r\n--%@--\r\n",  boundary]dataUsingEncoding:NSUTF8StringEncoding]];// 文件结束标志
    
    return postData;
}

- (NSData *) getUploadbody2:(NSData *)fileData {
    NSMutableData *postData = [NSMutableData data];
    [postData appendData: [@"log=[" dataUsingEncoding:NSUTF8StringEncoding]];//开始标志
    NSMutableString* fileString = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    [fileString deleteCharactersInRange:NSMakeRange(fileString.length -1, 1)];
    [postData appendData:[fileString dataUsingEncoding:NSUTF8StringEncoding] ];// 文件数据
    [postData appendData: [@"]" dataUsingEncoding:NSUTF8StringEncoding]];// 文件结束标志
    
    return postData;
}



- (NSArray *)unsortedLogFiles {
    NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];
    
    NSMutableArray *unsortedLogFiles = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];
    
    for (NSString *filePath in unsortedLogFilePaths) {
        WBDNSLogFile *logFileInfo = [[WBDNSLogFile alloc] initWithPath:filePath];
        if (logFileInfo) {
            [unsortedLogFiles addObject:logFileInfo];
        }
    }
    
    return unsortedLogFiles;
}


- (NSArray *)unsortedLogFilePaths {
    NSString* logsDirectory = [self getLogDirectory];
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil];
    NSMutableArray *unsortedLogFilePaths = [NSMutableArray arrayWithCapacity:[fileNames count]];
    
    for (NSString* fileName in fileNames) {
        NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
        
        [unsortedLogFilePaths addObject:filePath];
    }
    return unsortedLogFilePaths;
}


- (void)removeFile:(WBDNSLogFile *)logFile {
    if (logFile == nil || logFile.filePath == nil) {
        NSLog(@"ERROR:%s:%d input logFile is nil.",__func__, __LINE__);
        return;
    }
    
    if ([logFile.filePath isEqualToString:_currentLogFile.filePath]) {
        [self rollLogFileNow];
    }
    NSError* error;
    [[NSFileManager defaultManager]removeItemAtPath:logFile.filePath error:&error];
    if (error) {
        NSLog(@"ERROR:%s:%d remove logFile failed, reason:%@.",__func__, __LINE__, error.localizedDescription);
    }
    
}

@end
