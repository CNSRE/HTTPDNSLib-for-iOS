//
//  WBDNSLogFile.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/27.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSLogFile.h"

@implementation WBDNSLogFile

- (instancetype)initWithPath:(NSString *)filePath {
    NSDictionary* fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    if (fileInfo == nil) {
        NSLog(@"ERROR:%s:%d: filePath(%@) is invalid.",__func__,__LINE__, filePath);
        return nil;
    }
    
    if ((self = [super init])) {
        _filePath = [filePath copy];
        _fileName = [filePath lastPathComponent];
        _createDate = fileInfo[NSFileCreationDate];
        _modifyDate = fileInfo[NSFileModificationDate];
        _fileSize = [fileInfo[NSFileSize] integerValue];
        
    }
    return self;
}

@end
