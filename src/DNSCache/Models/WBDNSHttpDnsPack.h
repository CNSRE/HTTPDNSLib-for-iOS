//
//  HttpDnsPack.h
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *
 * 项目名称: DNSCache
 * 类名称: HttpDnsPack
 * 类描述: 将httpdns返回的数据封装一层，方便日后httpdns接口改动不影响数据库模型。 并且该接口还会标识httpdns错误之后的一些信息用来上报
 * 创建人: Robert Yang
 * 创建时间: 2015-7-30 上午11:20:11
 *
 * 修改人:
 * 修改时间:
 * 修改备注:
 *
 * @version V1.0
 */
@interface WBDNSHttpDnsPack : NSObject
/**
 * httpdns 接口返回字段 域名信息
 */
@property (nonatomic, strong) NSString *domain;

/**
 * httpdns 接口返回字段 请求的设备ip（也可能是sp的出口ip）
 */
@property (nonatomic, strong) NSString *device_ip;

/**
 * httpdns 接口返回字段 请求的设备sp运营商
 */
@property (nonatomic, strong) NSString *device_sp;

/**
 * httpdns 接口返回的a记录。（目前不包含cname别名信息）
 */
@property (nonatomic, strong) NSMutableArray *dns;

/**
 * 本机识别的sp运营商，手机卡下运营商正常，wifi下为ssid名字`
 */
@property (nonatomic, strong) NSString *localhostSp;

+ (WBDNSHttpDnsPack *)generateInstanceFromDic:(NSDictionary *)dic;

- (NSDictionary *)toDictionary;

@end
