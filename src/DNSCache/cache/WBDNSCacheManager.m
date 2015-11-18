//
//  DNSCacheManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/3.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSCacheManager.h"
#import "WBDNSMemeryCache.h"
#import "WBDNSConfig.h"
#import "WBDNSConfigManager.h"
#import "WBDNSQueryManager.h"
#import "WBDNSNetworkManager.h"
#import "WBDNSTools.h"

@interface WBDNSCacheManager()
{
    WBDNSDBManager *_dbManager;
    WBDNSMemeryCache *_cacheDic;
}

@end

@implementation WBDNSCacheManager

+ (instancetype)sharedInstance {
    static  WBDNSCacheManager *sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WBDNSCacheManager alloc]init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        _dbManager = [[WBDNSDBManager alloc]init];
        _cacheDic = [WBDNSMemeryCache sharedInstance];
    }
    return  self;
}

- (NSArray *)getExpireDnsCache {
    @synchronized(self) {
        return [_cacheDic getExpireDnsCache];
    }
}

- (NSArray *)getAllModels {
    @synchronized(self) {
        return [_cacheDic getAllModels];
    }
}

- (NSArray *)getAllModelsFromDB {
    @synchronized(self) {
        return [_dbManager queryAllDomainInfoWithIpArray:YES containsExpiredIp:YES hasDbOpen:NO];
    }
}

- (void)addMemoryCache:(NSString *)url model:(WBDNSDomainModel *)model {
    @synchronized(self) {
        if (model == nil) {
            NSLog(@"ERROR:%s:%d model is nil.", __func__, __LINE__);
            return;
        }
        if (model.ipModelArray == nil || model.ipModelArray.count == 0) {
            NSLog(@"ERROR:%s:%d model.ipModelArray is nil.", __func__, __LINE__);
            return;
        }
        
        for (WBDNSIpModel *ipModel in model.ipModelArray) {
            if (ipModel == nil) {
                NSLog(@"WARNING:%s an ipModel in model.ipModelArray is nil.", __func__);
                return;
            }
        }
        
        [_cacheDic addModel:model keyUrl:url];
        return;
    }
}

//本函数只用于更新从本地dns获取的ip， 从httpserver 获取的ip 不应该用此函数更新。
- (void)updateMemoryCache:(NSString *)domain model:(WBDNSDomainModel *)model
{
    @synchronized(self) {
        if (model == nil) {
            NSLog(@"ERROR:%s:%d model is nil.", __func__, __LINE__);
            return;
        }
        if (model.ipModelArray == nil || model.ipModelArray.count == 0) {
            NSLog(@"ERROR:%s:%d model.ipModelArray is nil.", __func__, __LINE__);
            return;
        }
        
        [_cacheDic updateModel:model keyUrl:domain];
        return;
    }
}

- (WBDNSDomainModel *)getDnsCache:(NSString *)sp url:(NSString *)url {
    //这个锁是防止 多个线程重复的 从数据库取数据插入缓存。
    @synchronized(self) {
        WBDNSDomainModel *model = [_cacheDic getModelByKeyUrl:url];
        NSString* source = @"cache";
        if (model == nil) {
            model = [_dbManager queryDomainInfoWithIPArray:url sp:sp containsExpiredIp:NO hasDbOpen:NO];
            source = @"database";
        }
        
        if (model != nil) {
            if ([WBDNSTools isDomainModelExpired:model expireDuration:[WBDNSConfigManager sharedInstance].config.refreshDomainIpInterval]) {
                NSLog(@"INFO:%s:%d model(domain:%@) from %@ is expired.", __func__, __LINE__, model.domain, source);
                model = nil;
            } else if (model.ipModelArray == nil || model.ipModelArray.count == 0) {
                NSLog(@"INFO:%s:%d model(domain:%@) from %@ all ip are expired.", __func__, __LINE__, model.domain, source);
                model = nil;
            } else if(![model.sp isEqualToString:sp]) {
                //只是一个容错判断，一般不会走到这里。
                NSLog(@"INFO:%s:%d model(domain:%@) from %@, sp is not current sp.", __func__, __LINE__, model.domain, source);
                model = nil;
            } else {
                //把数据库里的有效model 存到缓存里。
                if ([source isEqualToString:@"database"]) {
                    [self addMemoryCache:url model:model];
                }
            }
        }
        return model;
    }
}

- (WBDNSDomainModel *)insertDnsCache:(WBDNSHttpDnsPack *) dnsPack {
    @synchronized(self) {
        WBDNSDomainModel* model = [[WBDNSDomainModel alloc]init];
        model.domain = dnsPack.domain;
        model.sp = dnsPack.localhostSp;
        
        model.time = [[WBDNSTools sharedInstance] stringFromDate:[NSDate date]];
        
        int t = 120;
        for (WBDNSIP* tempIp in dnsPack.dns) {
            WBDNSIpModel* ipModel = [[WBDNSIpModel alloc]init];
            ipModel.d_id = -1;//需要在后面刷新：updateDomainModelWithIpArray
            ipModel.ip = tempIp.ip;
            ipModel.ttl = tempIp.ttl;
            ipModel.priority = tempIp.priority;
            ipModel.rtt = @"0";
            ipModel.port = 80;
            ipModel.sp = model.sp;
            ipModel.success_num = @"0";
            ipModel.err_num = @"0";
            ipModel.finally_success_time = [[WBDNSTools sharedInstance] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
            ipModel.finally_fail_time = [[WBDNSTools sharedInstance] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
            ipModel.finally_update_time = [[WBDNSTools sharedInstance] stringFromDate:[NSDate date]];
            [model.ipModelArray addObject:ipModel];
            
            if ([ipModel.ttl intValue] < t) {
                t = [ipModel.ttl intValue];
            }
        }
        
        model.ttl = [NSString stringWithFormat:@"%i", t];
        
        if (model.ipModelArray != nil && model.ipModelArray.count > 0) {
            model = [_dbManager updateDomainModelWithIpArray:model];
            [self addMemoryCache:model.domain model:model];
        }
        return model;
    }
}

- (WBDNSIpModel *)findIpModel:(WBDNSIpModel *)ipModel inArray:(NSArray *)array {
    for (WBDNSIpModel* ip in array) {
        if ([ip.sp isEqualToString:ipModel.sp] && [ip.ip isEqualToString:ipModel.ip]) {
            return ip;
        }
    }
    return nil;
}

- (void)updateCachedIpModelSpeedInfo:(WBDNSDomainModel *)model {
    @synchronized(self) {
        if(![model.sp isEqualToString:[WBDNSNetworkManager sharedInstance].currentSpTypeString]) {
            NSLog(@"INFO:%s:%d network switched，don't set speed test data to cache.", __func__, __LINE__);
            return;
        }
        
        WBDNSDomainModel* existModel = [_cacheDic getModelByKeyUrl:model.domain];
        if (existModel == nil) {
            return;
        }
        
        for (WBDNSIpModel* ipModel in model.ipModelArray) {
            WBDNSIpModel* existCachedIpModel = [self findIpModel:ipModel inArray:existModel.ipModelArray];
            if (existCachedIpModel) {
                NSDate* succDate = [[WBDNSTools sharedInstance]dateFromString:ipModel.finally_success_time];
                NSDate* failDate = [[WBDNSTools sharedInstance]dateFromString:ipModel.finally_fail_time];
                NSComparisonResult result = [succDate compare:failDate];
                if (result == NSOrderedDescending) {
                    existCachedIpModel.success_num =[NSString stringWithFormat:@"%d", [existCachedIpModel.success_num intValue] +1];
                    existCachedIpModel.finally_success_time = ipModel.finally_success_time;
                } else {
                    existCachedIpModel.err_num =[NSString stringWithFormat:@"%d", [existCachedIpModel.err_num intValue] +1];
                    existCachedIpModel.finally_fail_time = ipModel.finally_fail_time;
                }
                
                existCachedIpModel.rtt = ipModel.rtt;
            }
        }
    }
}

- (void)updateDBSavedIpModelSpeedInfo:(WBDNSDomainModel *)model {
    for (WBDNSIpModel* ipModel in model.ipModelArray) {
        
        WBDNSIpModel* existModel = [_dbManager queryIpModel:ipModel.ip sp:ipModel.sp domainId:model.id hasDbOpen:NO];
        if (existModel) {
            
            NSDate* succDate = [[WBDNSTools sharedInstance]dateFromString:ipModel.finally_success_time];
            NSDate* failDate = [[WBDNSTools sharedInstance]dateFromString:ipModel.finally_fail_time];
            NSComparisonResult result = [succDate compare:failDate];
            if (result == NSOrderedDescending) {
                existModel.success_num =[NSString stringWithFormat:@"%d", [existModel.success_num intValue] +1];
                existModel.finally_success_time = ipModel.finally_success_time;
            } else {
                existModel.err_num =[NSString stringWithFormat:@"%d", [existModel.err_num intValue] +1];
                existModel.finally_fail_time = ipModel.finally_fail_time;
            }
            
            existModel.rtt = ipModel.rtt;
            
            [_dbManager updateIpModel:existModel hasDbOpen:NO];
        }
    }
}

- (BOOL)updateIpModelSpeedInfoInCacheAndDB:(WBDNSDomainModel *)model {
    @synchronized(self) {
        if (model == nil || model.ipModelArray.count == 0) {
            NSLog(@"INFO:%s:%d  input params is nil.", __func__, __LINE__);
            return NO;
        }

        [self updateCachedIpModelSpeedInfo:model];
        
        [self updateDBSavedIpModelSpeedInfo:model];
        
        return YES;
    }
}

- (void)clear {
    @synchronized(self) {
        [_dbManager clear];
        [self clearMemoryCache];
    }
}

- (void)clearDB {
    @synchronized(self) {
        [_dbManager clear];
    }
}

- (void)clearMemoryCache {
    @synchronized(self) {
        [_cacheDic removeAllModels];
    }
}

@end
