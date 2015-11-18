//
//  WBDNSLogFile.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/27.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBDNSLogFile : NSObject

@property (strong, nonatomic) NSString *filePath;

@property (strong, nonatomic) NSString *fileName;

@property (strong, nonatomic) NSDate *createDate;

@property (strong, nonatomic) NSDate *modifyDate;

@property (assign, nonatomic) NSInteger fileSize;

- (instancetype)initWithPath:(NSString *)filePath;

@end
