/**
*
* 项目名称: DNSCache <br>
* 类名称: DomainModel <br>
* 类描述: 域名数据模型 - 对应domain表 <br>
* 创建人: fenglei <br>
* 创建时间: 2015-7-23 下午5:04:01 <br>
*
* 修改人:  <br>
* 修改时间:  <br>
* 修改备注: <br>
*
* @version V1.0
*/

import Foundation

class DomainModel{

    /**
    * 自增id <br>
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_ID 字段 <br>
    */
    var id:Long = -1 ;
    
    /**
    * 域名 <br>
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_DOMAIN 字段 <br>
    */
    var domain:String = "" ;
    
    /**
    * 运营商 <br>
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_SP 字段 <br>
    */
    var sp:String = "" ;
    
    /**
    * 域名过期时间 <br>
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_TTL 字段 <br>
    */
    var ttl:String = "0" ;
    
    /**
    * 域名最后查询时间 <br>
    *
    * 该字段映射类 {@link com.sina.util.dnscache.cache.DBConstants } DOMAIN_COLUMN_TIME 字段 <br>
    */
    var time:String = "0" ;

    
    /**
    * 域名关联的ip数组 <br>
    */
    var ipModelArr = IpModel[]()
    
    
    
    func toString()->String{
    
        var str = ""
        str += "域名ID = " + id + "\n"
        str += "域名 = " + domain + "\n"
        str += "运营商ID = " + sp + "\n"
        str += "域名过期时间： = " + ttl + "\n"
        str += "域名最后查询时间：" + Tools.getStringDateShort(time) + "\n"
        
        if( ipModelArr != null && ipModelArr.size() > 0 ){
            
        for temp in ipModelArr {
            if len t = temp
                continue
            str += "-- " + temp.toString()
        }
    
        str += "------------------------------------------------------\n\n"
        
        return str ;
    }

}