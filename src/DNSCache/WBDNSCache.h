//
//  DNSCache.h
//  DNSCache
//
//  Created by Robert Yang on 15/7/29.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  用于封装转换后URL的模型
 */
@interface WBDNSDomainInfo : NSObject

/**
 *  url 的唯一编号，目前没有使用。
 */
@property (nonatomic, strong) NSString *id;
/**
 *  转换后的URL
 */
@property (nonatomic, strong) NSString *url;

/**
 *  需要设置到Http head 中的主机头, 当host为空或者nil时，代表不设置host。
 */
@property (nonatomic, strong) NSString *host;

/**
 *  根据参数，生成一个WBDNSDomainInfo模型。
 *
 *  @param id   编号
 *  @param url  网址
 *  @param host 主机名
 *
 *  @return 生成的WBDNSDomainInfo模型。
 */
- (instancetype)initWithId:(NSString *)id url:(NSString *)url host:(NSString *)host;

@end


@interface WBDNSCache : NSObject
/**
 *  获取WBDNSCache的全局唯一对象。
 *
 *  @return WBDNSCache的全局唯一对象。
 */
+ (instancetype)sharedInstance;

/**
 *  从Http DNS server获取 转换后的URL。
 *
 *  @param urlString 原始的URL 注意Url必须已http:// 开头 否则SDK无法识别是否是合法的域名。
 *
 *  @return 转换后的直接使用的URL。是一个数组对象，里面有一个或多个WBDNSDomainInfo对象, nil 当没有网络且缓存数据过期，或者服务器配置禁止HTTPDNS服务的时候，返回nil。
 */
- (NSArray *)getDomainServerIpFromURL:(NSString *)urlString;

/**
 *  SDK 工作的原理是当用户请求domain 对应ip时，如果本地缓存没有数据，先取从本地dns获取Ip 返回给用户，同时向Sina http dns服务器请求，请求成功之后，存入缓存，下次用户请求便获得sina http dns 的IP，所以如果用户知道哪些domain后面会使用，那么可以提前从Http服务器请求，那么下次请求的时候，就会直接取到缓存中的sina http dns 返回的ip。
 *
 *  @param domainsArray 提前请求到domain数组，里面存储的是NSString类型的 域名
 */
- (void)preloadDomains:(NSArray *)domainsArray;


/**
 *  用于初始化整个全局唯一对象，仅程序初始化时调用一次。
 */
- (void)initialize;

/**
 *  设置应用程序在SinaDNS 服务器注册的app标识符和版本号。请在初始化函数调用前设置。
 *
 *  @param appKey  在新浪DNS服务器注册的 app标识符
 *  @param version 在新浪DNS服务器注册的 app版本号。
 */
+ (void)setAppkey:(NSString *)appKey version:(NSString *)version;


/**
 *  WBDNSCache SDK 需要从配置服务器获取需要的各种配置参数，如dns服务器地址，上传log服务器地址，网址支持白名单等参数。
 *  需要调用方设置配置服务器的地址，请在初始化函数前设置。
 *
 *  @param url WBDDSNCacheSDK的配置服务器地址
 */
+ (void)setConfigServerUrl:(NSString*)url;

@end
