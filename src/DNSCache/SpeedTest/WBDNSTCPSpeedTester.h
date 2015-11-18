//
//  TCPSpeedTester.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/19.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSSpeedTester.h"

#define WBDNS_SOCKET_CONNECT_TIMEOUT 10 //单位秒
#define WBDNS_SOCKET_CONNECT_TIMEOUT_RTT 600000//10分钟 单位毫秒

@interface WBDNSTCPSpeedTester : NSObject <WBDNSSpeedTester>

@end
