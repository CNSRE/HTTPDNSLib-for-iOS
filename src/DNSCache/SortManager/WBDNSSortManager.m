//
//  WBDNSSortManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/24.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSSortManager.h"
#import "WBDNSTools.h"
#import "WBDNSConfigManager.h"
#import "WBDNSConfig.h"

@implementation WBDNSSortManager

+ (WBDNSDomainModel *)sortIpArrayOfModel:(WBDNSDomainModel *)model {
    if (model == nil || model.ipModelArray == nil || model.ipModelArray.count == 0) {
        return model;
    }
    
    NSMutableArray* sortedIpArray = [NSMutableArray array];
    NSMutableArray* speedTestedIpArray = [NSMutableArray array];
    NSMutableArray* speedNotTestedIpArray = [NSMutableArray array];
    for (WBDNSIpModel* ip in model.ipModelArray) {
        if (ip.finally_success_time && ip.finally_fail_time) {
            NSDate* successTime = [[WBDNSTools sharedInstance] dateFromString:ip.finally_success_time];
            NSDate* failedTime = [[WBDNSTools sharedInstance] dateFromString:ip.finally_fail_time];
            
            //时间异常，认定测速数据不合法，分到未测速组。
            if (successTime == nil && failedTime == nil) {
                NSLog(@"ERROR:%s:%d SuccessTime(%@) or FailedTime (%@) is invalid.", __func__,__LINE__,ip.finally_success_time,ip.finally_fail_time);
                [speedNotTestedIpArray addObject:ip];
                continue;
            }
            
            int speedTestExpireTime = 2* [WBDNSConfigManager sharedInstance].config.speedTestInterval;
            
            if ((![WBDNSTools isTestTimeExpired:successTime expiredTime:speedTestExpireTime])&&(![WBDNSTools isTestTimeExpired:failedTime expiredTime:speedTestExpireTime])) {
                //成功时间 晚于失败时间，说明测速成功。
                if ([successTime compare:failedTime] != NSOrderedDescending) {
                    [speedTestedIpArray addObject:ip];
                    continue;
                }
                //测速失败，本条记录从ip列表中去除，不返回给用户。
                else {
                    continue;
                }
            }
            else if(![WBDNSTools isTestTimeExpired:successTime expiredTime:speedTestExpireTime]) {
                //测速成功,加入到测速成功分组
                [speedTestedIpArray addObject:ip];
                continue;
            }
            else if(![WBDNSTools isTestTimeExpired:failedTime expiredTime:speedTestExpireTime]) {
                //测速失败，本条记录从ip列表中去除，不返回给用户。
                continue;
            }
            else {
                //测速数据过期，分到未测速分组
                [speedNotTestedIpArray addObject:ip];
                continue;
            }
        }
        //时间异常，认定测速数据不合法，分到未测速组。
        else {
            NSLog(@"ERROR:%s:%d SuccessTime(%@) or FailedTime (%@) is invalid.", __func__,__LINE__,ip.finally_success_time,ip.finally_fail_time);
            [speedNotTestedIpArray addObject:ip];
            continue;
        }
    
    }
    
    [speedTestedIpArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        WBDNSIpModel* ip1 = obj1;
        WBDNSIpModel* ip2 = obj2;
        int rtt1 = [ip1.rtt intValue];
        int rtt2 = [ip2.rtt intValue];
        if (rtt1 > rtt2) {
            return NSOrderedDescending;
        }
        else if(rtt1 < rtt2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }
    }];
    
    [sortedIpArray addObjectsFromArray:speedTestedIpArray];
    [sortedIpArray addObjectsFromArray:speedNotTestedIpArray];
    model.ipModelArray = sortedIpArray;
    return model;
}

@end
