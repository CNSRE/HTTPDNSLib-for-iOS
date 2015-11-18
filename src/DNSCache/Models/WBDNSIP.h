//
//  IP.h
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A记录相关字段信息
 */
@interface WBDNSIP : NSObject

/**
 * A记录IP
 */
@property (nonatomic, strong) NSString *ip;

/**
 * 域名A记录过期时间
 */
@property (nonatomic, strong) NSString *ttl;

/**
 * 服务器推荐使用的A记录 级别从0-10
 */
@property (nonatomic, strong) NSString *priority;

@end
