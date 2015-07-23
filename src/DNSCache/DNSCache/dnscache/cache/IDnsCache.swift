/**
*
* 项目名称: DNSCache <br>
* 类名称: IDnsCache <br>
* 类描述: 缓存层对外接口 <br>
* 创建人: fenglei <br>
* 创建时间: 2015-7-23 下午6:12:10 <br>
*
* 修改人:  <br>
* 修改时间:  <br>
* 修改备注:  <br>
*
* @version V1.0
*/

import Foundation


protocol IDnsCache{

    
    /**
    * 获取 domain 缓存
    * @param sp
    * @param domain
    * @return
    */
    func getDnsCache(sp:String , domain:String) -> DomainModel
    
    
    
    /**
    * 插入一条缓存记录
    * @param dnsPack
    * @return
    */
    func insertDnsCache(dnsPack:HttpDnsPack) -> DomainModel
 
    
    
    /**
    * 设置测速后信息
    * @param ipModel
    */
    func setSpeedInfo(ipmodel:ipModel) -> IpModel
    
    
    
    /**
    * 获取即将过期的domain信息
    * @return
    */
    func getExpireDnsCache() -> [DomainModel]
    
    
    
    /**
    * 内存中 增加缓存信息
    * @param url
    * @param model
    */
    func addMemoryCache(url:String, model:DomainModel)
    
    
    
    /**
    * 清除全部缓存数据
    */
    func clear()
    
    
    
    /**
    * 清除内存缓存
    */
    func clearMemoryCache()
    

    
    /**
    * 获取缓存中全部的 DomainModel数据
    * @return
    */
    func getAllMemoryCache() -> [DomainModel]
    
    
    
    /**
    * 获取数据库 domain 表
    */
    func getAllTableDomain() -> [DomainModel]
    
    
    
    /**
    * 获取数据库 ip 表
    */
    func getTableIP() -> [IpModel]
    
 
    
}