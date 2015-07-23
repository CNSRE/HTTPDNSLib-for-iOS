/**
*
* 项目名称: DNSCache
* 类名称: HttpDnsPack
* 类描述: 将httpdns返回的数据封装一层，方便日后httpdns接口改动不影响数据库模型。 并且该接口还会标识httpdns错误之后的一些信息用来上报
* 创建人: fenglei
* 创建时间: 2015-3-30 上午11:20:11
*
* 修改人:
* 修改时间:
* 修改备注:
*
* @version V1.0
*/

import Foundation

class HttpDnsPack{

    /**
    * httpdns 接口返回字段 域名信息
    */
    var domain:String = ""
    
    /**
    * httpdns 接口返回字段 请求的设备ip（也可能是sp的出口ip）
    */
    var device_ip:String = ""
    
    /**
    * httpdns 接口返回字段 请求的设备sp运营商
    */
    var device_sp:String = ""
    
    /**
    * httpdns 接口返回的a记录。（目前不包含cname别名信息）
    */
    var dns = IP[]()
    
    /**
    * 本机识别的sp运营商，手机卡下运营商正常，wifi下为ssid名字
    */
    var localhostSp:String = ""

    
    /**
    * 打印该类相关变量信息
    */
    func toString()->String{
    
        var str = "HttpDnsPack class \n"
        str += "domain:" + domain + "\n"
        str += "device_ip:" + device_ip + "\n"
        str += "device_sp:" + device_sp + "\n"
        
//        if( dns != null ){
//            str += "-------------------\n"
//            for i {
//                str += "dns[" + i + "]:" + dns[i] + "\n"
//            }
//            str += "-------------------\n"
//        }
        
        return str
    
    
    }
    
    /**
    * A记录相关字段信息
    */
    class IP{
    
        /**
        * A记录IP
        */
        var ip:String = ""
        
        /**
        * 域名A记录过期时间
        */
        var ttl:String = ""
        
        /**
        * 服务器推荐使用的A记录 级别从0-10
        */
        var priority:String = ""
        
        /**
        * 该服务器速度
        */
        var speed:Float = 0.0
        
        /**
        * 打印该类信息
        */
        func toString() -> String{
            var str = "IP class \n"
            str += "ip:" + ip + "\n"
            str += "ttl:" + ttl + "\n"
            str += "priority:" + priority + "\n"
            return str ;
        }
        
    }
    
}
