# SWEB
**个人使用**的代理工具的WEB面板。集成修改配置，开启，关闭为一体的管理功能的网页面板。设计初衷是为了让所有的**扶墙专用VPS**能有一个简单的控制面板。类似于搬瓦工那种的。目前已加入V2ray，ShadowsocksR。~~未来还会支持 Anyconnet等~~。

## 功能

- 面板里 启动/关闭/重启 SSR服务端
- 面板直接设置连接密码，端口，加密等设置选项。
- 自动修改设置防火墙
- 在WEB端显示 二维码，SSR链接
- 自助修改V2ray的端口，传输方式，Mux等选项
- 面板开关重启V2Ray服务器
- 查看运行日志
- 没有数据库，一切靠JSON，内存占用不大
- Caddy反向代理，可以自定义域名和端口


## 缺点

- 未设置开机自启动，启动请手动输入 sweb 开启
- 仅仅是个人SSR WEB面板，无法进行多用户，否则JSON解析会报错
- 部分组件安装可能需要阅读文档和确认，未能完全一键，将就一下
- v2客户端下载暂时有问题，看情况修复

## 系统支持

**不支持CentOS 6**

目前已经测试通过的系统有

- CentOS 7
- Ubuntu 14
- Ubuntu 16
- Debian 8

## 安装

```shell
wget -N --no-check-certificate  https://raw.githubusercontent.com/ai2c133/SWEB/master/install.sh && bash install.sh
```
- 自行设置控制面板的用户名、密码、域名（ip）、端口
- ssr安装可以全部回车跳过，安装完毕后可以在控制面板调整
- 部分组件安装可能需要手动确认

## 使用方法

安装完成后，直接输入 **http://你的域名（IP）:端口** 就可以使用你设置的用户名密码进入管理啦~ 

如果要 打开/关闭 面板程序，修改面板密码，只需要在 SSH 里面输入 **sweb** 然后回车，就可以了哦。


## 引用

- Teddysun（秋水逸冰大佬）的脚本负责SSR一键安装：https://shadowsocks.be/9.html
- Toyo（逗比根据地大佬）的Caddy脚本意见安装：https://doub.bid/shell-jc1/


