//
//  DBManager.m
//  DNSCache
//
//  Created by Robert Yang on 15/7/28.
//  Copyright (c) 2015年 Weibo. All rights reserved.
//

#import "WBDNSDBManager.h"
#import "WBDNSTools.h"
#import "WBDNSConfig.h"
#import "WBDNSConfigManager.h"

#define WB_DNSCache_DB_Version 1
#define WB_DNSCache_DB_NAME @"dns_ip_info.db"

/**
 *  创建db_info table的Sql语句
 */
static NSString *WBDNS_CREATE_DB_INFO_TABLE_SQL= @"create table if not exists db_info (c_key text primary key ,c_value text)";


/**
 * domain表名称、列名定义
 */
static NSString *WBDNS_TABLE_NAME_DOMAIN = @"domain";
/**
 * domain 自增id
 */
static NSString *WBDNS_DOMAIN_COLUMN_ID = @"id";
/**
 * 域名
 */
static NSString *WBDNS_DOMAIN_COLUMN_DOMAIN = @"domain";
/**
 * 运营商
 */
static NSString *WBDNS_DOMAIN_COLUMN_SP = @"sp";
/**
 * 域名过期时间
 */
static NSString *WBDNS_DOMAIN_COLUMN_TTL = @"ttl";
/**
 * 最后查询时间
 */
static NSString *WBDNS_DOMAIN_COLUMN_TIME = @"time";

/**
 *  创建domain table的Sql语句
 */
static NSString *WBDNS_CREATE_DOMAIN_TABLE_SQL= @"create table if not exists domain (id INTEGER PRIMARY KEY, domain TEXT, sp TEXT, ttl TEXT, time TEXT)";

/**
 * ip表名称、列名定义
 */
static NSString *WBDNS_TABLE_NAME_IP = @"ip";
/**
 * ip 自增id
 */
static NSString *WBDNS_IP_COLUMN_ID = @"id";
/**
 * domain 关联id
 */
static NSString *WBDNS_IP_COLUMN_DOMAIN_ID = @"d_id";
/**
 * 服务器 ip地址
 */
static NSString *WBDNS_IP_COLUMN_IP = @"ip";
/**
 * ip服务器对应的端口
 */
static NSString *WBDNS_IP_COLUMN_PORT = @"port";
/**
 * ip服务器对应的sp运营商
 */
static NSString *WBDNS_IP_COLUMN_SP = @"sp";
/**
 * ip服务器对应域名过期时间
 */
static NSString *WBDNS_IP_COLUMN_TTL = @"ttl";
/**
 * ip服务器优先级-排序算法策略使用
 */
static NSString *WBDNS_IP_COLUMN_PRIORITY = @"priority";
/**
 *  ip服务器访问延时时间(可用ping或http发送空包实现)。单位ms
 */
static NSString *WBDNS_IP_COLUMN_RTT = @"rtt";
/**
 * 最后测速下行速度值
 */
static NSString *WBDNS_IP_COLUMN_FINALLY_SPEED = @"finally_speed";
/**
 * ip服务器链接产生的成功数
 */
static NSString *WBDNS_IP_COLUMN_SUCCESS_NUM = @"success_num";
/**
 * ip服务器链接产生的错误数
 */
static NSString *WBDNS_IP_COLUMN_ERR_NUM = @"err_num";
/**
 * ip服务器最后成功链接时间
 */
static NSString *WBDNS_IP_COLUMN_FINALLY_SUCCESS_TIME = @"finally_success_time";

/**
 * ip服务器最后失败链接时间
 */
static NSString *WBDNS_IP_COLUMN_FINALLY_FAIL_TIME = @"finally_fail_time";

/**
 *  此IP记录从服务器的更新时间
 */
static NSString *WBDNS_IP_COLUMN_FINALLY_UPDATE_TIME = @"finally_update_time";
/**
 *  创建ip table的Sql语句
 */
static NSString *WBDNS_CREATE_IP_TABLE_SQL= @"create table if not exists ip (id INTEGER PRIMARY KEY, d_id INTEGER, ip TEXT, port INTEGER, sp TEXT, ttl TEXT, priority TEXT, rtt TEXT, success_num TEXT, err_num TEXT, finally_success_time TEXT, finally_fail_time TEXT, finally_update_time TEXT)";

@implementation WBDNSDBManager
{
    sqlite3* db;
}

- (id)init {
    if(self = [super init]) {
        //检查是否存在数据库文件
        if (![self isExistDB]) {
            //不存在，则创建
            [self createDB];
            [self updateDB:0];
        }else {
            //若存在，检测数据库版本，则进行升级，
            char* info=NULL;
            [self getDBInfoValueWithKey:"db_version" value:&info];
            if(info == NULL) {
                NSLog(@"ERROR: DB is invalid, no db_version found.");
                return self;
            }
            int existDBVersion= atoi(info);
            free (info);
            
            [self updateDB:existDBVersion];
        }
    }
    return self;
}

- (void)updateDB:(int)currentDBVersion
{
    @synchronized(self) {
        //升级数据库。若第一次创建，则从0开始升级。顺序升级，因此不可以有break
        switch (currentDBVersion) {
            case 0:
                //第一次，新建并初始化各表
                [self createTable:WBDNS_CREATE_DB_INFO_TABLE_SQL];
                [self setDBInfoValueWithKey:"db_version" value:"1"];
                [self createTable:WBDNS_CREATE_DOMAIN_TABLE_SQL];
                [self createTable:WBDNS_CREATE_IP_TABLE_SQL];
            default:
                break;
        }
    }
}

- (BOOL)createDB {
    @synchronized(self) {
        int ret = sqlite3_open([[self getFilePath] UTF8String], &db);//打开数据库，数据库不存在则创建
        if (SQLITE_OK == ret) {//创建成功
            sqlite3_close(db);//关闭
            return YES;
        } else {
            NSLog(@"ERROR:%s:%d failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
            return NO;//创建失败
        }
    }
}

- (NSString *)getFilePath {
    NSArray *documentsPaths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask  , YES);
    NSString *databaseFilePath=[[documentsPaths objectAtIndex:0] stringByAppendingPathComponent:WB_DNSCache_DB_NAME];
    return databaseFilePath ;
}

- (BOOL)isExistDB {
    NSFileManager* fm = [[NSFileManager alloc] init];
    return [fm fileExistsAtPath:[self getFilePath]];
}

- (BOOL)createTable:(NSString *)creteSql {
    return [self execSql:creteSql hasDbOpen:NO];
}


- (BOOL)execSql:(NSString *)createSql hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        BOOL ret = YES;
        char* err;
        const char* sql = [createSql UTF8String];//创建表语句
        if (sql==NULL) {
            NSLog(@"ERROR:%s:%d createSql is nil.",__FUNCTION__,__LINE__);
            return NO;
        }
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)){
                NSLog(@"ERROR:%s:%d DB open failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
                return NO;
            }
        }
        
        if (SQLITE_OK == sqlite3_exec(db, sql, NULL, NULL, &err)) {//执行创建表语句成功ß
            ret = YES;
        } else {
            //创建表失败
            NSLog(@"ERROR:%s:%d sql execute failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
            ret = NO;
        }
        
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        return  ret;
    }
}

- (void)clear {
    @synchronized(self) {
        if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {//打开数据库
            NSLog(@"ERROR:%s:%d db open failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
            return;
        }
        
        NSString* sql = [NSString stringWithFormat:@"delete from %@", WBDNS_TABLE_NAME_DOMAIN];
        sqlite3_stmt* stmt;//
        int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
        if (result==SQLITE_OK) {
            if (SQLITE_DONE != sqlite3_step(stmt)) {
                NSLog(@"ERROR:%s:%d sql execute failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
            }
            
            sqlite3_finalize(stmt);
        } else {
            NSLog(@"ERROR:%s:%d sql prepared failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
        }
        
        sql = [NSString stringWithFormat:@"delete from %@", WBDNS_TABLE_NAME_IP];
        result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
        if (result==SQLITE_OK) {
            if (SQLITE_DONE != sqlite3_step(stmt)) {
                NSLog(@"ERROR:%s:%d sql execute failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
            }
            
            sqlite3_finalize(stmt);
        } else {
            NSLog(@"ERROR:%s:%d sql prepared failed reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
        }
        
        sqlite3_close(db);
    }
}

#pragma mark-  table db_info manage
- (void)getDBInfoValueWithKey:(const char *)key value:(char **)value {
    @synchronized(self) {
        if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String] , &db)) {
            NSLog(@"%s:%d db open error..reason:%s.",__FUNCTION__,__LINE__,sqlite3_errmsg(db));
            return ;
        }
        const char* sql = "select * from db_info where c_key =?";//查询语句
        sqlite3_stmt* stmt;
        
        int error = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
        if (error==SQLITE_OK) {//准备
            sqlite3_bind_text(stmt, 1,key, -1, NULL);
        } else {
            NSLog(@"ERROR%s:%d query error.. %d reason:%s\n",__FUNCTION__,__LINE__,error, sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return;
        }
        
        if( SQLITE_ROW == sqlite3_step(stmt) ) {//执行
            char* v= (char*)sqlite3_column_text(stmt, 1);
            *value = strdup(v);
        }
        sqlite3_finalize(stmt);
        sqlite3_close(db);
    }
}

- (BOOL)setDBInfoValueWithKey:(const char*)key value:(const char*)value {
    
    @synchronized(self) {
        char* info=NULL;
        [self getDBInfoValueWithKey:key value:&info];
        if (info!= NULL) {
            //存在，则更新
            [self updateDBInfoValueWithKey:key value:value];
        }else {
            //不存在，插入
            [self insertDBInfoValueWithKey:key value:value];
        }
        free(info);
        return YES;
    }
}

- (BOOL)insertDBInfoValueWithKey:(const char*)key value:(const char*)value {
    @synchronized(self) {
        int ret = 0;
        if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {
            return NO;
        }
        const char* sql = "insert into db_info(c_key,c_value) values(?,?);";
        sqlite3_stmt* stmt;//
        int result =sqlite3_prepare_v2(db, sql, -1, &stmt, nil);
        
        if (result==SQLITE_OK) {//准备语句
            sqlite3_bind_text(stmt, 1, key, -1, NULL);//绑定参数
            sqlite3_bind_text(stmt, 2, value, -1, NULL);
        } else {
            NSLog(@"ERROR:%s\n",sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return NO;
        }
        if (SQLITE_DONE == (ret = sqlite3_step(stmt))) {//执行查询
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return YES;
        } else {
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return NO;
        }
    }
}


- (BOOL)updateDBInfoValueWithKey:(const char*)key value:(const char*)value {
    @synchronized(self) {
        int ret = 0;
        if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {
            NSLog(@"ERROR%s:%d query db open error. reason:%s\n",__FUNCTION__,__LINE__, sqlite3_errmsg(db));
            return NO;
        }
        const char* sql = "update db_info set c_value = ? where c_key = ?;";
        sqlite3_stmt* stmt;//
        int result =sqlite3_prepare_v2(db, sql, -1, &stmt, nil);
        if (result==SQLITE_OK) {//准备语句
            sqlite3_bind_text(stmt, 1, value, -1, NULL);
            sqlite3_bind_text(stmt, 2, key, -1, NULL);
        } else {
            NSLog(@"ERROR:%s\n",sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return NO;
        }
        ret = sqlite3_step(stmt);
        if (SQLITE_DONE ==ret ) {//执行查询
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return YES;
        } else {
            NSLog(@"ERROR:%s\n",sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            return NO;
        }
    }
}

#pragma mark- Domain db manage



- (WBDNSDomainModel *)queryDomainInfo:(NSString *)domain sp:(NSString *)sp withIpArray:(BOOL)withIPArray containsExpiredIp:(BOOL)containsExpiredIp hasDbOpen:(BOOL)hasDbOpen {
    if (domain == nil) {
        NSLog(@"ERROR %s:%d domain is nil.", __func__,__LINE__);
    }
    
    if (sp == nil) {
        NSLog(@"ERROR %s:%d sp is nil.", __func__,__LINE__);
    }
    @synchronized(self) {
        NSMutableArray* result = [[NSMutableArray alloc]init];
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {
                NSLog(@"ERROR%s:%d db open error. reason:%s\n",__FUNCTION__,__LINE__, sqlite3_errmsg(db));
                return nil;
            }
        }
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ?;", WBDNS_TABLE_NAME_DOMAIN, WBDNS_DOMAIN_COLUMN_DOMAIN, WBDNS_DOMAIN_COLUMN_SP];
        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(db, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &stmt, nil) ==SQLITE_OK) {//准备
            sqlite3_bind_text(stmt, 1,[domain UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 2,[sp UTF8String], -1, NULL);
        } else {
            NSLog(@"ERROR%s:%d statments prepared fail. reason:%s\n",__FUNCTION__,__LINE__, sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return nil;
        }
        
        while (SQLITE_ROW == sqlite3_step(stmt)) {
            WBDNSDomainModel* model = [[WBDNSDomainModel alloc]init];
            model.id = sqlite3_column_int(stmt, 0);
            if (sqlite3_column_text(stmt, 1) != NULL) {
                model.domain = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 1)];
            }
            if (sqlite3_column_text(stmt, 2) != NULL) {
                model.sp = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 2)];
            }
            if (sqlite3_column_text(stmt, 3) != NULL) {
                model.ttl = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 3)];
            }
            if (sqlite3_column_text(stmt, 4) != NULL) {
                model.time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 4)];
            }
            
            if (withIPArray) {
                model.ipModelArray = [self queryIpModelArray:model containsExpiredIp:containsExpiredIp  hasDbOpen:YES];
            }
            
            [result addObject:model];
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        
        if (result.count > 1) {
            NSLog(@"ERROR%s:%d more than one domain Model in database.\n",__FUNCTION__,__LINE__);
        }
        
        return  [result firstObject];
    }
}


- (NSArray *)queryAllDomainInfoWithIpArray:(BOOL)withIPArray containsExpiredIp:(BOOL)containsExpiredIp hasDbOpen:(BOOL)hasDbOpen {
   
    @synchronized(self) {
        NSMutableArray* result = [[NSMutableArray alloc]init];
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {
                NSLog(@"ERROR%s:%d db open error. reason:%s\n",__FUNCTION__,__LINE__, sqlite3_errmsg(db));
                return nil;
            }
        }
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", WBDNS_TABLE_NAME_DOMAIN];
        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(db, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &stmt, nil) ==SQLITE_OK) {//准备
           
        } else {
            NSLog(@"ERROR%s:%d statments prepared fail. reason:%s\n",__FUNCTION__,__LINE__, sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return nil;
        }
        
        while (SQLITE_ROW == sqlite3_step(stmt)) {
            WBDNSDomainModel* model = [[WBDNSDomainModel alloc]init];
            model.id = sqlite3_column_int(stmt, 0);
            if (sqlite3_column_text(stmt, 1) != NULL) {
                model.domain = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 1)];
            }
            if (sqlite3_column_text(stmt, 2) != NULL) {
                model.sp = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 2)];
            }
            if (sqlite3_column_text(stmt, 3) != NULL) {
                model.ttl = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 3)];
            }
            if (sqlite3_column_text(stmt, 4) != NULL) {
                model.time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 4)];
            }
            
            if (withIPArray) {
                model.ipModelArray = [self queryIpModelArray:model containsExpiredIp:containsExpiredIp  hasDbOpen:YES];
            }
            
            [result addObject:model];
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        
        return result;
    }
}

- (WBDNSDomainModel *)queryDomainInfoWithIPArray:(NSString *)domain sp:(NSString *)sp containsExpiredIp:(BOOL)containsExpiredIp hasDbOpen:(BOOL)hasDbOpen {
    return [self queryDomainInfo:domain sp:sp withIpArray:YES containsExpiredIp:containsExpiredIp hasDbOpen:hasDbOpen];
}

- (WBDNSDomainModel *)queryDomainInfoWithoutIPArray:(NSString *)domain sp:(NSString *)sp hasDbOpen:(BOOL)hasDbOpen {
    return [self queryDomainInfo:domain sp:sp withIpArray:NO containsExpiredIp:NO hasDbOpen:hasDbOpen];
}

- (void)deleteDomainInfo:(WBDNSDomainModel *)model  hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                return;
            }
        }
        
        
        NSString* sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", WBDNS_TABLE_NAME_DOMAIN, WBDNS_DOMAIN_COLUMN_ID];
        sqlite3_stmt* stmt;//
        int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
        
        if (result==SQLITE_OK) {//准备语句
            sqlite3_bind_int(stmt, 1, model.id);
        } else {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            sqlite3_finalize(stmt);
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return;
        }
        if (SQLITE_DONE != sqlite3_step(stmt)) {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
    }
}

- (void)deleteDomainInfoArray:(NSArray *)domainInfoArr hasDbOpen:(BOOL) hasDbOpen {
    @synchronized(self) {
        for (WBDNSDomainModel* model in domainInfoArr) {
            if ([model isKindOfClass:[WBDNSDomainModel class]]) {
                [self deleteDomainInfo:model hasDbOpen:hasDbOpen];
            }
            else {
                NSLog(@"deleteDomainInfoArray: invaild model.\n");
            }
        }
    }
}

- (WBDNSDomainModel *)updateDomainModel:(WBDNSDomainModel *)model byDomain:(NSString *)domain sp:(NSString *)sp hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {
                NSLog(@"ERROR %s:%d Open database fail\n", __func__,__LINE__);
                return nil;
            }
        }
        
        WBDNSDomainModel* existModel = [self queryDomainInfoWithoutIPArray:domain sp:sp hasDbOpen:YES];
        sqlite3_stmt* stmt;
        if (existModel != nil) {
            NSString* sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? , %@ = ?, %@ = ?, %@ =? where %@ = ? AND %@ = ?",WBDNS_TABLE_NAME_DOMAIN, WBDNS_DOMAIN_COLUMN_DOMAIN, WBDNS_DOMAIN_COLUMN_SP,  WBDNS_DOMAIN_COLUMN_TTL, WBDNS_DOMAIN_COLUMN_TIME,WBDNS_DOMAIN_COLUMN_DOMAIN, WBDNS_DOMAIN_COLUMN_SP];
            sqlite3_stmt* stmt;//
            int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
            if (result==SQLITE_OK) {//准备语句
                sqlite3_bind_text(stmt, 1, [model.domain UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 2, [model.sp UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 3, [model.ttl UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 4, [model.time UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 5, [model.domain UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 6, [model.sp UTF8String], -1, NULL);
            } else {
                if (!hasDbOpen) {
                    sqlite3_close(db);
                }
                NSLog(@"ERROR %s:%d reason %s", __func__,__LINE__, sqlite3_errmsg(db));
                return nil;
            }
            if (SQLITE_DONE != sqlite3_step(stmt)) {//执行查询
                NSLog(@"ERROR %s:%d reason %s", __func__,__LINE__, sqlite3_errmsg(db));
                sqlite3_finalize(stmt);
                if (!hasDbOpen) {
                    sqlite3_close(db);
                }
            }
            
            sqlite3_finalize(stmt);
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
        } else {
            
            NSString* sql = [NSString stringWithFormat:@"insert into %@ (%@,%@,%@,%@) values (?, ?, ?, ?)", WBDNS_TABLE_NAME_DOMAIN, WBDNS_DOMAIN_COLUMN_DOMAIN, WBDNS_DOMAIN_COLUMN_SP, WBDNS_DOMAIN_COLUMN_TTL, WBDNS_DOMAIN_COLUMN_TIME];
            
            int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
            if (result==SQLITE_OK) {//准备语句
                sqlite3_bind_text(stmt, 1, [model.domain UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 2, [model.sp UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 3, [model.ttl UTF8String], -1, NULL);
                sqlite3_bind_text(stmt, 4, [model.time UTF8String], -1, NULL);
            } else {
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                if (!hasDbOpen) {
                    sqlite3_close(db);
                }
                return nil;
            }
            
            if (SQLITE_DONE != sqlite3_step(stmt)) {//执行查询
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                sqlite3_finalize(stmt);
                if (!hasDbOpen) {
                    sqlite3_close(db);
                }
                return nil;
            }
            
            sqlite3_finalize(stmt);
        }
        
        WBDNSDomainModel* newModel = [self queryDomainInfoWithoutIPArray:domain sp:sp hasDbOpen:YES];;
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        return newModel;
    }
}

- (WBDNSDomainModel *)updateDomainModelWithIpArray:(WBDNSDomainModel *)model {
    @synchronized(self) {
        if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {//打开数据库
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            return nil;
        }
        
        WBDNSDomainModel* newModel = [self updateDomainModel:model byDomain:model.domain sp:model.sp
                                                   hasDbOpen:YES];
        //是否需要把旧的IP 置为过期。这个函数只会返回server下发的ip，即使不把老的IP置为过期，也会在几秒钟后过期。
        //数据库里服务器以前下发的IP 只会在缓存没数据时读取，基本上都是程序启动时，一般情况下 都已经过期。
        NSMutableArray* tempIpArray = [[NSMutableArray alloc]init];
        for (int i = 0; i < model.ipModelArray.count; i++) {
            WBDNSIpModel* tempIp = model.ipModelArray[i];
            tempIp.d_id = newModel.id;
            WBDNSIpModel* ipModel = [self queryIpModel:tempIp.ip sp:model.sp domainId:newModel.id hasDbOpen:YES];
            if (ipModel == nil) {
                BOOL result = [self insertIpModel:tempIp hasDbOpen:YES];
                if (result == NO) {
                     NSLog(@"WARNING:%s:%d insert tempIp failed.", __func__,__LINE__);
                }
            } else {
                ipModel.d_id = tempIp.d_id;
                ipModel.port = tempIp.port;
                ipModel.sp = tempIp.sp;
                ipModel.ttl = tempIp.ttl;
                ipModel.priority = tempIp.priority;
                //重新请求ip 不更新rtt， 成功次数，失败此处，成功时间，和失败时间
                //ipModel.rtt = [[tempIp rtt] intValue] == 0 ? ipModel.rtt : tempIp.rtt;
                //ipModel.success_num = [NSString stringWithFormat:@"%i",[[tempIp success_num] intValue] + [[ipModel success_num]intValue]] ;
                //ipModel.err_num = [NSString stringWithFormat:@"%i",[[tempIp err_num] intValue] + [[ipModel err_num]intValue]] ;
                
                //ipModel.finally_success_time = tempIp.finally_success_time;
                //ipModel.finally_fail_time = tempIp.finally_fail_time;
                ipModel.finally_update_time = tempIp.finally_update_time;
                [self updateIpModel:ipModel hasDbOpen:YES];
            }
            
            if (ipModel == nil) {
                ipModel = tempIp;
            }
            [tempIpArray addObject:ipModel];
        }
        model.ipModelArray = tempIpArray;
        model.id = newModel.id;
        sqlite3_close(db);
        return model;
    }
}

#pragma mark- ip db manage

- (NSMutableArray *)queryIpModelArray:(WBDNSDomainModel *)domain containsExpiredIp:(BOOL)containsExpiredIp hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        if (domain.sp == nil) {
            NSLog(@"ERROR %s:%d domain.sp is nil.", __func__,__LINE__);
        }
        
        if (domain.id <= 0) {
            NSLog(@"ERROR %s:%d domain.id(%d) is invaild.", __func__,__LINE__, domain.id);
        }
        
        NSMutableArray* result = [[NSMutableArray alloc]init];
        
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)){
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                return nil;
            }
        }
        
        
        NSString* sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ?;", WBDNS_TABLE_NAME_IP, WBDNS_IP_COLUMN_DOMAIN_ID, WBDNS_IP_COLUMN_SP];
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &stmt, nil) ==SQLITE_OK) {//准备
            sqlite3_bind_int(stmt, 1, domain.id);
            sqlite3_bind_text(stmt, 2, [domain.sp UTF8String], -1, NULL);
        } else {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return nil;
        }
        
        while (SQLITE_ROW == sqlite3_step(stmt)) {
            WBDNSIpModel* model = [[WBDNSIpModel alloc]init];
            model.id = sqlite3_column_int(stmt, 0);
            model.d_id = sqlite3_column_int(stmt, 1);
            if (sqlite3_column_text(stmt, 2) != NULL) {
                model.ip = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 2)];
            }
            model.port = sqlite3_column_int(stmt, 3);
            if (sqlite3_column_text(stmt, 4) != NULL) {
                model.sp = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 4)];
            }
            if (sqlite3_column_text(stmt, 5) != NULL) {
                model.ttl = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 5)];
            }
            if (sqlite3_column_text(stmt, 6) != NULL) {
                model.priority = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 6)];
            }
            if (sqlite3_column_text(stmt, 7) != NULL) {
                model.rtt = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 7)];
            }
            if (sqlite3_column_text(stmt, 8) != NULL) {
                model.success_num = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 8)];
            }
            if (sqlite3_column_text(stmt, 9) != NULL) {
                model.err_num = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 9)];
            }
            if (sqlite3_column_text(stmt, 10) != NULL) {
                model.finally_success_time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 10)];
            }
            if (sqlite3_column_text(stmt, 11) != NULL) {
                model.finally_fail_time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 11)];
            }
            if (sqlite3_column_text(stmt, 12) != NULL) {
                model.finally_update_time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 12)];
            }
            
            if (containsExpiredIp) {
                [result addObject:model];
            } else {
                if (![WBDNSTools isIpRecordExpired:model expireDuration:[WBDNSConfigManager sharedInstance].config.refreshDomainIpInterval + 15]) {
                    [result addObject:model];
                }
            }
            
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        return  result;
    }
}

- (WBDNSIpModel *)queryIpModel:(NSString *)severIp sp:(NSString *)sp domainId:(int)d_id hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        NSMutableArray* result = [[NSMutableArray alloc]init];
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)){
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                return nil;
            }
        }
        
        NSString* sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ? AND %@ = ?;", WBDNS_TABLE_NAME_IP,WBDNS_IP_COLUMN_DOMAIN_ID, WBDNS_IP_COLUMN_IP, WBDNS_IP_COLUMN_SP];
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &stmt, nil) ==SQLITE_OK) {//准备
            sqlite3_bind_int(stmt, 1, d_id);
            sqlite3_bind_text(stmt, 2,[severIp UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 3,[sp UTF8String], -1, NULL);
        } else {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return nil;
        }
        
        while (SQLITE_ROW == sqlite3_step(stmt)) {
            WBDNSIpModel* model = [[WBDNSIpModel alloc]init];
            model.id = sqlite3_column_int(stmt, 0);
            model.d_id = sqlite3_column_int(stmt, 1);
            if (sqlite3_column_text(stmt, 2) != NULL) {
                model.ip = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 2)];
            }
            model.port = sqlite3_column_int(stmt, 3);
            if (sqlite3_column_text(stmt, 4) != NULL) {
                model.sp = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 4)];
            }
            if (sqlite3_column_text(stmt, 5) != NULL) {
                model.ttl = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 5)];
            }
            if (sqlite3_column_text(stmt, 6) != NULL) {
                model.priority = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 6)];
            }
            if (sqlite3_column_text(stmt, 7) != NULL) {
                model.rtt = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 7)];
            }
            if (sqlite3_column_text(stmt, 8) != NULL) {
                model.success_num = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 8)];
            }
            if (sqlite3_column_text(stmt, 9) != NULL) {
                model.err_num = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 9)];
            }
            if (sqlite3_column_text(stmt, 10) != NULL) {
                model.finally_success_time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 10)];
            }
            if (sqlite3_column_text(stmt, 11) != NULL) {
                model.finally_fail_time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 11)];
            }
            if (sqlite3_column_text(stmt, 12) != NULL) {
                model.finally_update_time = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 12)];
            }
            [result addObject:model];
        }
        sqlite3_finalize(stmt);
        
        if (result.count >= 1) {
            for (int i = 1; i< result.count; i++) {
                NSLog(@"ERROR:%s:%d more than one ip record for this ip(%@) sp (%@)and domain id(%d)",__func__,__LINE__, severIp,sp, d_id);
                [self deleteIpModel:result[i] hasDbOpen:YES];
            }
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return  result[0];
        } else {
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return nil;
        }
    }
}

- (BOOL)deleteIpModel:(WBDNSIpModel *)model hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        int ret = YES;
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {//打开数据库
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                return NO;
            }
        }
        
        NSString* sql = [NSString stringWithFormat:@"delete from %@ where %@ = ?", WBDNS_TABLE_NAME_IP, WBDNS_IP_COLUMN_ID];
        sqlite3_stmt* stmt;//
        int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
        if (result==SQLITE_OK) {//准备语句
            sqlite3_bind_int(stmt, 1, model.id);
        } else {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return NO;
        }
        if (SQLITE_DONE != sqlite3_step(stmt)) {//执行查询
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            ret =  NO;
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        return  ret;
    }
}

- (BOOL)updateIpModel:(WBDNSIpModel *) model hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        BOOL ret = YES;
        if (model == nil) {
            NSLog(@"ERROR %s:model is nil", __func__);
            return NO;
        }
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)) {//打开数据库
                NSLog(@"ERROR %s:%s", __func__, sqlite3_errmsg(db));
                return NO;
            }
        }
        NSString* sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? , %@ = ?, %@ = ?,%@ = ?,%@ = ?,%@ = ?,%@ = ?,%@ = ?, %@ =?, %@ =?, %@ =?, %@ =? where %@ = ?",WBDNS_TABLE_NAME_IP, WBDNS_IP_COLUMN_DOMAIN_ID, WBDNS_IP_COLUMN_IP, WBDNS_IP_COLUMN_PORT, WBDNS_IP_COLUMN_SP, WBDNS_IP_COLUMN_TTL, WBDNS_IP_COLUMN_PRIORITY, WBDNS_IP_COLUMN_RTT, WBDNS_IP_COLUMN_SUCCESS_NUM, WBDNS_IP_COLUMN_ERR_NUM, WBDNS_IP_COLUMN_FINALLY_SUCCESS_TIME,WBDNS_IP_COLUMN_FINALLY_FAIL_TIME, WBDNS_IP_COLUMN_FINALLY_UPDATE_TIME, WBDNS_IP_COLUMN_ID];
        sqlite3_stmt* stmt;//
        int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
        if (result==SQLITE_OK) {//准备语句
            sqlite3_bind_int(stmt, 1, model.d_id);
            sqlite3_bind_text(stmt, 2, [model.ip UTF8String], -1, NULL);
            sqlite3_bind_int(stmt, 3, model.port);
            sqlite3_bind_text(stmt, 4, [model.sp UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 5, [model.priority UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 6, [model.ttl UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 7, [model.rtt UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 8, [model.success_num UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 9, [model.err_num UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 10, [model.finally_success_time UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 11, [model.finally_fail_time UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 12, [model.finally_update_time UTF8String], -1, NULL);
            sqlite3_bind_int(stmt, 13, model.id);
        } else {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return NO;
        }
        if (SQLITE_DONE != sqlite3_step(stmt)) {//执行查询
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            ret = NO;
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        return ret;
    }
}

- (BOOL)insertIpModel:(WBDNSIpModel *) ipModel hasDbOpen:(BOOL)hasDbOpen {
    @synchronized(self) {
        BOOL ret = YES;
        
        if (ipModel == nil) {
            NSLog(@"ERROR %s:%d model is nil", __func__, __LINE__);
            return NO;
        }
        if (!hasDbOpen) {
            if (SQLITE_OK != sqlite3_open([[self getFilePath] UTF8String], &db)){//打开数据库
                NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
                return NO;
            }
        }
        NSString* sql = [NSString stringWithFormat:@"insert into %@(%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", WBDNS_TABLE_NAME_IP, WBDNS_IP_COLUMN_DOMAIN_ID, WBDNS_IP_COLUMN_IP, WBDNS_IP_COLUMN_PORT, WBDNS_IP_COLUMN_SP, WBDNS_IP_COLUMN_TTL, WBDNS_IP_COLUMN_PRIORITY, WBDNS_IP_COLUMN_RTT, WBDNS_IP_COLUMN_SUCCESS_NUM, WBDNS_IP_COLUMN_ERR_NUM, WBDNS_IP_COLUMN_FINALLY_SUCCESS_TIME, WBDNS_IP_COLUMN_FINALLY_FAIL_TIME, WBDNS_IP_COLUMN_FINALLY_UPDATE_TIME];
        sqlite3_stmt* stmt;
        int result =sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
        if (result==SQLITE_OK) {//准备语句
            sqlite3_bind_int(stmt, 1, ipModel.d_id);
            sqlite3_bind_text(stmt, 2, [ipModel.ip UTF8String], -1, NULL);
            sqlite3_bind_int(stmt, 3, ipModel.port);
            sqlite3_bind_text(stmt, 4, [ipModel.sp UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 5, [ipModel.ttl UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 6, [ipModel.priority UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 7, [ipModel.rtt UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 8, [ipModel.success_num UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 9, [ipModel.err_num UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 10, [ipModel.finally_success_time UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 11, [ipModel.finally_fail_time UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 12, [ipModel.finally_update_time UTF8String], -1, NULL);
            
        } else {
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));
            if (!hasDbOpen) {
                sqlite3_close(db);
            }
            return NO;
        }
        
        if (SQLITE_DONE != sqlite3_step(stmt)) {//执行查询
            NSLog(@"ERROR %s:%d reason:%s", __func__,__LINE__, sqlite3_errmsg(db));;
            ret = NO;
        }
        sqlite3_finalize(stmt);
        if (!hasDbOpen) {
            sqlite3_close(db);
        }
        return ret;
    }

}

@end
