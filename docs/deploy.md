*感谢[BARK](https://github.com/Finb/Bark) 的开源项目*

## Docker-Compose 
* 配置

```yaml
system:
  name: "NewBearService"
  user: ""         # 用户名 非必填
  password: ""    # 密码  非必填
  host: "0.0.0.0"  # 服务监听地址
  port: "8080"   # 服务监听端口 docker-compose中的端口映射必须与此端口一致
  mode: "release"   # debug,release,test
  dbType: "default" # default,mysql
  dbPath: "/data" # 数据库文件存放路径

mysql: # 仅在 dbType: "mysql" 时有效
  host: "localhost"
  port: "3306"
  user: "root"
  password: "root"

apple: # 复制项目中的配置，不需要修改，仅在自己编译app时需要修改
  keyId:
  teamId:
  topic:
  apnsPrivateKey:

```

## Docker部署
*  因为国内情况复杂，如果下载不了镜像使用我的镜像地址，先把镜像拉取下来

```shell
docker pull crpi-qe87peuqqnyljim6.cn-shanghai.personal.cr.aliyuncs.com/neouu/pushback
docker tag crpi-qe87peuqqnyljim6.cn-shanghai.personal.cr.aliyuncs.com/neouu/pushback neouu/pushback
```


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

