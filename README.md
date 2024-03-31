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

直接运行下面的就行了
```
bash <(curl -L https://github.com/arcmosh/xray-easymuti/raw/main/install.sh)
```

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
