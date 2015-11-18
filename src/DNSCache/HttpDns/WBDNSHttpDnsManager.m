//
//  HttpDnsManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/4.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSHttpDnsManager.h"
#import "WBDNSNetworkManager.h"
#import "WBDNSConfig.h"
#import "WBDNSConfigManager.h"
#import "WBDNSLogManager.h"

@implementation WBDNSHttpDnsManager

- (void)requestHttpDnsByDomain:(NSString *)domain completionHandler:(void(^)(WBDNSHttpDnsPack *))completionHandler {
    NSString* urlPrefix = [[WBDNSConfigManager sharedInstance] getServerUrl];
    if (urlPrefix == nil) {
        NSLog(@"ERROR:%s:%d urlPrefix is nil.", __FUNCTION__, __LINE__);
        return;
    }
    NSURL *url;
    if ([urlPrefix hasPrefix:@"http://"]||[urlPrefix hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/dns?domain=%@", urlPrefix, domain]];
    }
    else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/dns?domain=%@",  urlPrefix, domain]];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    session.sessionDescription = urlPrefix;
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            //NSString* str = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
            NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (jsonDic) {
                WBDNSHttpDnsPack* dnsPack = [WBDNSHttpDnsPack generateInstanceFromDic:jsonDic];
                dnsPack.localhostSp = [WBDNSNetworkManager sharedInstance].currentSpTypeString;
                
                [WBDNSLogManager log:WBDNS_LOG_TYPE_INFO action:WBDNS_LOG_ACTION_INFO_PACK body:[dnsPack toDictionary] samplingRate:[WBDNSConfigManager sharedInstance].config.logSamplingRate];
                
                //检测服务器返回的运营商SP 是否正确
                if ([WBDNSNetworkManager sharedInstance].networkType == WBDNS_NETWORK_TYPE_MOBILE) {
                    
                    NSInteger deviceSpCode = [dnsPack.device_sp integerValue];
                    if (![dnsPack.localhostSp isEqualToString:[WBDNSTools serviceProviderTypeToString:(int)deviceSpCode]]) {
                        [WBDNSLogManager log:WBDNS_LOG_TYPE_ERROR action:WBDNS_LOG_ACTION_ERR_SPINFO body:[dnsPack toDictionary]];
                    }
                }
                
                if (completionHandler) {
                    completionHandler(dnsPack);
                }
            }
            else {
                NSString* str = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                NSLog(@"ERROR:%s:%d request ip from sina dns failed reason:response data is not a valid json. \n response:\n%@",__FUNCTION__,__LINE__,str);
                if (completionHandler) {
                    completionHandler(nil);
                }
            }
            
        }
        else {
            if (completionHandler) {
                completionHandler(nil);
            }
            
            [[WBDNSConfigManager sharedInstance] setServerUrlFailedTimes:session.sessionDescription];
            NSLog(@"ERROR:%s:%d request ip from sina dns failed reason:%@.",__FUNCTION__,__LINE__, error.description);
            
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

@end
