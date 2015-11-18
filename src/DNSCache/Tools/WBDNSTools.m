//
//  Tools.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/3.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSTools.h"
#import "WBDNSNetworkManager.h"
#import <CommonCrypto/CommonDigest.h>
@implementation WBDNSTools
{
    NSDateFormatter *_dateFormat;
}

+ (instancetype)sharedInstance {
    static WBDNSTools* sharedInsance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInsance = [[WBDNSTools alloc]init];
    });
    return sharedInsance;
}

- (instancetype)init {
    if (self = [super init]) {
        _dateFormat = [[NSDateFormatter alloc]init];
        [_dateFormat setDateFormat:[WBDNSTools dateFormatter]];
    }
    return self;
}

- (NSDate *)dateFromString:(NSString *)s {
    return [_dateFormat dateFromString:s];
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [_dateFormat stringFromDate:date];
}

+ (NSString *)dateFormatter
{
    return @"yyyy-MM-dd HH:mm:ss Z";
}

+ (NSString *)getIpUrlFromDomainUrl:(NSString *)domainUrl host:(NSString *)host ip:(NSString *)ip
{
    if (domainUrl == nil) {
        NSLog(@"ERROR:%s:%d failed reason:domainUrl is nil.",__FUNCTION__,__LINE__);
        return domainUrl;
    }
    
    if (host == nil) {
        NSLog(@"ERROR:%s:%d failed reason:host is nil.",__FUNCTION__,__LINE__);
        return domainUrl;
    }
    
    if (ip == nil) {
        NSLog(@"ERROR:%s:%d failed reason:ip is nil.",__FUNCTION__,__LINE__);
        return domainUrl;
    }
    
    NSRange range = [domainUrl rangeOfString:host];
    if (range.length != host.length) {
        NSLog(@"ERROR:%s:%d failed reason:can't find %@ in %@.",__FUNCTION__,__LINE__, host, domainUrl);
        return domainUrl;
    }
    NSString *ipUrl = [domainUrl stringByReplacingCharactersInRange:range withString:ip];
    return ipUrl;
}

+ (NSString *) md5:(NSString *)str
{
     const char *cStr = [str UTF8String];
     unsigned char result[16];
     CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
     NSString* orginalMd5 = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                          result[0], result[1], result[2], result[3],
                                           result[4], result[5], result[6], result[7],
                                           result[8], result[9], result[10], result[11],
                                           result[12], result[13], result[14], result[15]
            ];
    return [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c",
            [orginalMd5 characterAtIndex:1],
            [orginalMd5 characterAtIndex:5],
            [orginalMd5 characterAtIndex:2],
            [orginalMd5 characterAtIndex:10],
            [orginalMd5 characterAtIndex:17],
            [orginalMd5 characterAtIndex:9],
            [orginalMd5 characterAtIndex:25],
            [orginalMd5 characterAtIndex:27]];
}


+ (NSString *)getHostNameOfUrl:(NSString *)urlString
{
    NSURL* url = [NSURL URLWithString:urlString];
    if (url == nil) {
        NSLog(@"ERROR:%s:%d failed reason: %@ is invaild url.",__FUNCTION__,__LINE__, urlString);
    }
    
    return  url.host;
}

+ (NSString *)networkTypeToString:(int)networkType
{
    NSString* networkTypeString;
    
    switch (networkType) {
        case WBDNS_NETWORK_TYPE_UNCONNECTED:
            networkTypeString = @"NoNetwork";
            break;
        case WBDNS_NETWORK_TYPE_UNKNOWN:
            networkTypeString = @"UnknownNetwork";
            break;
        case WBDNS_NETWORK_TYPE_WIFI:
            networkTypeString = @"WifiNetwork";
            break;
        case WBDNS_NETWORK_TYPE_MOBILE:
            networkTypeString = @"OperatorNetwork";
            break;
        default:
            networkTypeString = @"UnknownNetwork";
            break;
    }
    return networkTypeString;
}

+ (NSString *)serviceProviderTypeToString:(int)spType
{
    NSString *spTypeString;
    
    switch (spType) {
        case WBDNS_MOBILE_UNKNOWN:
            spTypeString = @"UnknownSP";
            break;
        case WBDNS_MOBILE_TELCOM:
            spTypeString = @"ChinaTelecom";
            break;
        case WBDNS_MOBILE_UNICOM:
            spTypeString = @"ChinaUnicom";
            break;
        case WBDNS_MOBILE_CHINAMOBILE:
            spTypeString = @"ChinaMobile";
            break;
        default:
            spTypeString = @"UnknowNetwork";
            break;
    }
    return spTypeString;
}

+ (BOOL)isDomainModelExpired:(WBDNSDomainModel *)domainModel expireDuration:(long)duration
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:[WBDNSTools dateFormatter]];
    NSDate* date = [formatter dateFromString:domainModel.time];
    int ttl = [domainModel.ttl intValue];
    NSDate* currentDate = [NSDate date];
    NSTimeInterval inteval = [currentDate timeIntervalSinceDate:date];
    if (inteval > ttl + duration) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (BOOL)isIpRecordExpired:(WBDNSIpModel *)ipModel expireDuration:(long)duration
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:[WBDNSTools dateFormatter]];
    NSDate* date = [formatter dateFromString:ipModel.finally_update_time];
    int ttl = [ipModel.ttl intValue];
    NSDate* currentDate = [NSDate date];
    NSTimeInterval inteval = [currentDate timeIntervalSinceDate:date];
    if (inteval > ttl + duration) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (BOOL)isTestTimeExpired:(NSDate *)time expiredTime:(int)expiredTime
{
    //容错处理，如果间隔小于10秒，设为10秒。
    if (expiredTime < 10) {
        expiredTime = 10;
    }
    
    if ([time compare:[NSDate date]] == NSOrderedDescending) {
        NSLog(@"ERROR:%s:%d time(%@) is invalid.", __func__,__LINE__, time);
        return YES;
    }
    else {
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:time];
        if (interval < expiredTime) {
            return NO;
        }
        else {
            return YES;
        }
    }
}

+ (BOOL)isPureInt:(NSString *)string {
    
    NSScanner* scan = [NSScanner scannerWithString:string];
    
    int val;
    
    return[scan scanInt:&val] && [scan isAtEnd];
    
}

+ (BOOL)isIpV4Address:(NSString *) url {
    NSString *regex = @"^(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])(\\.(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])){3}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:url];
}

+ (BOOL)isStringArray:(NSArray *)arr1 equalToStringArray2:(NSArray *)arr2 {
    if (arr1 == nil && arr2 == nil) {
        return YES;
    }
    else if(arr1 == nil) {
        if (arr2.count == 0) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else if(arr2 == nil) {
        if (arr1.count == 0) {
            return YES;
        }
        else {
            return NO;
        }
    }
    
    if (arr1.count != arr2.count) {
        return NO;
    }
    
    for (NSString* item1 in arr1) {
        if (![self findString:item1 inStringArray:arr2]) {
            return NO;
        }
    }
    
    for (NSString* item2 in arr2) {
        if (![self findString:item2 inStringArray:arr1]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)findString:(NSString *)str inStringArray:(NSArray *)stringArray {
    for (NSString* temStr in stringArray) {
        if([str isEqualToString:temStr]) {
            return YES;
        }
    }
    return NO;
}

@end
