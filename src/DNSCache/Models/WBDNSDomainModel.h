//
//  DomainModel.h
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WBDNS_LOCAL_DNS_ID -1

/**
 *
 * 项目名称: DNSCache <br>
 * 类名称: DomainModel <br>
 * 类描述: 域名数据模型 - 对应domain表 <br>
 * 创建人: Robert Yang <br>
 * 创建时间: 2015-7-28 下午5:04:01 <br>
 *
 * 修改人:  <br>
 * 修改时间:  <br>
 * 修改备注: <br>
 *
 * @version V1.0
 */
@interface WBDNSDomainModel : NSObject<NSCopying>
/**
 * 自增id <br>
 *
 * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_ID 字段 <br>
 */
@property (nonatomic, assign) int id;

/**
 * 域名 <br>
 *
 * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_DOMAIN 字段 <br>
 */
@property (nonatomic, strong) NSString *domain;

/**
 * 运营商 <br>
 *
 * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_SP 字段 <br>
 */
@property (nonatomic, strong) NSString *sp;

/**
 * 域名过期时间 <br>
 *
 * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_TTL 字段 <br>
 */
@property (nonatomic, strong) NSString *ttl;

/**
 * 域名最后查询时间 <br>
 *
 * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_TIME 字段 <br>
 */
@property (nonatomic, strong) NSString *time;

/**
 * 域名关联的ip数组 <br>
 */
@property (nonatomic, strong) NSMutableArray *ipModelArray;

- (NSArray *)serverIpArray;

- (NSString *)toJson;

- (NSDictionary *)toDictionary;

@end
