/**
*
* 项目名称: DNSCache <br>
* 类名称: IpModel <br>
* 类描述: ip数据模型 - 对应ip表 <br>
* 创建人: fenglei <br>
* 创建时间: 2015-7-21 下午5:23:06 <br>
*
* 修改人:  <br>
* 修改时间:  <br>
* 修改备注:  <br>
*
* @version V1.0
*/

import Foundation


class IpModel {


    /**
    * 自增id <br>
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_ID 字段 <br>
    */
    var id:Long = -1
    
    /**
    * domain id 关联id
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_DOMAIN_ID 字段 <br>
    */
    var d_id:Long = -1
    
    /**
    * 服务器ip地址
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_PORT 字段 <br>
    */
    var ip:String = ""
    
    /**
    * ip服务器对应的端口
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_PORT 字段 <br>
    */
    var port:Int = -1
    
    /**
    * ip服务器对应的sp运营商
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_SP 字段 <br>
    */
    var sp:String = ""

    
    /**
    * ip过期时间
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_TTL 字段 <br>
    */
    var ttl:String = ""
    
    /**
    * ip服务器优先级-排序算法策略使用
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_PRIORITY 字段 <br>
    */
    var priority:String = ""

    
    /**
    * 最后测速下行速度值
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_FINALLY_SPEED 字段 <br>
    */
    var finally_speed:String = ""
    
    /**
    * ip服务器链接产生的成功数
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_SUCCESS_NUM 字段 <br>
    */
    var success_num:String = ""
    
    /**
    * ip服务器链接产生的错误数
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_ERR_NUM 字段 <br>
    */
    var err_num:String = ""
    
    /**
    * ip服务器最后成功链接时间
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } IP_COLUMN_FINALLY_SUCCESS_TIME 字段 <br>
    */
    var finally_success_time:String = ""
    
    
    
    /**
    * 评估体系 评分分值
    */
    var grade:Float = -1

    
    
    func toString()->String{
        var str = "*\n"
        str += "-- 服务器id = " + id + "\n"
        str += "-- 服务器ip = " + ip + "\n"
        str += "-- 域名ID索引 = " + d_id + "\n"
        str += "-- 服务器端口 = " + port + "\n"
        str += "-- 运营商 = " + sp + "\n"
        str += "-- 过期时间 = " + ttl + "\n"
        str += "-- 优先级 = " + priority + "\n"
        str += "-- 最后速度分值 = " + finally_speed + "\n"
        str += "-- 历史成功次数 = " + success_num + "\n"
        str += "-- 历史错误次数 = " + err_num + "\n"
        str += "-- 最后一次访问成功时间 = " + Tools.getStringDateShort(finally_success_time) + "\n"
        str += "-- 系统对服务器的评分 = " + grade + "\n"
        str += "\n"
        return str
    }


}