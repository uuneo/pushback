 *感谢[BARK](https://github.com/Finb/Bark) 的开源项目*

## 发送推送 
1. 打开APP，复制测试URL 

<img src="../_media/example.jpeg" width=365 />

2. 修改内容，请求这个URL。<br>
可以发 GET 或者 POST 请求 ，请求成功会立即收到推送 <br>
与bark差异：参数权限 【POST > GET > URL params 】 post参数会覆盖get参数以此类推

## URL格式
URL由推送key、参数 title、参数 body 组成。有下面两种组合方式

```
https://push.uuneo.com/:key/:body 
https://push.uuneo.com/:key/:title/:body 
https://push.uuneo.com/:key/:title/:subtitle/:body

```

## 请求方式
##### GET 请求参数拼接在 URL 后面，例如：
```sh
curl https://push.uuneo.com/your_key/推送内容?group=分组&copy=复制
```
*手动拼接参数到URL上时，请注意URL编码问题，可以参考阅读[常见问题：URL编码](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc)*

##### POST 请求参数放在请求体中，例如：
```sh
curl -X POST https://push.uuneo.com/your_key \
     -d'body=推送内容&group=分组&copy=复制'
```
##### POST 请求支持JSON，例如：
```sh
curl -X "POST" "//https://push.uuneo.com/your_key" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test pushback Server",
  "title": "Test Title",
  "badge": 1,
  "category": "myNotificationCategory",
  "sound": "minuet.caf",
  "icon": "https://day.app/assets/images/avatar.jpg",
  "group": "test",
  "url": "https://mritd.com"
}'
```

##### JSON 请求 key 可以放进请求体中,URL 路径须为 /push，例如
```sh
curl -X "POST" "https://push.uuneo.com/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test pushback Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

## 请求参数
支持的参数列表，具体效果可在APP内预览。

| 参数 | Bark | Pushback 使用差异 |
| ----- | ----------- | ----------- |
| id | 无 | UUID 传入相同id覆盖原有消息 |
| title | 推送标题 | 一致 |
| subtitle | 推送副标题 | 一致 |
| body | 推送内容 | 一致 传入markdown时需category=markdown |
| level | 推送中断级别。<br>**active**：默认值，系统会立即亮屏显示通知<br>**timeSensitive**：时效性通知，可在专注状态下显示通知。<br>**passive**：仅将通知添加到通知列表，不会亮屏提醒。<br>**critical**：重要提醒，可在专注模式或者静音模式下提醒 | 兼容。参数可以使用数字替代：`level=1`<br>0：passive<br>1：active<br>2：timeSensitive<br>3...10：critical，此模式数字将用于音量（`level=3...10`） |
| volume | `level=critical` 模式下音量，取值范围 0...10 | 一致 |
| call | 长提醒，类似微信电话通知 | 一致 |
| badge | 推送角标，可以是任意数字 | 应用内开启自定义角标才能生效，否则按照未读数计算 |
| autoCopy | iOS 14.5 以下自动复制推送内容，iOS 14.5 以上需手动长按推送或下拉推送 | 本应用 iOS 16+ |
| copy | 复制推送时，指定复制的内容，不传此参数将复制整个推送内容。 | 一致 |
| sound | 可以为推送设置不同的铃声 | 应用内可设置默认铃声 |
| icon | 为推送设置自定义图标，设置的图标将替换默认 Bark 图标。<br>图标会自动缓存在本机，相同的图标 URL 仅下载一次。 | 兼容，支持上传云图标 |
| image | 传入图片地址，手机收到消息后自动下载缓存 | 消息下拉可以查看图片<br> |
| group | 对消息进行分组，推送将按 `group` 分组显示在通知中心中。<br>也可在历史消息列表中选择查看不同的群组。 | 兼容 |
| isArchive | 传 `1` 保存推送，传其他的不保存推送，不传按 App 内设置来决定是否保存。 | 用 `ttl=天数`，不传以 App 内设置为准 |
| url | 点击推送时，跳转的 URL，支持 URL Scheme 和 Universal Link | 一致 |
