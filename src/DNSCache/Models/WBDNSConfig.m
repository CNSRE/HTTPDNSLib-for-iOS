//
//  WBDNSConfig.m
//  DNSCache
//
//  Created by Robert Yang on 15/9/1.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSConfig.h"
#import "WBDNSTools.h"
@implementation WBDNSConfig

-(instancetype)init {
    if (self = [super init]) {
        self.enableHttpDnsCache = YES;
        self.logSamplingRate = 50;
        self.uploadLogInterval = 3600;
        self.speedTestInterval = 60;
        self.refreshDomainIpInterval = 60;
        self.enableRequestFromSinaHttpDnsServer = YES;
        self.enableSDKUpdateServerIpOrder = YES;
        self.speedTestFactorWeight = 50;
        self.serverSuggestionFactorWeight = 50;
        self.supportedDomainList = @[
                                     @"ww1.sinaimg.cn",
                                     @"ww2.sinaimg.cn",
                                     @"ww3.sinaimg.cn",
                                     @"ww4.sinaimg.cn",
                                     @"api.weibo.cn"
                                     ];
        self.httpDnsServerUrlList = @[
                                      @"http://dns.weibo.cn",
                                      @"http://202.108.7.232",
                                      @"http://221.179.190.246",
                                      @"http://58.63.236.228"
                                      ];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    
    WBDNSConfig *newConfig = [[[self class] allocWithZone:zone] init];
    newConfig.enableHttpDnsCache = self.enableHttpDnsCache;
    newConfig.logSamplingRate = self.logSamplingRate;
    newConfig.uploadLogInterval = self.uploadLogInterval;
    newConfig.speedTestInterval = self.speedTestInterval;
    newConfig.refreshDomainIpInterval = self.refreshDomainIpInterval;
    newConfig.enableRequestFromSinaHttpDnsServer = self.enableRequestFromSinaHttpDnsServer;
    newConfig.enableSDKUpdateServerIpOrder = self.enableSDKUpdateServerIpOrder;
    newConfig.speedTestFactorWeight = self.speedTestFactorWeight;
    newConfig.serverSuggestionFactorWeight = self.serverSuggestionFactorWeight;
    newConfig.supportedDomainList = [NSMutableArray arrayWithArray:self.supportedDomainList];
    newConfig.httpDnsServerUrlList = [NSMutableArray arrayWithArray:self.httpDnsServerUrlList];
    return newConfig;
}

-(BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[WBDNSConfig class]]) {
        return NO;
    }
    WBDNSConfig *other = (WBDNSConfig *)object;
    if (self.enableHttpDnsCache != other.enableHttpDnsCache ) {
        return NO;
    }
    
    if (self.enableSDKUpdateServerIpOrder != other.enableSDKUpdateServerIpOrder) {
        return NO;
    }
    
    if (self.enableRequestFromSinaHttpDnsServer != other.enableRequestFromSinaHttpDnsServer) {
        return NO;
    }
    
    if (self.logSamplingRate != other.logSamplingRate) {
        return NO;
    }
    
    if (self.uploadLogInterval != other.uploadLogInterval) {
        return NO;
    }
    
    if (self.speedTestInterval != other.speedTestInterval) {
        return NO;
    }
    
    if (self.refreshDomainIpInterval != other.refreshDomainIpInterval) {
        return NO;
    }
    
    if (self.speedTestFactorWeight != other.speedTestFactorWeight) {
        return NO;
    }
    
    if (self.serverSuggestionFactorWeight != other.serverSuggestionFactorWeight) {
        return NO;
    }
    
    if (![WBDNSTools isStringArray:self.supportedDomainList equalToStringArray2:other.supportedDomainList]) {
        return NO;
    }
    
    if (![WBDNSTools isStringArray:self.httpDnsServerUrlList equalToStringArray2:other.httpDnsServerUrlList]){
        return NO;
    }
    
    return YES;
}

@end
