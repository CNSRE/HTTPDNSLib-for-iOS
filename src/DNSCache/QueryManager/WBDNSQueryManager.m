//
//  QueryManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/4.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSQueryManager.h"
#import "WBDNSConfig.h"
#import "WBDNSConfigManager.h"
#import "WBDNSSortManager.h"
#import <netdb.h>
#import <sys/socket.h>

@implementation WBDNSQueryManager
{
    id<WBDNSCacheProtocol> _manager;
}

- (instancetype)initWithDnsCacheManager:(id<WBDNSCacheProtocol>)dnsCacheManager
{
    if (self = [super init]) {
        _manager = dnsCacheManager;
    }
    return  self;
}

- (WBDNSDomainModel *)queryDomainIp:(NSString *)sp host:(NSString *)host
{
    WBDNSDomainModel* domainModel = nil;
    
    if ([[WBDNSConfigManager sharedInstance] isSupportedDomain:host] && [WBDNSConfigManager sharedInstance].config.enableRequestFromSinaHttpDnsServer) {
        domainModel = [[_manager getDnsCache:sp url:host] copy];
        if ([WBDNSConfigManager sharedInstance].config.enableSDKUpdateServerIpOrder) {
            domainModel = [WBDNSSortManager sortIpArrayOfModel:domainModel];
        }
    }
    
    if (domainModel == nil || domainModel.ipModelArray == nil || domainModel.ipModelArray.count == 0) {
        struct addrinfo hints;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = PF_INET;        // PF_INET if you want only IPv4 addresses
        hints.ai_protocol = IPPROTO_TCP;
        
        struct addrinfo *addrs, *addr;
        
        getaddrinfo([host UTF8String], NULL, &hints, &addrs);
        NSMutableArray* ipStringArray = [NSMutableArray array];
        for (addr = addrs; addr; addr = addr->ai_next) {
            char host[NI_MAXHOST];
            getnameinfo(addr->ai_addr, addr->ai_addrlen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
            [ipStringArray addObject:[NSString stringWithUTF8String:host]];
        }
        freeaddrinfo(addrs);

        NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:[WBDNSTools dateFormatter]];
        
        domainModel = [[WBDNSDomainModel alloc]init];
        domainModel.id = WBDNS_LOCAL_DNS_ID;
        domainModel.domain = host;
        domainModel.sp = sp;
        domainModel.ttl = @"60";
        domainModel.time = [formatter stringFromDate:[NSDate date]];
        
        for (NSString* ip in ipStringArray) {
            WBDNSIpModel* model = [[WBDNSIpModel alloc]init];
            model.id = WBDNS_LOCAL_DNS_ID;
            model.d_id = WBDNS_LOCAL_DNS_ID;
            model.ip = ip;
            model.port = 80;
            model.sp = sp;
            model.ttl = @"60";
            model.priority = @"";
            model.rtt = @"0";
            model.success_num = @"0";
            model.err_num = @"0";
            model.finally_fail_time = [[WBDNSTools sharedInstance]stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
            model.finally_success_time = [[WBDNSTools sharedInstance]stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
            model.finally_update_time = [formatter stringFromDate:[NSDate date]];
            
            [domainModel.ipModelArray addObject:model];
        }
        
        if ([[WBDNSConfigManager sharedInstance] isSupportedDomain:host] && [WBDNSConfigManager sharedInstance].config.enableRequestFromSinaHttpDnsServer) {
            [_manager updateMemoryCache:host model:domainModel];
        }
    }
    return domainModel;
}

@end
