中文 ｜ **[English](README.EN.md)** | **[日本語](README.JA.md)** | **[한국어](README.KO.md)**

> [!IMPORTANT]
>
>- 项目部分代码来自 [Bark ](https://github.com/Finb/Bark)
> 
> - Markdown 样式（已完成）
> - 铃声自动转换 （已完成）
> - 朗读消息内容(测试版) （已完成）

<p align="center">
<img src="/docs/_media/egglogo.png" alt="pushback" title="pushback" width="100"/>
</p>

# Pushback 反推
![IOS](https://img.shields.io/badge/IPhone-16+-ff69b4.svg) ![IOS](https://img.shields.io/badge/IPad-16+-ff69b4.svg) ![Markdown](https://img.shields.io/badge/gcm-markdown-green.svg)
### 是一款 iOS 应用程序，可让您将自定义通知推送到您的苹果设备


[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="Pushback App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR)
[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
alt="Pushback App"
height="40">](https://apps.apple.com/us/app/%E5%8F%8D%E6%8E%A8-%E7%BB%99%E4%BD%A0%E7%9A%84%E6%89%8B%E6%9C%BA%E5%8F%91%E6%8E%A8%E9%80%81/id6615073345)


## 问题反馈 Telegram 群
[Pushback反馈群](https://t.me/+pmCp6gWuAzFjYWQ1)


## 文档
[查看文档](https://uuneo.github.io/pushback)

## 发送推送
1. 打开APP，复制测试URL 

<img src="/docs/_media/example.jpeg" width=365 />

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

* body 
```
// content ｜ message ｜ data ｜ text | == body
https://push.uuneo.com/yourkey/?body=Test
https://push.uuneo.com/yourkey/?content=Test
                                            ...
``

* markdown / md
```
// 推送将渲染Markdown
https://push.uuneo.com/yourkey/?markdown=%23%20Pushback%0A%23%23%20Pushback%0A%23%23%23%20Pushback
```


* url
```
// 点击推送将跳转到url的地址（发送时，URL参数需要编码）
https://push.uuneo.com/yourkey/百度网址?url=https://www.baidu.com 
```
* ttl
```
// ttl = 天数 传入0不保存,不传按照app内部设置
https://push.uuneo.com/yourkey/消息保存时间?ttl=0
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
* level
```
// 消息通知级别 设置时效性通知 
https://push.uuneo.com/yourkey/时效性通知?level=timeSensitive&volume=10

// 可选参数值 也可使用 level = 1...10  volume 声音优先级大于 level
// passive(0)：仅将通知添加到通知列表，不会亮屏提醒
// active(1)：不设置时的默认值，系统会立即亮屏显示通知。
// timeSensitive(2)：时效性通知，可在专注状态下显示通知。
// critical(3-10)：重要提醒 (也代表音量 0.3-1)
```

## Safari/Chrome扩展
* safari扩展无需安装，App自带
* 浏览器直接发送文字，图片，链接到手机上
* 该扩展可直接将ins的图片网址发送到手机，手机上可以自动保存到图片到相册
* [安装Chrome扩展](https://chromewebstore.google.com/detail/pushback/gadgoijjifgnbeehmcapjfipggiijeej)

## 项目中使用的第三方库
- [Defaults](https://github.com/sindresorhus/Defaults)
- [QRScanner](https://github.com/mercari/QRScanner)
- [realm](https://github.com/realm/realm-swift)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [OpenAI](https://github.com/MacPaw/OpenAI)
- [Splash](https://github.com/AugustDev/Splash)
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)

