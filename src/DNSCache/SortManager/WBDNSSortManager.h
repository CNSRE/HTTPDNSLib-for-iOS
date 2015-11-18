//
//  WBDNSSortManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/24.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBDNSModel.h"

@interface WBDNSSortManager : NSObject

+ (WBDNSDomainModel *)sortIpArrayOfModel:(WBDNSDomainModel*)model;

@end
