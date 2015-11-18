//
//  IpModel.h
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *
 * 项目名称: DNSCache <br>
 * 类名称: IpModel <br>
 * 类描述: ip数据模型 - 对应ip表 <br>
 * 创建人: Robert Yang <br>
 * 创建时间: 2015-7-26 下午5:23:06 <br>
 *
 * 修改人:  <br>
 * 修改时间:  <br>
 * 修改备注:  <br>
 *
 * @version V1.0
 */
@interface WBDNSIpModel : NSObject <NSCopying>
/**
 * 自增id <br>
 *
 * 该字段映射 WBDNS_IP_COLUMN_ID 字段 <br>
 */
@property (nonatomic, assign) int id;

/**
 * domain id 关联id
 *
 * 该字段映射 WBDNS_IP_COLUMN_DOMAIN_ID 字段 <br>
 */
@property (nonatomic, assign) int d_id;

/**
 * 服务器ip地址
 *
 * 该字段映射 WBDNS_IP_COLUMN_PORT 字段 <br>
 */
@property (nonatomic, strong) NSString *ip;

/**
 * ip服务器对应的端口
 *
 * 该字段映射 WBDNS_IP_COLUMN_PORT 字段 <br>
 */
@property (nonatomic, assign) int port;

/**
 * ip服务器对应的sp运营商
 *
 * 该字段映射 WBDNS_IP_COLUMN_SP 字段 <br>
 */
@property (nonatomic, strong) NSString *sp;

/**
 * ip过期时间
 *
 * 该字段映射 WBDNS_IP_COLUMN_TTL 字段 <br>
 */
@property (nonatomic, strong) NSString *ttl;

/**
 * ip服务器优先级-排序算法策略使用
 *
 * 该字段映射 WBDNS_IP_COLUMN_PRIORITY 字段 <br>
 */
@property (nonatomic, strong) NSString *priority;

/**
 *  访问ip服务器的往返时延
 *
 * 该字段映射类 WBDNS_IP_COLUMN_RTT 字段
 */
@property (nonatomic, strong) NSString *rtt;

/**
 * ip服务器链接产生的成功数
 *
 * 该字段映射 WBDNS_IP_COLUMN_SUCCESS_NUM 字段 <br>
 */
@property (nonatomic, strong) NSString *success_num;

/**
 * ip服务器链接产生的错误数
 *
 * 该字段映射 WBDNS_IP_COLUMN_ERR_NUM 字段 <br>
 */
@property (nonatomic, strong) NSString *err_num;

/**
 * ip服务器最后成功链接时间
 *
 * 该字段映射 WBDNS_IP_COLUMN_FINALLY_SUCCESS_TIME 字段 <br>
 */
@property (nonatomic, strong) NSString *finally_success_time;


/**
 * ip服务器最后失败链接时间
 *
 * 该字段映射WBDNS_IP_COLUMN_FINALLY_FAIL_TIME 字段 <br>
 */
@property (nonatomic, strong) NSString *finally_fail_time;

/**
 *  此IP记录从服务器的更新时间
 *  该字段映射WBDNS_IP_COLUMN_FINALLY_UPDATE_TIME 字段 <br>
 */
@property (nonatomic, strong) NSString* finally_update_time;

/**
 * 评估体系 评分分值
 */
@property (nonatomic, assign) NSInteger grade;

/**
 *  转成用json表示的对象。
 *
 *  @return json字符串
 */
- (NSString*)toJson;


/**
 *  转成用词典表示的对象
 *
 *  @return 用词典表示的对象
 */
- (NSDictionary*)toDictionary;

@end
