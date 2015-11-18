//
//  WBDNSLogger.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/27.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WBDNSLogFile;
@interface WBDNSLogger : NSObject

+ (instancetype)sharedInstance;

- (void)logMessage:(NSString *)Message;

- (NSArray *)unsortedLogFiles;

- (void)removeFile:(WBDNSLogFile *)logFile;

- (void)uploadLogFiles;

- (void)rollLogFileNow;

@end
