//
//  WBDNSMemeryCache.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/10.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSDomainModel.h"
@interface WBDNSMemeryCache : NSMutableDictionary

+ (instancetype)sharedInstance;
- (WBDNSDomainModel *)getModelByKeyUrl:(NSString*)keyUrl;
- (void)addModel:(WBDNSDomainModel *)model keyUrl:(NSString*)keyUrl;
- (void)updateModel:(WBDNSDomainModel *)model keyUrl:(NSString*)keyUrl;
- (NSArray *)getExpireDnsCache;
- (void)removeAllModels;
- (NSArray *)getAllModels;

@end
