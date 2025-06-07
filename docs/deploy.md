*感谢[BARK](https://github.com/Finb/Bark) 的开源项目*

## Docker-Compose 
* 配置

```yaml
system: # 系统配置
  name: "pushback" # 服务名称
  user: "" # 服务用户名
  password: "" # 服务密码
  address: "0.0.0.0:8080" # 服务监听地址
  debug: false # 是否开启调试模式
  dsn: "" # mysql user:password@tcp(host:port)
  maxApnsClientCount: 1 # 最大APNs客户端连接数

apple: # 苹果推送配置
  keyId: "BNY5GUGV38" # 密钥ID
  teamId: "FUWV6U942Q" # 团队ID
  topic: "me.uuneo.Meoworld" # 推送主题
  develop: false # 是否开发环境
  apnsPrivateKey: |- # APNs私钥
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgvjopbchDpzJNojnc
    o7ErdZQFZM7Qxho6m61gqZuGVRigCgYIKoZIzj0DAQehRANCAAQ8ReU0fBNg+sA+
    ZdDf3w+8FRQxFBKSD/Opt7n3tmtnmnl9Vrtw/nUXX4ldasxA2gErXR4YbEL9Z+uJ
    REJP/5bp
    -----END PRIVATE KEY-----
  adminId: "" # 管理员ID

```

### 命令行参数

除了配置文件外，还可以通过命令行参数或环境变量来配置服务：

| 参数 | 环境变量 | 说明 | 默认值 |
|------|----------|------|--------|
| `--addr` | `PB_SERVER_ADDR` | 服务器监听地址 | 空 |
| `--config`, `-c` | `PB_SERVER_CONFIG` | 配置文件路径 | `/data/config.yaml` |
| `--dsn` | `PB_SERVER_DSN` | MySQL DSN | 空 |
| `--maxApnsClientCount`, `-max` | `PB_MAX_APNS_CLIENT_COUNT` | 最大 APNs 客户端数量 | 0（无限制） |
| `--debug` | `PB_DEBUG` | 启用调试模式 | false |
| `--develop`, `-dev` | `PB_DEVELOP` | 启用推送开发模式 | false |
| `--user`, `-u` | `PB_USER` | 服务器用户名 | 空 |
| `--password`, `-p` | `PB_PASSWORD` | 服务器密码 | 空 |

命令行参数优先级高于配置文件，环境变量优先级高于命令行参数。

## Docker部署

```shell

docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  sanvx/pushback:latest
```

## Docker-compose部署
* 复制项目中的/deploy文件夹到服务器上，然后执行以下命令即可。
* 可选 `config.yaml` 配置文件，文件中的配置项，可以根据自己的需求进行修改。

* 启动
```shell
docker-compose up -d
```

## 手动部署

1. 根据平台下载可执行文件:<br> <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a><br>
或自己编译<br>
<a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. 运行
---
```
./main
```

## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. App代码: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

