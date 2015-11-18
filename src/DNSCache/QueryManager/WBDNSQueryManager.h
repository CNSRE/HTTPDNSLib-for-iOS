//
//  QueryManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/4.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSModel.h"
#import "WBDNSCacheManager.h"

@protocol WBDNSQueryManagerProtocol <NSObject>

- (WBDNSDomainModel *)queryDomainIp:(NSString *)sp host:(NSString *)host;

@end

@interface WBDNSQueryManager : NSObject <WBDNSQueryManagerProtocol>

- (instancetype)initWithDnsCacheManager:(id<WBDNSCacheProtocol>)DnsCacheManager;

@end
