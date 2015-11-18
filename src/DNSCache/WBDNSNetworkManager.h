//
//  NetworkManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/4.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSReachability.h"
#import "WBDNSCacheManager.h"

/**
 * 无网络
 */
#define WBDNS_NETWORK_TYPE_UNCONNECTED -1
/**
 * 未知网络
 */
#define WBDNS_NETWORK_TYPE_UNKNOWN 0
/**
 * WIFI网络
 */
#define WBDNS_NETWORK_TYPE_WIFI 1
/**
 * 运营商网络
 */
#define WBDNS_NETWORK_TYPE_MOBILE 2


/**
 * 未知运营商
 */
#define WBDNS_MOBILE_UNKNOWN 0  // 未知运营商
/**
 * mobile-中国电信
 */
#define WBDNS_MOBILE_TELCOM 3  // 中国电信
/**
 * mobile-中国联通
 */
#define WBDNS_MOBILE_UNICOM 5 // 中国联通
/**
 * mobile-中国移动
 */
#define WBDNS_MOBILE_CHINAMOBILE 4 // 中国移动

static NSString* WBDNSNetworkStatusChangeNotification = @"WBDNSNetworkStatusChangeNotification";

@interface WBDNSNetworkManager : NSObject

@property (atomic, strong) NSString *lastSpTypeString;
@property (atomic, strong) NSString *currentSpTypeString;
@property (atomic, assign) int networkType;
@property (atomic, strong) NSString *networkTypeString;

+ (instancetype)sharedInstance;
- (void)setDnsCacheManager:(id<WBDNSCacheProtocol>)dnsCacheManager;

@end
