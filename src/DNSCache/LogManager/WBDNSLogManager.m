//
//  WBDNSLogManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/27.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSLogManager.h"
#import "WBDNSLogger.h"
#import "WBDNSConfigManager.h"
#import "WBDNSTools.h"
#import "WBDNSLogFile.h"

@implementation WBDNSLogManager {
    WBDNSLogger *_logger;
    NSString *_appVersion;
}

+ (instancetype)sharedInstance {
    static WBDNSLogManager* sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WBDNSLogManager alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _logger = [WBDNSLogger sharedInstance];
        NSString *notificationName = @"UIApplicationWillTerminateNotification";
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate)
                                                     name:notificationName
                                                   object:nil];
    }
    
    return self;
}

- (void)applicationWillTerminate {
    [_logger rollLogFileNow];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)uploadLogFiles {
    [_logger uploadLogFiles];
}

- (void)removeLogFile:(WBDNSLogFile *)logFile {
    [_logger removeFile:logFile];
}

- (NSString *)generateJsonStrByLogType:(int)type action:(NSString *)action body:(NSDictionary *)body {
    NSDictionary* dic = @{@"type":@(type),
                          @"action":action,
                          @"content":body,
                          @"versionName":[WBDNSConfigManager getAppVersion],
                          @"did":@"iOSCan'tGetDid",
                          @"appkey":[WBDNSConfigManager getAppkey],
                          @"timestamp":[[WBDNSTools sharedInstance] stringFromDate:[NSDate date]]
                          };
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return myString;
}


+ (void)log:(int)type action:(NSString *)action body:(NSDictionary *)body {
    [[WBDNSLogManager sharedInstance] writeLog:type action:action body:body];
}

+ (void)log:(int)type action:(NSString *)action body:(NSDictionary *) body samplingRate:(int)samplingRate {
    [[WBDNSLogManager sharedInstance] writeLog:type action:action body:body samplingRate:samplingRate];
}


- (void)writeLog:(int)type action:(NSString *)action body:(NSDictionary *) body {
    [self writeLog:type action:action body:body samplingRate:1];
}

- (void)writeLog:(int)type action:(NSString *)action body:(NSDictionary *)body samplingRate:(int) samplingRate {
    if (samplingRate <= 0) {
        return;
    }
    //安卓版本对采样率的定义是，采样率是50 就代表50次取一次。ios版本的理解是 50%，这里适配安卓的理解。
    float androidSamplingRate = 1.0f/samplingRate;
    float temp = ((float)(arc4random()%1000000))/1000000 ;
    if (temp > androidSamplingRate) {
        return;
    }
    
    NSString* message = [self generateJsonStrByLogType:type action:action body:body];
    NSString* newMessage = [NSString stringWithFormat:@"%@,", message];
    [_logger logMessage:newMessage];
}

@end
