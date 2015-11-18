//
//  WBDNSLogManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/27.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum WBDNS_LOG_TYPE
{
    WBDNS_LOG_TYPE_ERROR = 1,
    WBDNS_LOG_TYPE_INFO =2,
    WBDNS_LOG_TYPE_SPEED = 3
} WBDNS_LOG_TYPE;

#define WBDNS_LOG_ACTION_INFO_DOMAIN  @"httpdns_domaininfo"
#define WBDNS_LOG_ACTION_INFO_PACK  @"httpdns_packinfo"
#define WBDNS_LOG_ACTION_INFO_CONFIG  @"httpdns_configinfo"
#define WBDNS_LOG_ACTION_ERR_SPINFO  @"httpdns_errspinfo"
#define WBDNS_LOG_ACTION_ERR_DOMAININFO  @"httpdns_errdomaininfo"

@interface WBDNSLogManager : NSObject

- (void)uploadLogFiles;

+ (instancetype)sharedInstance;

+ (void)log:(int)type action:(NSString*)action body:(NSDictionary*)body;

+ (void)log:(int)type action:(NSString*)action body:(NSDictionary*)body samplingRate:(int)samplingRate;

@end
