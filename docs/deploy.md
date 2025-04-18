*感谢[BARK](https://github.com/Finb/Bark) 的开源项目*

## Docker-Compose 
* 配置

```yaml
system: # 系统配置
  name: "Pushback" # 服务名称
  user: "" # 服务用户名
  password: "" # 服务密码
  host: "0.0.0.0" # 服务地址
  port: "8180" # 服务端口
  mode: "release" # debug, release
  dbType: "default" # 数据库类型
  dbPath: "./" # 数据库文件路径
  hostName: "https://push.uuneo.com" # 服务域名

mysql: # 数据库配置
  host: "localhost"
  port: "3306"
  user: "root"
  password: "root"

apple: # 苹果推送配置
  keyId: "BNY5GUGV38"
  teamId: "FUWV6U942Q"
  topic: "me.uuneo.Meoworld"
  develop: true # 推送程序的模式
  adminId: "" # 管理员id
  apnsPrivateKey: 

```

## Docker部署

```shell

docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  neouu/pushback:latest
```

## Docker-compose部署
* 复制项目中的/deploy文件夹到服务器上，然后执行以下命令即可。
* 必须有/data/config.yaml 的配置文件，否则无法启动，文件中的配置项，可以根据自己的需求进行修改。

* 启动
```shell
docker-compose up -d
```

## 手动部署

1. 根据平台下载可执行文件:<br> <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a><br>
或自己编译<br>
<a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. 运行
```
./二进制文件名 -c config.yaml
```
3. 你可能需要
```
chmod +x 二进制文件名
```
请注意 pushback-server 单独运行必须指定 配置文件地址

## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. App代码: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

