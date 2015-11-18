//
//  WBDNSSpeedTester.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/19.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

@protocol WBDNSSpeedTester <NSObject>

-(int) testSpeedOf:(NSString *)ip;

@end

