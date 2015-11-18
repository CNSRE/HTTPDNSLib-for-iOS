//
//  DNSCacheManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/3.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSDBManager.h"
#import "WBDNSTools.h"
#import "WBDNSCache.h"
@protocol WBDNSCacheProtocol <NSObject>

- (void)addMemoryCache:(NSString *)url model:(WBDNSDomainModel *)model;
- (WBDNSDomainModel *)getDnsCache:(NSString *)sp url:(NSString *)url;
- (WBDNSDomainModel *)insertDnsCache:(WBDNSHttpDnsPack *) dnsPack;
- (NSArray *)getExpireDnsCache;
- (NSArray *)getAllModels;
- (BOOL)updateIpModelSpeedInfoInCacheAndDB:(WBDNSDomainModel *)model;

//本函数只用于更新从本地dns获取的ip， 从httpserver 获取的ip 不应该用此函数更新。
- (void)updateMemoryCache:(NSString *)domain model:(WBDNSDomainModel *)model;

- (void)clear;
- (void)clearDB;
- (void)clearMemoryCache;


@end

@interface WBDNSCacheManager : NSObject<WBDNSCacheProtocol>

+(instancetype) sharedInstance;

- (NSArray *)getAllModelsFromDB;

@end
