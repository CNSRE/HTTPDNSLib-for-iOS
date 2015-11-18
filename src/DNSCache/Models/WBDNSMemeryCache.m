//
//  WBDNSMemeryCache.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/10.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSMemeryCache.h"
#import "WBDNSQueryManager.h"
#import "WBDNSConfigManager.h"
#import "WBDNSTools.h"

@implementation WBDNSMemeryCache
{
    NSMutableDictionary* _dic;
}

+ (instancetype)sharedInstance {
    static WBDNSMemeryCache* sharedInstance;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WBDNSMemeryCache alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _dic = [[NSMutableDictionary alloc]init];
    }
    return self;
}


- (WBDNSDomainModel *)getModelByKeyUrl:(NSString *)keyUrl {
    @synchronized(self) {
        return _dic[keyUrl];
    }
}

- (void)removeAllModels {
    @synchronized(self) {
        [_dic removeAllObjects];
    }
}

- (NSArray *)getAllModels {
    @synchronized(self) {
        return [_dic allValues];
    }
}

- (void)addModel:(WBDNSDomainModel *)model keyUrl:(NSString *)keyUrl {
    @synchronized(self) {
        WBDNSDomainModel* existModel = _dic[keyUrl];
        if (existModel) {
            [_dic removeObjectForKey:keyUrl];
            [_dic setObject:model forKey:keyUrl];
        }
        else {
            [_dic setObject:model forKey:keyUrl];
        }
    }
}


//本函数只用于更新从本地dns获取的ip， 从httpserver 获取的ip 不应该用此函数更新。
- (void)updateModel:(WBDNSDomainModel *)model keyUrl:(NSString *)keyUrl
{
    @synchronized(self) {
        WBDNSDomainModel* existModel = _dic[keyUrl];
        if (existModel) {
            existModel.id = model.id;
            existModel.domain = model.domain;
            existModel.sp = model.sp;
            existModel.ttl = model.ttl;
            existModel.time = model.time;
            
            NSMutableArray *newIpArray= [NSMutableArray array];
            
            //更新在新老Model里的ip，不更新测速数据；。删除存在着老model里的，但是不在新Model里的ip。
            for (WBDNSIpModel *ipModel in existModel.ipModelArray) {
                WBDNSIpModel *newIpModel = [self findIp:ipModel.ip inIPArray:model.ipModelArray];
                if (newIpModel) {
                    ipModel.id = newIpModel.id;
                    ipModel.d_id = newIpModel.d_id;
                    ipModel.ttl = newIpModel.ttl;
                    ipModel.sp = newIpModel.sp;
                    ipModel.finally_update_time = newIpModel.finally_update_time;
                    [newIpArray addObject:ipModel];
                }
            }
            
            //把新Model里存在 但不再老model里的ip 加进来。
            for (WBDNSIpModel *ipModel in model.ipModelArray) {
                WBDNSIpModel *newIpModel = [self findIp:ipModel.ip inIPArray:newIpArray];
                if (newIpModel == nil) {
                    [newIpArray addObject:ipModel];
                }
            }
            
            existModel.ipModelArray = newIpArray;
        }
        else {
            [_dic setObject:model forKey:keyUrl];
        }
    }
}

- (WBDNSIpModel *)findIp:(NSString *)ip inIPArray:(NSArray *)ipArray
{
    for (WBDNSIpModel* ipModel in ipArray) {
        if ([ipModel.ip isEqualToString:ip]) {
            return ipModel;
        }
    }
    return nil;
}

- (NSArray *)getExpireDnsCache
{
    @synchronized(self) {
        NSMutableArray *domainList = [NSMutableArray array];
        for (WBDNSDomainModel *tempModel in [_dic allValues] ) {
            if ([WBDNSTools isDomainModelExpired:tempModel expireDuration:0]) {
                [domainList addObject:tempModel];
            }
        }
        return domainList;
    }
}

@end
