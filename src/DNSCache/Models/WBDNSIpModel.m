//
//  IpModel.m
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSIpModel.h"

@implementation WBDNSIpModel

- (instancetype) init {
    if (self = [super init]) {
        _id = -2;
        _d_id = -2;
        _ip = @"";
        _port = 80;
        _sp = @"";
        _ttl = @"";
        _priority = @"";
        _rtt = @"";
        _success_num = 0;
        _err_num = 0;
        _finally_success_time = @"";
        _finally_fail_time = @"";
        _finally_update_time = @"";
        _grade = 0;
        
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    WBDNSIpModel* newModel = [[WBDNSIpModel allocWithZone:zone]init];
    newModel.id = self.id;
    newModel.d_id = self.d_id;
    newModel.ip = self.ip;
    newModel.port = self.port;
    newModel.sp = self.sp;
    newModel.ttl = self.ttl;
    newModel.priority = self.priority;
    newModel.rtt = self.rtt;
    newModel.success_num = self.success_num;
    newModel.err_num = self.err_num;
    newModel.finally_success_time = self.finally_success_time;
    newModel.finally_fail_time = self.finally_fail_time;
    newModel.finally_update_time = self.finally_update_time;
    newModel.grade = self.grade;
    return newModel;
}

- (NSString *)description {
    NSMutableString* string = [NSMutableString stringWithFormat:@"服务器id ＝ %ld\n域名ID索引 ＝ %i\n服务器ip ＝ %@\n服务器端口 = %i\n运营商 = %@\n过期时间 ＝ %@\n优先级 ＝ %@\n往返时延 ＝ %@\n历史成功次数 = %@\n历史失败次数 = %@\n最后一次访问成功时间 = %@\n最后一次访问失败时间 = %@\n最后一次更新时间 = %@\n服务器评分 = %ld\n", (long)_id, _d_id, _ip, _port, _sp, _ttl, _priority,_rtt, _success_num, _err_num, _finally_success_time, _finally_fail_time, _finally_update_time, (long)_grade];
    return string;
}


- (NSString*)toJson {
    NSDictionary* dic = @{@"id":@(_id),
                          @"d_id":@(_d_id),
                          @"ip":_ip,
                          @"port":@(_port),
                          @"sp":_sp,
                          @"ttl":_ttl,
                          @"priority":_priority,
                          @"success_num":_success_num,
                          @"err_num":_err_num,
                          @"finally_success_time":_finally_success_time,
                          @"finally_fail_time":_finally_fail_time
                          };
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return myString;
}

- (NSDictionary*)toDictionary {
    NSDictionary *dic = @{@"id":@(_id),
                          @"d_id":@(_d_id),
                          @"ip":_ip,
                          @"port":@(_port),
                          @"sp":_sp,
                          @"ttl":_ttl,
                          @"priority":_priority,
                          @"success_num":_success_num,
                          @"err_num":_err_num,
                          @"finally_success_time":_finally_success_time,
                          @"finally_fail_time":_finally_fail_time
                          };
    return dic;
}

@end
