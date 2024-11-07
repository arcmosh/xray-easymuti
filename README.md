# xray-easymuti
Xray, VLESS_Reality + Vmess 双协议 极简一键脚本，不罗嗦安装开箱即用。

# 说明 
简单改了一下原大佬的脚本，为了自用。所以把交互式的小白操作都去掉了。  

然后，我个人喜欢双模式，因为vmess在中转隧道等各种奇技淫巧中表现更好，reality用于备用的直连节点，比较让我安心。  

首次安装会随机生成一个uuid，之后，vmess的端口号公私钥等都是在此基础上映射而来的。因此只要知道uuid就可以快速恢复配置。

# 一键安装

Debian Ubuntu 肯定没问题其他的系统我没试

首先你可能需要准备下环境
```
apt update
apt install -y curl
```

**直接运行下面的就行了**
```
bash <(curl -L https://github.com/arcmosh/xray-easymuti/raw/main/install.sh)
```

启用宾客用户（简易多用户）: 2024.11 新功能 

启用方法：在原有的安装命令后增加 -g 参数即可 

对于全新安装，运行下面的命令以直接启用宾客用户 
```
bash <(curl -L https://github.com/arcmosh/xray-easymuti/raw/main/install.sh) -g
```

# 宾客用户的详细说明
**这不是一个严谨的实现方式，你可以和你的朋友分享使用，但最好不要公开给公众使用以免安全风险。**
 
**默认生成10个宾客连接凭证，宾客0~9。** 脚本设计上共有10个宾客插槽，所以最多10个宾客 

**使用方法** 

1. 先把链接配置**导入到你自己的设备上**，然后修改UUID为宾客的连接凭证并保存。
2. 测试一下是不是可以连接，没问题的话导出新的分享链接给他人。

**封锁宾客** 

如果你不再想让某个宾客连接，请使用 -g xxx 重新运行脚本来关闭指定的宾客，例如
```
UUID=xxxxxxxx-xxxx-xxxxxx  bash <(curl -L https://github.com/arcmosh/xray-easymuti/raw/main/install.sh) -g 903
```
这将删除宾客0 宾客3 和宾客9的连接权限，并保持其他人的连接凭证不变化。

# 高级安装（自定义主机名或UUID）
```
HOST=example.com UUID=xxxxxxxx-xxxx-xxxxxx  bash <(curl -L https://github.com/arcmosh/xray-easymuti/raw/main/install.sh)
```
或者，也可以先下载，编辑脚本最上面几行Reality配置项(端口和伪装域名等)然后再安装
```
wget https://github.com/arcmosh/xray-easymuti/raw/main/install.sh
vi install.sh
bash install.sh
```
