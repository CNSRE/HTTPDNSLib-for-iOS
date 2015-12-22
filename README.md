# HTTPDNSLib-for-iOS
DNSCache库使用说明书

目前我们的服务器还不能支持所有的域名，所以代码里有白名单来限制域名。现在还不建议大家用在商用项目里，仅做学习交流用。

1. 导入LibDnsCache.a, WBDNSCache.h. (如果愿意，也可以将DNSCache整个工程导入)

2. 在Targets－》Build Phases－》LinkBinaryWithLibraries 加入libDNSCache.a.  httpDNSLib依赖libsqlite3.dylib, SystemConfiguration.framework, CoreTelephony.framework. 请同时加入以上依赖库。

3. 确定Targets－》BuildingSetting－》SearchPaths－》Library Search Path 可以搜索到正确的库文件。
注意，库分为模拟器版本和真机版本，请确定自己导入的是正确的版本，或者库路径查找 能首先查到正确的版本，有时候能找到两个版本，系统会已第一个找到的版本为准，导致link错误。

4。建议在AppDelegate里（也就是尽可能早的时候）初始化 WBDNSCache库。
设置AppKey和版本，用于请求对应版本的配置参数
以下只是一个示例，如果需要从sina服务器拉取配置，需要申请自己的AppKey，否则请手动修改代码获取自己的配置。
[WBDNSCache setAppkey:@"ed3e6e90975f52876cd9d74a8e9e05d8" version:@"0.1"];
设置配置参数服务器的URL
[WBDNSCache setConfigServerUrl:@"http://api.weibo.cn/2/httpdns/config"];
初始化库，期间会从参数服务器请求配置参数
[[WBDNSCache sharedInstance] initialize];

5.建议初始化后延时调用 预请求域名对应IP，提前从服务器拉取域名对应IP
[[WBDNSCache sharedInstance]preloadDomains:@[@"http://ww4.sinaimg.cn", @"http://api.weibo.cn/"]];

6.然后就可以在任何地方调用
[[WBDNSCache sharedInstance] getDomainServerIpFromURL:url]
获取转换后Url 和 需要设置的host值。
这个函数拿到的是一个WBDNSDomainInfo 对象数组，一般来说 取第一个就可以了。
WBDNSDomainInfo.id 暂时没用。
WBDNSDomainInfo.url 已经替换好的URL， 客户端可以直接用它 请求资源。
WBDNSDomainInfo.host 客户端需要将这个host设置到HTTP的请求头里。 如果Host为@“” 代表不需要设置Host
以AFNetworking举例
[manager.requestSerializer setValue:WBDNSDomainInfo.host forHTTPHeaderField:@"Host"];
