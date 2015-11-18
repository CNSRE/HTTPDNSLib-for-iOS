//
//  WBDNSCacheConfig.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/13.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WBDNSConfigDataChangeNotification @"WBDNSConfigDataChangeNotification"
@class WBDNSConfig;
@interface WBDNSConfigManager : NSObject

@property (nonatomic, strong, getter=getConfig) WBDNSConfig *config;

/**
 *  获取WBDNSConfigManager的全局唯一实例。
 *
 *  @return WBDNSConfigManager的全局唯一实例。
 */
+ (WBDNSConfigManager *)sharedInstance;

/**
 *  获取WBDNSConfigManager的全局唯一参数配置
 *
 *  @return WBDNSConfigManager的全局唯一参数配置
 */
+ (WBDNSConfig *)sharedConfig;

/**
 *  设置使用DNSCache SDK的app 的唯一标识符和版本号，用于请求对应的参数配置文件。
 *  App应在Sina http dns server网站配置此标识符合版本对应的参数配置列表。
 *
 *  @param appKey  App申请的唯一标识符
 *  @param version App的版本号。
 */
+ (void)setAppkey:(NSString *)appKey version:(NSString *)version;

/**
 *  设置配置下发服务器的网址。
 *
 *  @param url 配置下发服务器的网址。
 */
+ (void)setConfigServerUrl:(NSString *)url;

/**
 * 设置上传Log服务器的地址
 *
 *  @param url 上传Log服务器的地址。
 */
+ (void)setLogServerUrl:(NSString *)url;

/**
 *  判断一个domain是否在服务器的支持列表中。
 *
 *  @param domain 待查询的domain
 *
 *  @return YES 代表服务器支持查询，NO代表不支持。
 */
- (BOOL)isSupportedDomain:(NSString *)domain;

/**
 *  获取设置的App key.
 *
 *  @return App key
 */
+ (NSString *)getAppkey;

/**
 *  获取设置的App version。
 *
 *  @return App Version
 */
+ (NSString *)getAppVersion;

/**
 *  获取推荐的服务器Url
 *
 *  @return 推荐的服务器Url
 */
- (NSString *)getServerUrl;

/**
 *  获取Log服务器Url
 *
 *  @return Log服务器Url
 */
- (NSString *)getLogServerUrl;

/**
 *  当使用服务器推荐URL失败的时候，调用此函数，通知这个URL调用失败了一次。
 *
 *  @param url 访问失败的URL
 */
- (void)setServerUrlFailedTimes:(NSString *) url;

@end

