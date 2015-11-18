//
//  NetworkManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/4.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSNetworkManager.h"
#import "WBDNSCacheManager.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/CaptiveNetwork.h>
@implementation WBDNSNetworkManager
{
    id<WBDNSCacheProtocol> _manager;
    WBDNSReachability *_reachability;
    WBDNSNetworkManager *_sharedInstance;
    
}

+ (instancetype)sharedInstance {
    static  WBDNSNetworkManager* sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WBDNSNetworkManager alloc]init];
    });
    return sharedInstance;
}

- (void)setDnsCacheManager:(id<WBDNSCacheProtocol>)dnsCacheManager {
    _manager = dnsCacheManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _reachability = [WBDNSReachability reachabilityForInternetConnection];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kWBDNSReachabilityChangedNotification object:nil];
        [_reachability startNotifier];
        self.networkType = WBDNS_NETWORK_TYPE_UNKNOWN;
        self.networkTypeString = [WBDNSTools networkTypeToString:self.networkType];
        self.lastSpTypeString = @"UnknownSP";
        self.currentSpTypeString = @"UnkownSP";
        [self refreshNetworkInfo:_reachability];
    }
    return  self;
}

- (void)reachabilityChanged:(NSNotification *)note {
    WBDNSReachability * reach = [note object];
    [self refreshNetworkInfo:reach];
    WBDNSNetworkStatus status = [reach currentReachabilityStatus];
    [[NSNotificationCenter defaultCenter]postNotificationName:WBDNSNetworkStatusChangeNotification object:@(status)];
}

- (void)refreshNetworkInfo:(WBDNSReachability *)reach {
    if (reach == nil) {
        reach = _reachability;
    }
    
    WBDNSNetworkStatus status = [reach currentReachabilityStatus];
    switch (status) {
        case WBDNSNotReachable:
            self.networkType = WBDNS_NETWORK_TYPE_UNCONNECTED;
            self.networkTypeString = [WBDNSTools networkTypeToString:self.networkType];
            break;
        case WBDNSReachableViaWiFi:
        {
            self.networkType = WBDNS_NETWORK_TYPE_WIFI;
            self.networkTypeString = [WBDNSTools networkTypeToString:self.networkType];
            if((self.currentSpTypeString = [self fetchSSIDName]) == nil) {
                self.currentSpTypeString = @"UnkownWifiSP";
            }
            
            if (self.currentSpTypeString != self.lastSpTypeString) {
                [_manager clearMemoryCache];
            }
            self.lastSpTypeString = self.currentSpTypeString;
            break;
        }
        case WBDNSReachableViaWWAN:
        {
            self.networkType = WBDNS_NETWORK_TYPE_MOBILE;
            self.networkTypeString = [WBDNSTools networkTypeToString:self.networkType];
            CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
            CTCarrier *carrier = [info subscriberCellularProvider];
            self.currentSpTypeString = [self getSPNameFromCode:carrier.mobileNetworkCode];
            NSLog(@"%@, %@", carrier.carrierName, carrier.mobileNetworkCode);
            
            if (self.currentSpTypeString != self.lastSpTypeString) {
                [_manager clearMemoryCache];
            }
            self.lastSpTypeString = self.currentSpTypeString;
            break;
        }
        default:
            self.networkType = WBDNS_NETWORK_TYPE_UNKNOWN;
            self.networkTypeString = [WBDNSTools networkTypeToString:self.networkType];
            NSLog(@"ERROR:%s:%d this condition should not appear.", __func__, __LINE__);
            break;
    }
    
}

- (NSArray *)chinaMobileNetworkCode {
    return @[@"00",@"02",@"07",@"20"];
}

- (NSArray *)chinaUnicomNetworkCode {
    return @[@"01",@"06"];
}

- (NSArray *)chinaTelecomNetworkCode {
    return @[@"03",@"05"];
}

- (NSString *)getSPNameFromCode:(NSString *)networkCode {
    if([[self chinaMobileNetworkCode] containsObject:networkCode]) {
        return @"ChinaMobile";
    }
    else if([[self chinaUnicomNetworkCode] containsObject:networkCode]) {
        return @"ChinaUnicom";
    }
    else if([[self chinaTelecomNetworkCode] containsObject:networkCode]) {
        return @"ChinaTelecom";
    }
    else {
        return @"UnknowSP";
    }
}

- (NSString *)fetchSSIDName {
    return [self fetchSSIDInfo][@"SSID"];
}

- (NSDictionary *)fetchSSIDInfo {
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(
                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        //NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty) {
            break;
        }
    }
    return SSIDInfo;
}

- (void)dealloc {
    [_reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
