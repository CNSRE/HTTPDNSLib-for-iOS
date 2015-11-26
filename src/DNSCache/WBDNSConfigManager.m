//
//  WBDNSCacheConfig.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/13.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSConfigManager.h"
#import "WBDNSTools.h"
#import "WBDNSNetworkManager.h"
#import "WBDNSConfig.h"
#import <UIKit/UIKit.h>
#define WBDNS_CONFIG_FILE_NAME @"WBDNSCacheConfigFile.json"

@implementation WBDNSConfigManager
{
    BOOL _getConfigDataSuccessfully;
    BOOL _isRequestingConfigDataFromServer;
    NSArray *_httpDnsServerUrlList;
    NSMutableDictionary *_httpDnsServerUrlFailedTimesDic;
    dispatch_queue_t _serverUrlOperationQueue;
}

static NSString* WBDNSCacheConfigServerUrl = @"";
static NSString* WBDNSCacheLogServerUrl = @"";
static NSString* WBDNS_APPKEY = @"";
static NSString* WBDNS_APP_VERSION = @"";

+ (WBDNSConfigManager *)sharedInstance {
    static WBDNSConfigManager* sharedInstance;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WBDNSConfigManager alloc]init];
    });
    return sharedInstance;
}

+ (WBDNSConfig *)sharedConfig {
    return [WBDNSConfigManager sharedInstance].config;
}

- (instancetype)init {
    if (self = [super init]) {
        _config = [[WBDNSConfig alloc]init];
        
        _serverUrlOperationQueue = dispatch_queue_create("com.sina.weibo.dnscache.serverUrlQueue", DISPATCH_QUEUE_SERIAL);
        
        if ([self isExistFile]) {
            [self readDataFromConfigFile];
        }
        else {
            [self saveConfigToJasonFile];
        }
        dispatch_sync(_serverUrlOperationQueue, ^{
            _httpDnsServerUrlList = [NSArray arrayWithArray:_config.httpDnsServerUrlList];
            _httpDnsServerUrlFailedTimesDic = [NSMutableDictionary dictionary];
            for (NSString* url in _config.httpDnsServerUrlList) {
                [_httpDnsServerUrlFailedTimesDic setObject:@(0) forKey:url];
            }
        });
        _getConfigDataSuccessfully = NO;
        _isRequestingConfigDataFromServer = NO;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(networkStatusChanged:) name:(WBDNSNetworkStatusChangeNotification) object:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestingConfigDataFromServer];
        });
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (WBDNSConfig *)getConfig {
    return _config;
}

- (void)networkStatusChanged:(NSNotification*)notif {
    WBDNSNetworkStatus status = [notif.object intValue];
    
    if (status == WBDNS_NETWORK_TYPE_MOBILE || status == WBDNS_NETWORK_TYPE_WIFI) {
        if (!_getConfigDataSuccessfully && !_isRequestingConfigDataFromServer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestingConfigDataFromServer];
            });
        }
    }
}

- (BOOL)isExistFile {
    NSFileManager* fm = [[NSFileManager alloc] init];
    return [fm fileExistsAtPath:[self getFilePath]];
}

- (NSString *)getFilePath {
    //get db path
    NSArray *documentsPaths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask  , YES);
    NSString *databaseFilePath=[[documentsPaths objectAtIndex:0] stringByAppendingPathComponent:WBDNS_CONFIG_FILE_NAME];
    return databaseFilePath ;
}

- (void)saveConfigToJasonFile {
    @synchronized(self) {
        if (_config == nil) {
            NSLog(@"ERROR:%s:%d: _config is nil.",__func__,__LINE__);
            return;
        }
        NSDictionary* dic = @{@"HTTPDNS_LOG_SAMPLE_RATE":[NSString stringWithFormat:@"%d", _config.logSamplingRate],
                              @"HTTPDNS_SWITCH": _config.enableHttpDnsCache?@"1":@"0",
                              @"SCHEDULE_LOG_INTERVAL":[NSString stringWithFormat:@"%d", _config.uploadLogInterval*1000],
                              @"SCHEDULE_SPEED_INTERVAL":[NSString stringWithFormat:@"%d", _config.speedTestInterval*1000],
                              @"SCHEDULE_TIMER_INTERVAL":[NSString stringWithFormat:@"%d", _config.refreshDomainIpInterval*1000],
                              @"IS_MY_HTTP_SERVER":_config.enableRequestFromSinaHttpDnsServer?@"1":@"0",
                              @"IS_SORT":_config.enableSDKUpdateServerIpOrder?@"1":@"0",
                              @"SPEEDTEST_PLUGIN_NUM":[NSString stringWithFormat:@"%d", _config.speedTestFactorWeight],
                              @"PRIORITY_PLUGIN_NUM":[NSString stringWithFormat:@"%d", _config.serverSuggestionFactorWeight],
                              @"DOMAIN_SUPPORT_LIST":_config.supportedDomainList,
                              @"HTTPDNS_SERVER_API": _config.httpDnsServerUrlList
                              };
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        BOOL result = [jsonData writeToFile:[self getFilePath] atomically:YES];
        if (!result) {
            NSLog(@"ERROR:%s:%d write to file failed.", __FUNCTION__, __LINE__);
        }
    }
}

- (void)requestingConfigDataFromServer {
    if (WBDNS_APP_VERSION.length == 0 || WBDNS_APPKEY.length == 0) {
        NSLog(@"ERROR:%s:%d WBDNS_APP_VERSION or WBDNS_APPKEY is not set.", __FUNCTION__, __LINE__);
        return;
    }
    
    if ([WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNCONNECTED || [WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_UNKNOWN) {
        return;
    }
    _isRequestingConfigDataFromServer = YES;
    NSString *identifierForVendor = [[UIDevice currentDevice].identifierForVendor UUIDString];
    NSString *secureCode = [WBDNSTools md5:[NSString stringWithFormat:@"%@%@",identifierForVendor,@"iheRFsFhLE9h9TRHVRLLBD6eS9ccQdLe"]];
    NSString* urlString = [NSString stringWithFormat:@"%@?k=%@&v=%@&c=httpdns&did=%@&s=%@",WBDNSCacheConfigServerUrl, WBDNS_APPKEY, WBDNS_APP_VERSION,identifierForVendor, [secureCode lowercaseString]];
    NSURL* url = [NSURL URLWithString:urlString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if (dic == nil) {
                    NSLog(@"ERROR:%s:%d deserialize response data failed.", __FUNCTION__, __LINE__);
                    return;
                }
                WBDNSConfig* oldConfig = [_config copy];
                //这个函数是线程安全的。
                [self readDataFromDic:dic];
                if (![oldConfig isEqual:_config]) {
                    [self saveConfigToJasonFile];
                    [[NSNotificationCenter defaultCenter] postNotificationName:WBDNSConfigDataChangeNotification object:nil];
                    [self updateServerUrlList];
                }
                _getConfigDataSuccessfully = YES;
            }
            else {
                _getConfigDataSuccessfully = NO;
                NSLog(@"ERROR:%s:%d request config data from server. failed reason:%@.",__FUNCTION__,__LINE__, error.description);
            }
            _isRequestingConfigDataFromServer = NO;
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

+ (void)setAppkey:(NSString *)appKey version:(NSString *)version {
    WBDNS_APPKEY = appKey;
    WBDNS_APP_VERSION = version;
}

+ (NSString *)getAppkey {
    return WBDNS_APPKEY;
}

+ (NSString *)getAppVersion {
    return WBDNS_APP_VERSION;
}

+ (void)setConfigServerUrl:(NSString *)url {
    if ([NSURL URLWithString:url] != nil) {
        WBDNSCacheConfigServerUrl = url;
    }
    else
    {
        NSLog(@"ERROR:%s:%d url:(%@) is invalid.", __FUNCTION__, __LINE__, url);
    }
}

+ (void)setLogServerUrl:(NSString *)url {
    if ([NSURL URLWithString:url] != nil) {
        WBDNSCacheLogServerUrl = url;
    }
    else
    {
        NSLog(@"ERROR:%s:%d url:(%@) is invalid.", __FUNCTION__, __LINE__, url);
    }
}



- (BOOL)isSupportedDomain:(NSString*)domain {
    NSArray* supportedDomainList = _config.supportedDomainList;
    //如果域名支持列表为空，那么默认支持所有的域名。
    if (supportedDomainList == nil || supportedDomainList.count == 0) {
        return YES;
    }
    
    for (NSString* temStr in supportedDomainList) {
        if([domain hasSuffix:temStr])
        {
            return YES;
        }
    }
    return NO;
}

- (void)readDataFromDic:(NSDictionary*)dic {
    if (dic == nil) {
        return;
    }
    
    if (_config == nil) {
        _config = [[WBDNSConfig alloc]init];
    }
    
    NSString *httpDnsSwitch = dic[@"HTTPDNS_SWITCH"];
    if ([httpDnsSwitch isEqualToString:@"1"]) {
        _config.enableHttpDnsCache = YES;
    }
    else if([httpDnsSwitch isEqualToString:@"0"]) {
        
        _config.enableHttpDnsCache = NO;
    }
    else {
        NSLog(@"WARNING%s:%d HTTPDNS_SWITCH:%@ is invalid.",__func__, __LINE__, httpDnsSwitch);
    }
    
    NSString *enableSDKUpdateServerIpOrderString = dic[@"IS_SORT"];
    if ([enableSDKUpdateServerIpOrderString isEqualToString:@"1"]) {
        _config.enableSDKUpdateServerIpOrder = YES;
    }
    else if([enableSDKUpdateServerIpOrderString isEqualToString:@"0"]) {
        
        _config.enableSDKUpdateServerIpOrder = NO;
    }
    else {
        NSLog(@"WARNING%s:%d IS_SORT:%@ is invalid.",__func__, __LINE__, enableSDKUpdateServerIpOrderString);
    }
    
    NSString *enableSinaHttpServer = dic[@"IS_MY_HTTP_SERVER"];
    if ([enableSinaHttpServer isEqualToString:@"1"]) {
        _config.enableRequestFromSinaHttpDnsServer = YES;
    }
    else if ([enableSinaHttpServer isEqualToString:@"0"]) {
        
        _config.enableRequestFromSinaHttpDnsServer = NO;
    }
    else {
        NSLog(@"WARNING%s:%d IS_MY_HTTP_SERVER:%@ is invalid.",__func__, __LINE__, enableSinaHttpServer);
    }
    
    
    NSString* logSamplingRate = dic[@"HTTPDNS_LOG_SAMPLE_RATE"];
    if (logSamplingRate && [WBDNSTools isPureInt:logSamplingRate]){
        _config.logSamplingRate = [logSamplingRate intValue];
    }
    else {
        NSLog(@"WARNING%s:%d SCHEDULE_LOG_INTERVAL:%@ is invalid.",__func__, __LINE__, logSamplingRate);
    }
    
    NSString* uploadLogInterval = dic[@"SCHEDULE_LOG_INTERVAL"];
    if (uploadLogInterval && [WBDNSTools isPureInt:uploadLogInterval]) {
        int logInterval = [uploadLogInterval intValue]/1000;
        if (logInterval > WBDNSMinInterval) {
            _config.uploadLogInterval = logInterval;
        }
        else {
            _config.uploadLogInterval = WBDNSMinInterval;
            NSLog(@"WARNING%s:%d SCHEDULE_LOG_INTERVAL:%@ is too short. use %d .",__func__, __LINE__, uploadLogInterval, WBDNSMinInterval);
        }
    }
    else {
        NSLog(@"WARNING%s:%d SCHEDULE_LOG_INTERVAL:%@ is invalid.",__func__, __LINE__, uploadLogInterval);
    }
    
    NSString *speedTestInterval = dic[@"SCHEDULE_SPEED_INTERVAL"];
    
    if (speedTestInterval && [WBDNSTools isPureInt:speedTestInterval]) {
        int speedInterval =[speedTestInterval intValue]/1000;
        
        if (speedInterval > WBDNSMinInterval) {
            _config.speedTestInterval = speedInterval;
        }
        else {
            _config.speedTestInterval = WBDNSMinInterval;
            NSLog(@"WARNING%s:%d SCHEDULE_SPEED_INTERVAL:%@ is too short. use %d .",__func__, __LINE__, speedTestInterval, WBDNSMinInterval);
        }
        
    }
    else {
        NSLog(@"WARNING%s:%d SCHEDULE_SPEED_INTERVAL:%@ is invalid.",__func__, __LINE__, speedTestInterval);
    }
    
    NSString* refreshDomainIpInterval = dic[@"SCHEDULE_TIMER_INTERVAL"];
    if (refreshDomainIpInterval && [WBDNSTools isPureInt:refreshDomainIpInterval]) {
        int refreshInterval = [refreshDomainIpInterval intValue]/1000;
        if (refreshInterval > WBDNSMinInterval) {
            _config.refreshDomainIpInterval = refreshInterval;
        }
        else {
            _config.refreshDomainIpInterval = WBDNSMinInterval;
            NSLog(@"WARNING%s:%d SCHEDULE_TIMER_INTERVAL:%@ is too short. use %d .",__func__, __LINE__, refreshDomainIpInterval, WBDNSMinInterval);
        }
        
    }
    else {
        NSLog(@"WARNING%s:%d SCHEDULE_TIMER_INTERVAL:%@ is invalid.",__func__, __LINE__, refreshDomainIpInterval);
    }
    
    NSString* speedTestFactorWeightString = dic[@"SPEEDTEST_PLUGIN_NUM"];
    if (speedTestFactorWeightString && [WBDNSTools isPureInt:speedTestFactorWeightString]) {
        _config.speedTestFactorWeight = [speedTestFactorWeightString intValue];
    }
    else {
        NSLog(@"WARNING%s:%d SPEEDTEST_PLUGIN_NUM:%@ is invalid.",__func__, __LINE__, speedTestFactorWeightString);
    }
    
//    NSString* serverSuggestionFactorWeightString = dic[@"PRIORITY_PLUGIN_NUM"];
//    if (serverSuggestionFactorWeightString && [WBDNSTools isPureInt:serverSuggestionFactorWeightString]){
//        _config.serverSuggestionFactorWeight = [serverSuggestionFactorWeightString intValue];
//    }
//    else {
//        NSLog(@"WARNING%s:%d PRIORITY_PLUGIN_NUM:%@ is invalid.",__func__, __LINE__, serverSuggestionFactorWeightString);
//    }
    
    NSArray* supportedDomainArray = dic[@"DOMAIN_SUPPORT_LIST"];
    if (supportedDomainArray) {
        _config.supportedDomainList = [NSArray arrayWithArray:supportedDomainArray];
    }
    
    NSArray* httpDnsServerUrlArray = dic[@"HTTPDNS_SERVER_API"];
    if (httpDnsServerUrlArray) {
        _config.httpDnsServerUrlList = [NSArray arrayWithArray:httpDnsServerUrlArray];
    }
}

- (void)readDataFromConfigFile {
    @synchronized(self) {
        NSData* fileData = [NSData dataWithContentsOfFile:[self getFilePath]];
        NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:fileData options:kNilOptions error:nil];
        [self readDataFromDic:dic];
    }
}

- (NSString *) getServerUrl {
    __block NSString* serverUrl;
    dispatch_sync(_serverUrlOperationQueue, ^{
        serverUrl = [_httpDnsServerUrlList firstObject];
    });
    return serverUrl;
    
}

- (NSString *) getLogServerUrl {
    return WBDNSCacheLogServerUrl;
}

-(void) updateServerUrlList {
    dispatch_async(_serverUrlOperationQueue, ^{
        
        for (NSString* url in _httpDnsServerUrlList) {
            if (![WBDNSTools findString:url inStringArray:_config.httpDnsServerUrlList]) {
                [_httpDnsServerUrlFailedTimesDic removeObjectForKey:url];
            }
        }
        
        for (NSString* url in _config.httpDnsServerUrlList) {
            if (![WBDNSTools findString:url inStringArray:_httpDnsServerUrlList]) {
                [_httpDnsServerUrlFailedTimesDic setObject:@(0) forKey:url];
            }
        }
        
        _httpDnsServerUrlList = [NSArray arrayWithArray:_config.httpDnsServerUrlList];
        _httpDnsServerUrlList = [_httpDnsServerUrlList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            int obj1FailTimes = [_httpDnsServerUrlFailedTimesDic[obj1] intValue];
            int obj2FailTimes = [_httpDnsServerUrlFailedTimesDic[obj2] intValue];
            
            if(obj1FailTimes > obj2FailTimes) {
                return NSOrderedDescending;
            }
            else if(obj1FailTimes < obj2FailTimes) {
                return NSOrderedAscending;
            }
            else {
                return NSOrderedSame;
            }
        }];
    });
}

- (void)setServerUrlFailedTimes:(NSString *)url {
    
    dispatch_async(_serverUrlOperationQueue, ^{
        
        if (url == nil) {
            NSLog(@"ERROR:%s:%d: serverUrl is nil.",__FUNCTION__,__LINE__);
            return;
        }
        
        NSNumber* failedTimes = _httpDnsServerUrlFailedTimesDic[url];
        if (failedTimes) {
            _httpDnsServerUrlFailedTimesDic[url] = @(failedTimes.intValue+1);
        }
        else {
            NSLog(@"ERROR:%s:%d: url(%@) is not found in dic.",__FUNCTION__,__LINE__, url);
            return;
        }
        
        _httpDnsServerUrlList = [[_httpDnsServerUrlList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            int obj1FailTimes = [_httpDnsServerUrlFailedTimesDic[obj1] intValue];
            int obj2FailTimes = [_httpDnsServerUrlFailedTimesDic[obj2] intValue];
            
            if(obj1FailTimes > obj2FailTimes) {
                return NSOrderedDescending;
            }
            else if(obj1FailTimes < obj2FailTimes) {
                return NSOrderedAscending;
            }
            else {
                return NSOrderedSame;
            }
        }] mutableCopy];
    });
}

@end
