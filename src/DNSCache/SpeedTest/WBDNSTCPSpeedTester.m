//
//  TCPSpeedTester.m
//  DNSCache
//
//  Created by Robert Yang on 15/8/19.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSTCPSpeedTester.h"
#import "WBDNSTools.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <fcntl.h>
#import <arpa/inet.h>
#import <netdb.h>

@implementation WBDNSTCPSpeedTester 

-(NSString*) getHostByName:(NSString*) url {
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;        // PF_INET if you want only IPv4 addresses
    hints.ai_protocol = IPPROTO_TCP;
    
    struct addrinfo *addrs, *addr;
    
    getaddrinfo([url UTF8String], NULL, &hints, &addrs);
    NSMutableArray* ipStringArray = [NSMutableArray array];
    for (addr = addrs; addr; addr = addr->ai_next) {
        
        char host[NI_MAXHOST];
        getnameinfo(addr->ai_addr, addr->ai_addrlen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
        //            printf("%s\n", host);
        [ipStringArray addObject:[NSString stringWithUTF8String:host]];
    }
    freeaddrinfo(addrs);
    if (ipStringArray.count > 0) {
        return ipStringArray.firstObject;
    }
    else {
        return nil;
    }
}

/**
 *  本测速函数，使用linux socket connect 和select函数实现的。 基于以下原理
 *  1. 即使套接口是非阻塞的。如果连接的服务器在同一台主机上，那么在调用connect 建立连接时，连接通常会立即建立成功，我们必须处理这种情况。
 *  2. 源自Berkeley的实现(和Posix.1g)有两条与select 和非阻塞IO相关的规则：
 *     A. 当连接建立成功时，套接口描述符变成可写；
 *     B. 当连接出错时，套接口描述符变成既可读又可写。
 *  @param ip 用于测速对Ip，应该是IPv4格式。
 *
 *  @return 测速结果，单位时毫秒，WBDNS_SOCKET_CONNECT_TIMEOUT_RTT 代表超时。
 */
-(int) testSpeedOf:(NSString *)ip {
    NSString* oldIp = ip;
    if (![WBDNSTools isIpV4Address:ip]) {
        ip = [self getHostByName:ip];
        if (ip == nil) {
            NSLog(@"ERROR:%s:%d, params(%@) is invalid.",__FUNCTION__,__LINE__, oldIp);
            return 0;
        }
        
    }
    
    float rtt = 0.0;
    int s = 0;
    struct sockaddr_in saddr;
    saddr.sin_family = AF_INET;
    saddr.sin_port = htons(80);
    saddr.sin_addr.s_addr = inet_addr([ip UTF8String]);
    //saddr.sin_addr.s_addr = inet_addr("1.1.1.123");
    if( (s=socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        NSLog(@"ERROR:%s:%d, create socket failed.",__FUNCTION__,__LINE__);
        return 0;
    }

    NSDate* startTime = [NSDate date];
    NSDate* endTime;
    //为了设置connect超时 把socket设置称为非阻塞
    int flags = fcntl(s, F_GETFL,0);
    fcntl(s,F_SETFL, flags | O_NONBLOCK);
    int i = connect(s,(struct sockaddr*)&saddr, sizeof(saddr));
    if(i ==0) {
        //建立连接成功，返回rtt时间。 因为connect是非阻塞，所以这个时间就是一个函数执行的时间，毫秒级，没必要再测速了。
        close(s);
        return 1;
    }
    
    struct timeval tv;
    fd_set myset;
    int valopt;
    socklen_t lon;
    tv.tv_sec = WBDNS_SOCKET_CONNECT_TIMEOUT;
    tv.tv_usec = 0;
    FD_ZERO(&myset);
    FD_SET(s, &myset);
    
    int j = select(s+1, NULL, &myset, NULL, &tv);
    if (j > 0) {
        lon = sizeof(int);
        getsockopt(s, SOL_SOCKET, SO_ERROR, (void*)(&valopt), &lon);
        if (valopt) {
            NSLog(@"ERROR:%s:%d, select function error.",__FUNCTION__,__LINE__);
            rtt = 0;
        }
        else {
            endTime = [NSDate date];
            rtt = [endTime timeIntervalSinceDate:startTime] * 1000;
        }
    }
    else if (j == 0) {
        NSLog(@"INFO:%s:%d, test rtt of (%@) timeout.",__FUNCTION__,__LINE__, oldIp);
        rtt = WBDNS_SOCKET_CONNECT_TIMEOUT_RTT;
    }
    else {
        NSLog(@"ERROR:%s:%d, select function error.",__FUNCTION__,__LINE__);
        rtt = 0;
    }
    
    close(s);
    return rtt;
}

@end
