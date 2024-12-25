**[English](README.EN.md)** | 中文

<p align="center">
<img src="/docs/_media/egglogo.png" alt="pushback" title="pushback" width="300"/>
</p>


> [!IMPORTANT]
>
> - 项目部分代码来自 [Bark ](https://github.com/Finb/Bark)
> - 兼容Bark的所有使用方法
>

# Pushback 反推
![IOS](https://img.shields.io/badge/IPhone-16+-ff69b4.svg) ![IOS](https://img.shields.io/badge/IPad-16+-ff69b4.svg)
### 是一款 iOS 应用程序，可让您将自定义通知推送到您的苹果设备

[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
alt="Pushback App"
height="40">](https://apps.apple.com/us/app/pushback-push-to-phone/id6615073345)


## 问题反馈 Telegram 群
[Pushback反馈群](https://t.me/+pmCp6gWuAzFjYWQ1)


## 文档
[查看文档](https://uuneo.github.io/pushback)

## 发送推送
1. 打开APP，复制测试URL 

<img src="/docs/_media/example.jpg" width=365 />

2. 修改内容，请求这个URL
```
可以发 get 或者 post 请求 ，请求成功会立即收到推送 

URL 组成: 第一个部分是 key , 之后有三个匹配 
/:key/:body 
/:key/:title/:body 
/:key/:title/:subtitle/:body 

title 推送标题 比 body 字号粗一点 
subtitle 推送副标题
body 推送内容 换行请使用换行符 '\n'
post 请求 参数名也是上面这些
```

## 功能参数

* url
```
// 点击推送将跳转到url的地址（发送时，URL参数需要编码）
https://push.uuneo.com/yourkey/百度网址?url=https://www.baidu.com 
```
* group
```
// 指定推送消息分组，可在历史记录中按分组查看推送。
https://push.uuneo.com/yourkey/需要分组的推送?group=groupName
```
* icon
```
// 指定推送消息图标
https://push.uuneo.com/yourkey/需要自定义图标的推送?icon=https://pushback.uuneo.com/_media/avatar.png
```
* image
```
// 指定推送消息图片，图片自动保存到相册
https://push.uuneo.com/yourkey/icon?image=https://pushback.uuneo.com/_media/avatar.png
```
* video
```
// 指定推送消息视频，下拉可以播放
https://push.uuneo.com/yourkey/icon?video=https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-360p.mp4
```

* sound
```
// 指定推送消息的铃声
https://push.uuneo.com/yourkey/sound?sound=alarm
```
* call
```
// 重复播放铃声30s
https://push.uuneo.com/yourkey/call?call=1
```
* ciphertext
```
// 推送加密的密文
https://push.uuneo.com/yourkey/ciphertext?ciphertext=
```
* 时效性通知
```
// 设置时效性通知
https://push.uuneo.com/yourkey/时效性通知?level=timeSensitive

// 可选参数值
// active：不设置时的默认值，系统会立即亮屏显示通知。
// timeSensitive：时效性通知，可在专注状态下显示通知。
// passive：仅将通知添加到通知列表，不会亮屏提醒
```

## Chrome扩展
* 浏览器直接发送文字，图片，链接到手机上
* 该扩展可直接将ins的图片网址发送到手机，手机上可以自动保存到图片到相册
* [安装扩展](https://chromewebstore.google.com/detail/pushback/gadgoijjifgnbeehmcapjfipggiijeej)

## 项目中使用的第三方库
- [Defaults](https://github.com/sindresorhus/Defaults)
- [QRScanner](https://github.com/mercari/QRScanner)
- [realm](https://github.com/realm/realm-swift)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

