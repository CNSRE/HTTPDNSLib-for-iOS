//
//  IP.m
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSIP.h"

@implementation WBDNSIP

- (instancetype) init {
    if (self = [super init]) {
    }
    return self;
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"服务器ip ＝ %@, 过期时间 ＝ %@, 优先级 ＝ %@", _ip, _ttl, _priority];
    return string;
}

- (NSDictionary *)toDictionary {
    NSDictionary* dic = @{@"ip":_ip,
                          @"ttl":_ttl,
                          @"priority":_priority,
                          };
    return dic;
}

@end
