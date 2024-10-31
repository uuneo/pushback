*感谢[BARK](https://github.com/Finb/Bark) 的开源项目*
## Docker 
```
docker run -dt --name pushback -p 8080:8080 -v `pwd`/data:/data thurmantsao/alarm-paw-server
```

## Docker-Compose 
```
mkdir -p pushback/data \
&& cd pushback \
&& curl -sl https://github.com/uuneo/pushbackServer/blob/main/deploy/compose.yaml > docker-compose.yaml \
&& curl -sl https://github.com/uuneo/pushbackServer/blob/main/deploy/data/config.yaml > ./data/config.yaml \
&& docker-compose up -d

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
请注意 alarm-paw-server 单独运行必须指定 配置文件地址


## Render
Render 能非常简单的创建免费的 alarm-paw-server
1. [注册](https://dashboard.render.com/register/)一个 Render 账号
2. 创建一个 [New Web Service](https://dashboard.render.com/select-repo?type=web)
3. 在底部的 **Public Git repository** 输入框输入下面的URL
```
https://github.com/uuneo/pushbackServer
```
4. 点击 **Continue** 输入表单
   * Name - 名称，随便取个名字，例如 pushbackServer
   * Region - 服务器地区，选择离你近的
   * Start Command - 程序执行命令,填`./app -serverless true`。（注意不要漏了 ./app 前面的点）
   * Instance Type - 选 Free ，免费的足够用了。
   * 点击 Advanced 展开更多选项
   * 点击 Add Environment Variable 添加 Serverless 模式需要的 BARK_KEY 和 BARK_DEVICE_TOKEN 字段。 (填写要求参考 [Serverless](#Serverless)) <br><img src="../_media/environment.png" />
   * 其他的默认不动
5. 点击底部的 Create Web Service 按钮，然后等待状态从 In progress 变成 Live，可能需要几分钟到十几分钟。
6. 页面顶部找到你的服务器URL，这个就是bark-server服务器URL，在 Bark App 中添加即可
```
https://[your-server-name].onrender.com
```
7. 如果添加失败，可以等待一段时间再试，有可能服务还没准备好。
8. 不添加到 Bark App 中也可以，直接调用就能发推送。BARK_KEY 就是上面环境变量中你填写的。
```
https://[your-server-name].onrender.com/BARK_KEY/推送内容
```

## 测试
```
curl http://0.0.0.0:8080/ping
```
返回 pong 就证明部署成功了

## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. App代码: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

