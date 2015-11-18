//
//  DBManager.h
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "WBDNSModel.h"
@interface WBDNSDBManager : NSObject

- (WBDNSDomainModel*)queryDomainInfoWithIPArray:(NSString *)domain sp:(NSString *)sp containsExpiredIp:(BOOL)containsExpiredIp hasDbOpen:(BOOL)hasDbOpen;

- (WBDNSDomainModel *)updateDomainModelWithIpArray:(WBDNSDomainModel *) model;

- (WBDNSIpModel *)queryIpModel:(NSString *)severIp sp:(NSString *)sp domainId:(int)d_id hasDbOpen:(BOOL)hasDbOpen;

- (NSArray *)queryAllDomainInfoWithIpArray:(BOOL)withIPArray containsExpiredIp:(BOOL)containsExpiredIp hasDbOpen:(BOOL)hasDbOpen;

- (BOOL)updateIpModel:(WBDNSIpModel *)model hasDbOpen:(BOOL)hasDbOpen;

- (void)clear;

@end
