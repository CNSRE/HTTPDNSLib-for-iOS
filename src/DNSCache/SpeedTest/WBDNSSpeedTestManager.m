//
//  SpeedTestManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/19.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSSpeedTestManager.h"
#import "WBDNSSpeedTester.h"
#import "WBDNSTCPSpeedTester.h"
#import "WBDNSModel.h"
#import "WBDNSCacheManager.h"
@implementation WBDNSSpeedTestManager
{
    id<WBDNSSpeedTester> _speedTester;
}

+ (instancetype)sharedInstance {
    static WBDNSSpeedTestManager* sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WBDNSSpeedTestManager alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _speedTester = [[WBDNSTCPSpeedTester alloc]init];
    }
    return self;
}

-(void)testSpeedOfIpArrayOfDomain:(WBDNSDomainModel *)domain
{
    if (domain.ipModelArray == nil) {
        NSLog(@"ERROR:%s:%d domian or domain.ipModelArray is nil.",__func__,__LINE__);
        return;
    }
    
    if (domain.ipModelArray.count == 0) {
        return;
    }
    
    for (WBDNSIpModel *ip in domain.ipModelArray) {

        int rtt = [_speedTester testSpeedOf:ip.ip];
        if (rtt < WBDNS_SOCKET_CONNECT_TIMEOUT_RTT) {
            ip.success_num = [NSString stringWithFormat:@"%d", [ip.success_num intValue] +1];
            ip.finally_success_time = [[WBDNSTools sharedInstance]stringFromDate:[NSDate date]];
        }
        else
        {
            ip.err_num = [NSString stringWithFormat:@"%d", [ip.err_num intValue] +1];
            ip.finally_fail_time = [[WBDNSTools sharedInstance]stringFromDate:[NSDate date]];
        }
        ip.rtt = [NSString stringWithFormat:@"%d",rtt];
    }
    
    [[WBDNSCacheManager sharedInstance]updateIpModelSpeedInfoInCacheAndDB:domain];
}

@end
