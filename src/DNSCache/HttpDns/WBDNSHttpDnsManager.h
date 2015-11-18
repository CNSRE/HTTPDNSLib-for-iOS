//
//  HttpDnsManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/4.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSModel.h"
#import "WBDNSCache.h"
@protocol WBDNSHttpDnsProtocol

- (void)requestHttpDnsByDomain:(NSString *)domain completionHandler:(void(^)(WBDNSHttpDnsPack *))completionHandler;

@end

@interface WBDNSHttpDnsManager : NSObject <WBDNSHttpDnsProtocol>

@end
