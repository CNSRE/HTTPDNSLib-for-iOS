//
//  WBDNSConfig.h
//  DNSCache
//
//  Created by Robert Yang on 15/9/1.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WBDNSMinInterval 30

@interface WBDNSConfig : NSObject<NSCopying>
/**
 *  是否允许从HttpDns Server 或者cache 获取ip。 YES 允许， NO 将对所有请求返回nil。
 */
@property (atomic, assign) BOOL enableHttpDnsCache;
/**
 *  概率性记录某条日志的抽样率
 */
@property (atomic, assign) int logSamplingRate;

/**
 *  上传HTTP Cache Log的间隔周期。单位是秒，但是服务器下发的是毫秒。
 */
@property (atomic, assign) int uploadLogInterval;
/**
 *  对缓存域名的ip测速的间隔周期。单位是秒，但是服务器下发的是毫秒。
 */
@property (atomic, assign) int speedTestInterval;

/**
 *  刷新缓存内域名对应ip的间隔周期。单位是秒，但是服务器下发的是毫秒。
 */
@property (atomic, assign) int refreshDomainIpInterval;

/**
 *  SDK可以从多种途径获取域名对应Ip，这个变量控制是否从Sina HTTP DNS server获取ip. YES 代表允许，NO代表不允许。
 */
@property (atomic, assign) BOOL enableRequestFromSinaHttpDnsServer;

/**
 *  允许SDK根据本地获取信息 修改server返回的Domain对应IP的优先级。
 */
@property (atomic, assign) BOOL enableSDKUpdateServerIpOrder;

/**
 *  SDK计算IP列表中一个ip的优先级时，测速所占权重。
 */
@property (atomic, assign) int  speedTestFactorWeight;

/**
 *  SDK计算IP列表中一个ip的优先级时，Server返回优先级所占权重。
 */
@property (atomic, assign) int  serverSuggestionFactorWeight;

/**
 *  目前服务器支持的domain列表。里面存储NSString 对象，代表一个支持的domain。
 */
@property (atomic, strong) NSArray *supportedDomainList;

/**
 *  Sina http dns server的地址。会返回多个，默认使用第一个，其它作为备用。用NSString对象表示。
 */
@property (atomic, strong) NSArray *httpDnsServerUrlList;

@end
