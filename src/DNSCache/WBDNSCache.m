//
//  DNSCache.m
//  DNSCache
//
//  Created by Robert Yang on 15/7/29.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSCache.h"
#import "WBDNSModel.h"
#import "WBDNSNetworkManager.h"
#import "WBDNSQueryManager.h"
#import "WBDNSHttpDnsManager.h"
#import "WBDNSConfig.h"
#import "WBDNSConfigManager.h"
#import "WBDNSSpeedTestManager.h"
#import "WBDNSLogManager.h"
#import "WBDNSLogManager.h"
#import "WBDNSWeakTimer.h"

static NSString* WBDNSLastUploadLogTime = @"WBDNSLastUploadLogTime";

@implementation WBDNSDomainInfo

- (instancetype)initWithId:(NSString *)id url:(NSString *)url host:(NSString *)host {
    if (self = [super init]) {
        self.id = id;
        self.url = url;
        self.host = host;
    }
    return self;
}

+ (WBDNSDomainInfo *)generateDomainInfoByServerIp:(NSString *)serverIp url:(NSString *) url host:(NSString *) host {
    url = [WBDNSTools getIpUrlFromDomainUrl:url host:host ip:serverIp];
    return [[WBDNSDomainInfo alloc]initWithId:@"" url:url host:host];
}

+ (NSArray *)generateDomainInfoArrayByServerIpArray:(NSArray *)serverIpArray url:(NSString *) url host:(NSString *)host {
    NSMutableArray* resultArray = [NSMutableArray array];
    for (NSString* serverIp in serverIpArray) {
        WBDNSDomainInfo* domainInfo = [self generateDomainInfoByServerIp:serverIp url:url host:host];
        [resultArray addObject:domainInfo];
    }
    return resultArray;
}


- (NSString *)description {
    NSString* description = [NSString stringWithFormat:@"DomainInfo: id = %@, url = %@, host = %@", _id, _url, _host];
    return description;
}

@end


@interface WBDNSCache()
{
    WBDNSCacheManager *_dnsCacheManager;
    WBDNSQueryManager *_queryManager;
    WBDNSNetworkManager *_netWorkManager;
    WBDNSHttpDnsManager *_httpDnsManager;
    WBDNSConfigManager *_dnsCacheConfig;
    NSMutableDictionary *_runningTask;
    NSMutableDictionary *_runningSpeedTestTask;
    NSOperationQueue *_taskQueue;
    NSTimer *_timer;
    NSTimer *_testSpeedTimer;
}
@end

@implementation WBDNSCache

+ (instancetype)sharedInstance {
    static  WBDNSCache* sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WBDNSCache alloc]init];
    });
    return sharedInstance;
}

- (void)initialize {
    //为了让客户端调用sharedInstance时 感觉有初始化这个动作。
}

- (instancetype)init {
    if (self = [super init]) {
        //其它模块都需要依赖config模块，所以config模块先初始化好一些。
        _dnsCacheConfig = [WBDNSConfigManager sharedInstance];
        _dnsCacheManager = [WBDNSCacheManager sharedInstance];
        _queryManager = [[WBDNSQueryManager alloc]initWithDnsCacheManager:_dnsCacheManager];
        _netWorkManager = [WBDNSNetworkManager sharedInstance];
        [_netWorkManager setDnsCacheManager:_dnsCacheManager];
        _httpDnsManager = [[WBDNSHttpDnsManager alloc]init];
        _runningTask = [[NSMutableDictionary alloc]init];
        _taskQueue = [[NSOperationQueue alloc]init];
        _runningSpeedTestTask = [[NSMutableDictionary alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configDataChanged) name:WBDNSConfigDataChangeNotification object:nil];

        _timer = [WBDNSWeakTimer scheduledTimerWithTimeInterval:_dnsCacheConfig.config.refreshDomainIpInterval target:self selector:@selector(processPeriodicTask) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc {
    _dnsCacheManager = nil;
    _queryManager = nil;
    _netWorkManager = nil;
    _httpDnsManager = nil;
    
    [_timer invalidate];
    _timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (void)setAppkey:(NSString *)appKey version:(NSString *)version {
    [WBDNSConfigManager setAppkey:appKey version:version];
}

+ (void)setConfigServerUrl:(NSString *) url {
    [WBDNSConfigManager setConfigServerUrl:url];
}

- (void)configDataChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_timer isValid]) {
            [_timer invalidate];
            _timer = nil;
        }
        
        _timer = [WBDNSWeakTimer scheduledTimerWithTimeInterval:_dnsCacheConfig.config.refreshDomainIpInterval target:self selector:@selector(processPeriodicTask) userInfo:nil repeats:YES];
    });
}

- (void)preloadDomains:(NSArray *)domainsArray {
    for (NSString* domain in domainsArray) {
        NSString* host;
        if ([domain hasPrefix:@"http://"]) {
            NSURL* url = [NSURL URLWithString:domain];
            host = url.host;
        } else {
            host = domain;
        }
        [self checkUpdate:host needSpeedTest:YES];
    }
}

- (NSArray *)getDomainServerIpFromURL:(NSString *)urlString {
    if (!_dnsCacheConfig.config.enableHttpDnsCache) {
        return nil;
    }
    
    NSURL* url = [NSURL URLWithString:urlString];
    
    if (url.host == nil) {
        NSLog(@"ERROR:%s:%d get host from (%@) failed ",__FUNCTION__,__LINE__, urlString);
        return nil;
    }
    
    if ([WBDNSTools isIpV4Address:url.host] || ![[WBDNSConfigManager sharedInstance] isSupportedDomain:url.host]) {
        NSArray* domainInfoArray = @[[[WBDNSDomainInfo alloc]initWithId:@"1" url:urlString host:@""]];
        return domainInfoArray;
    }
    
    WBDNSDomainModel* domainModel = [_queryManager queryDomainIp:_netWorkManager.currentSpTypeString host:url.host];
    
    if (domainModel == nil) {
        if ([[WBDNSConfigManager sharedInstance] isSupportedDomain:url.host] && [WBDNSConfigManager sharedInstance].config.enableRequestFromSinaHttpDnsServer) {
            [self checkUpdate:url.host needSpeedTest:YES];
        }
        return nil;
    }
    
    if (domainModel.id == WBDNS_LOCAL_DNS_ID) {
        if ([[WBDNSConfigManager sharedInstance] isSupportedDomain:url.host] && [WBDNSConfigManager sharedInstance].config.enableRequestFromSinaHttpDnsServer) {
            [self checkUpdate:url.host  needSpeedTest:YES];
        }
    }
    
    [WBDNSLogManager log:WBDNS_LOG_TYPE_INFO action:WBDNS_LOG_ACTION_INFO_DOMAIN body:[domainModel toDictionary] samplingRate:[WBDNSConfigManager sharedInstance].config.logSamplingRate];

    NSArray *domainInfoArray = [WBDNSDomainInfo generateDomainInfoArrayByServerIpArray:[domainModel serverIpArray]  url:urlString host:url.host];

    return domainInfoArray;
}


#pragma mark- 定时任务 －刷新域名对应IP

- (void)processPeriodicTask {
    if ([WBDNSConfigManager sharedInstance].config.enableRequestFromSinaHttpDnsServer == NO) {
        return;
    }
    
    if ([WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNCONNECTED
        || [WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNKNOWN) {
        return;
    }
    
    NSArray* expiredDomainInfos = [_dnsCacheManager getExpireDnsCache];
    for (WBDNSDomainModel* model in expiredDomainInfos) {
        [self checkUpdate:model.domain needSpeedTest:NO];
    }
    
    [self testSpeed];
    
    [self uploadLogs];
}

- (void)checkUpdate:(NSString *)domain needSpeedTest:(BOOL)needSpeedTest {
    if ([WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNCONNECTED
        || [WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNKNOWN) {
        return;
    }
    
    if (domain == nil) {
        return;
    }
    
    NSBlockOperation* operation = _runningTask[domain];
    if (operation == nil) {
        NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
            [_httpDnsManager requestHttpDnsByDomain:domain completionHandler:^(WBDNSHttpDnsPack * dnsPack) {
                WBDNSDomainModel* newModel;
                if(dnsPack != nil)
                {
                    newModel = [_dnsCacheManager insertDnsCache:dnsPack];
                    if (needSpeedTest) {
                        [self testSpeedOfModel:[newModel copy]];
                    }
                }
                
                [_runningTask performSelectorOnMainThread:@selector(removeObjectForKey:) withObject:domain waitUntilDone:NO];
            }];
        }];
        [_runningTask setObject:operation forKey:domain];
        [_taskQueue addOperation:operation];
    }
}

#pragma mark- 定时任务 －对域名IP进行测速

- (void)testSpeed {
    NSArray* modelArray = [_dnsCacheManager getAllModels];
    for (WBDNSDomainModel* model in modelArray) {
        
        if (![self needSpeedTestForDomain:model]) {
            continue;
        }
        
        [self testSpeedOfModel:[model copy]];
    }
}

- (void)testSpeedOfModel:(WBDNSDomainModel *)model {
    if ([WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNCONNECTED
        || [WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNKNOWN) {
        return;
    }
    
    if (model == nil || model.ipModelArray == nil || model.ipModelArray.count == 0) {
        NSLog(@"WARNING:%s:%d test ip of domain is %@ or ipArray is nil.",__func__,__LINE__,model.domain);
        return;
    }
    
    if(_runningSpeedTestTask[model.domain] == nil) {
        NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
            [[WBDNSSpeedTestManager sharedInstance]testSpeedOfIpArrayOfDomain:model];
            [_runningSpeedTestTask performSelectorOnMainThread:@selector(removeObjectForKey:) withObject:model.domain waitUntilDone:NO];
        }];
        [_runningSpeedTestTask setObject:operation forKey:model.domain];
        [_taskQueue addOperation:operation];
    }
}

- (BOOL)needSpeedTestForDomain:(WBDNSDomainModel *)model {
    if(model == nil || model.ipModelArray == nil  || model.ipModelArray.count == 0) {
        NSLog(@"ERROR:%s:%d model(%@) is invalid.",__func__,__LINE__, model.domain);
        return NO;
    }
    for (WBDNSIpModel* ip in model.ipModelArray) {
        NSDate* successTime = [[WBDNSTools sharedInstance] dateFromString:ip.finally_success_time];
        NSDate* failedTime = [[WBDNSTools sharedInstance] dateFromString:ip.finally_fail_time];
        NSDate* lastSpeedTestTime;
        //时间异常，需要测速。
        if (successTime == nil || failedTime == nil) {
            NSLog(@"ERROR:%s:%d SuccessTime(%@) or FailedTime (%@) is invalid.", __func__,__LINE__,ip.finally_success_time,ip.finally_fail_time);
            return YES;
        }
        
        if ([successTime compare:failedTime] == NSOrderedAscending) {
            lastSpeedTestTime = failedTime;
        } else {
            lastSpeedTestTime = successTime;
        }
        
        if ([WBDNSTools isTestTimeExpired:lastSpeedTestTime expiredTime:[WBDNSConfigManager sharedInstance].config.speedTestInterval]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark- 定时任务 －上传日志
- (void)uploadLogs {
    if ([WBDNSNetworkManager sharedInstance].networkType != WBDNS_NETWORK_TYPE_WIFI) {
        return;
    }
    //周期判断
    NSDate* lastUploadTime = [[NSUserDefaults standardUserDefaults] objectForKey:WBDNSLastUploadLogTime];
    if (lastUploadTime != nil && [lastUploadTime compare:[NSDate date]] != NSOrderedDescending) {
        NSDate *shouldUploadTime = [lastUploadTime initWithTimeInterval:[WBDNSConfigManager sharedInstance].config.uploadLogInterval sinceDate:lastUploadTime];
        if ([[NSDate date]compare:shouldUploadTime] == NSOrderedAscending) {
            return;
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:WBDNSLastUploadLogTime];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    [[WBDNSLogManager sharedInstance]uploadLogFiles];
}

@end
