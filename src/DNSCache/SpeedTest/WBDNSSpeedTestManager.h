//
//  SpeedTestManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/19.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSModel.h"
@interface WBDNSSpeedTestManager : NSObject
- (void)testSpeedOfIpArrayOfDomain:(WBDNSDomainModel *)domain;
+ (instancetype)sharedInstance;
@end
