//
//  WBDNSWeakTimer.h
//  DNSCache
//
//  Created by Robert Yang on 15/8/17.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WBDNSTimerHandler)(id userInfo);

@interface WBDNSWeakTimer : NSObject
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                      target:(id)aTarget
                                    selector:(SEL)aSelector
                                    userInfo:(id)userInfo
                                     repeats:(BOOL)repeats;

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                      block:(WBDNSTimerHandler)block
                                   userInfo:(id)userInfo
                                    repeats:(BOOL)repeats;
@end
