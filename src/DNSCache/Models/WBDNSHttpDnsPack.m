//
//  HttpDnsPack.m
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSHttpDnsPack.h"
#import "WBDNSModel.h"
#import "WBDNSCache.h"
@implementation WBDNSHttpDnsPack

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

+ (WBDNSHttpDnsPack *)generateInstanceFromDic:(NSDictionary *)dic {
    if (dic == nil) {
        return nil;
    }
    WBDNSHttpDnsPack* dnsPack = [[WBDNSHttpDnsPack alloc]init];
    dnsPack.domain = dic[@"domain"];
    dnsPack.device_ip = dic[@"device_ip"];
    dnsPack.device_sp = dic[@"device_sp"];
    NSArray* dns = dic[@"dns"];
    if (dns && [dns isKindOfClass:[NSArray class]]) {
        dnsPack.dns = [NSMutableArray array];
    }
    for (NSDictionary* tempIP in dns) {
        WBDNSIP* ip = [[WBDNSIP alloc]init];
        ip.ip = tempIP[@"ip"];
        ip.ttl = tempIP[@"ttl"];
        ip.priority = tempIP[@"priority"];
        [dnsPack.dns addObject:ip];
    }
    return dnsPack;
}

- (NSString *)description {
    NSMutableString* string = [NSMutableString stringWithFormat:@"域名 ＝ %@, 最终请求IP ＝ %@, 服务器识别运营商 ＝ %@, 本地识别运营商或SSID ＝ %@", _domain, _device_ip, _device_sp, _localhostSp];
    return string;
}

- (NSDictionary *)toDictionary {
    NSMutableArray* dnsIpJasonArray = [NSMutableArray array];
    for(int i = 0; i< self.dns.count; i++)
    {
        [dnsIpJasonArray addObject:[self.dns[i] toDictionary]];
    }
    
    NSDictionary* dic = @{@"domain":_domain,
                          @"device_ip":_device_ip,
                          @"device_sp":_device_sp,
                          @"dns":dnsIpJasonArray,
                          };
    return dic;
}

@end
