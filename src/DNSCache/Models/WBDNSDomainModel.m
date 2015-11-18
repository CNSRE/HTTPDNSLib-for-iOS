//
//  DomainModel.m
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSDomainModel.h"
#import "WBDNSIpModel.h"
@implementation WBDNSDomainModel

- (instancetype)init {
    if (self = [super init]) {
        _id = -2;
        _domain = @"";
        _sp = @"";
        _ttl = @"";
        _time = @"";
        self.ipModelArray = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    self.ipModelArray = nil;
}

- (NSArray *)serverIpArray {
    NSMutableArray* serverIpArray = [NSMutableArray array];
    for (WBDNSIpModel* ipModel in self.ipModelArray) {
        [serverIpArray addObject:ipModel.ip];
    }
    return serverIpArray;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    WBDNSDomainModel* newModel = [[WBDNSDomainModel allocWithZone:zone]init];
    newModel.id = self.id;
    newModel.domain = self.domain;
    newModel.sp = self.sp;
    newModel.ttl = self.ttl;
    newModel.time = self.time;
    
    for (WBDNSIpModel* ipModel in self.ipModelArray) {
        [newModel.ipModelArray addObject:[ipModel copy]];
    }
    return newModel;
}

- (NSString *) description {
    NSMutableString* string = [NSMutableString stringWithFormat:@"域名ID ＝ %i, 域名 ＝ %@, 运营商ID ＝ %@, 域名过期时间 = %@, 域名最后查询时间 = %@,\n", _id, _domain, _sp, _ttl, _time];
    for (WBDNSIpModel* ipModel in self.ipModelArray) {
        [string appendString:@"--------Ip 列表---------\n"];
        [string appendString:[ipModel description]];
    }
    return string;
}

-(NSString*) toJson {
    NSMutableArray* ipModelJasonArray = [NSMutableArray array];
    for(int i = 0; i< self.ipModelArray.count; i++) {
        [ipModelJasonArray addObject:[self.ipModelArray[i] toDictionary]];
    }
        
    NSDictionary* dic = @{@"id":@(_id),
                          @"domain":_domain,
                          @"sp":_sp,
                          @"ttl":_ttl,
                          @"sp":_sp,
                          @"time":_time,
                          @"ipModelArr":ipModelJasonArray,
                          };
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return myString;
}

- (NSDictionary *)toDictionary {
    NSMutableArray* ipModelJasonArray = [NSMutableArray array];
    for(int i = 0; i< self.ipModelArray.count; i++) {
        [ipModelJasonArray addObject:[self.ipModelArray[i] toDictionary]];
    }
    
    NSDictionary* dic = @{@"id":@(_id),
                          @"domain":_domain,
                          @"sp":_sp,
                          @"ttl":_ttl,
                          @"sp":_sp,
                          @"time":_time,
                          @"ipModelArr":ipModelJasonArray,
                          };
    return dic;
}

@end
