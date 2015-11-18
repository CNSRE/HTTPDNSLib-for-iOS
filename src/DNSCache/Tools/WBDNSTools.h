//
//  Tools.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/3.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WBDNSDomainModel;
@class WBDNSIpModel;
@interface WBDNSTools : NSObject

+ (instancetype)sharedInstance;

- (NSDate *)dateFromString:(NSString *)s;

- (NSString *)stringFromDate:(NSDate *)date;
//非标准的md5算法，然后从 md5 获取 1 , 5 , 2 , 10 , 17 , 9 , 25 , 27 位(从0开始)的字符按顺序拼成一个8位长度的字符串 s
+ (NSString *) md5:(NSString *)str;

+ (NSString *)dateFormatter;

+ (NSString *)getIpUrlFromDomainUrl:(NSString *)domainUrl host:(NSString *)host ip:(NSString *) ip;

+ (NSString *)getHostNameOfUrl:(NSString *)urlString;

+ (NSString *)networkTypeToString:(int)networkType;

+ (NSString *)serviceProviderTypeToString:(int)spType;

+ (BOOL)isDomainModelExpired:(WBDNSDomainModel *)domainModel expireDuration:(long) duration;

+ (BOOL)isIpV4Address:(NSString *)url;

+ (BOOL)isIpRecordExpired:(WBDNSIpModel *)ipModel expireDuration:(long) duration;

+ (BOOL)isTestTimeExpired:(NSDate *)time expiredTime:(int) expiredTime;

+ (BOOL)isPureInt:(NSString *)string;

+ (BOOL)isStringArray:(NSArray *)arr1 equalToStringArray2:(NSArray *) arr2;

+ (BOOL)findString:(NSString *)str inStringArray:(NSArray *) stringArray;
@end
