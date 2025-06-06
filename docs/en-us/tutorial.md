*Thanks to the [BARK](https://github.com/Finb/Bark) open-source project.*

## Sending Push Notifications
1. Open the app and copy the test URL.

<img src="../_media/example.jpeg" width=365 />

2. Modify the content and send a request to this URL.<br>
You can send either a GET or POST request. A successful request will result in an immediate push notification.<br>
Difference from Bark: Parameter priority 【POST > GET > URL params】. POST parameters override GET parameters, and GET parameters override URL parameters accordingly.

## URL Format
The URL consists of a push key, the `title` parameter, and the `body` parameter. There are two combination formats:

```
https://push.uuneo.com/:key/:body 
https://push.uuneo.com/:key/:title/:body 
https://push.uuneo.com/:key/:title/:subtitle/:body

```

## Request Methods
##### GET Request
Parameters are appended to the URL, for example:
```sh
curl https://push.uuneo.com/your_key/PushContent?group=GroupName&copy=CopyText
```
*When manually appending parameters to the URL, please ensure proper URL encoding. You can refer to [FAQ: URL Encoding](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc) for more details.*


##### POST Request
Parameters are placed in the request body, for example:
```sh
curl -X POST https://push.uuneo.com/your_key \
     -d'body=PushContent&group=GroupName&copy=CopyText'
```
##### POST requests support JSON, for example:
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

##### The JSON request key can be included in the request body, and the URL path must be `/push`, for example:
```sh
curl -X "POST" "https://push.uuneo.com/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test pushback Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

## Request Parameters
List of supported parameters, specific effects can be previewed in the APP.
All parameters support various formats: SubTitle / subTitle / subtitle / sub_title / sub-title /

| Parameter | Bark | Pushback Usage Differences |
| ----- | ----------- | ----------- |
| id | None | UUID, messages with same id will override existing messages |
| title | Push title | Same |
| subtitle | Push subtitle | Same |
| body | Push content | Same (supports content/message/data/text as alternatives to body) |
| markdown | Not supported | Renders Markdown (supports md shorthand) |
| level | Push interruption level.<br>**active**: Default value, system will immediately light up screen to show notification<br>**timeSensitive**: Time-sensitive notification, can be shown during focus mode<br>**passive**: Only adds notification to notification list, won't light up screen<br>**critical**: Important alert, can notify during focus mode or silent mode | Compatible. Parameter can use numbers instead: `level=1`<br>0: passive<br>1: active<br>2: timeSensitive<br>3...10: critical, in this mode numbers will be used for volume (`level=3...10`) |
| volume | Volume in `level=critical` mode, range 0...10 | Same |
| call | Long alert, similar to WeChat call notification | Same |
| badge | Push badge, can be any number | Calculated based on unread count |
| autoCopy | Auto-copy push content below iOS 14.5, requires manual long-press or pull-down above iOS 14.5 | This app iOS 16+ |
| copy | When copying push, specifies content to copy. If not provided, copies entire push content | Same |
| sound | Can set different ringtones for push | Default ringtone can be set in app |
| icon | Set custom icon for push, icon is automatically cached | Same, with additional cloud icon upload support |
| image | Pass image URL, automatically downloaded and cached when received | Same |
| savealbum | Not supported | Pass "1" to automatically save image to album |
| group | Groups messages, pushes will be displayed in notification center by `group`<br>Can also view different groups in history message list | Compatible |
| isArchive | Pass `1` to save push, pass other values to not save, if not passed follows app settings | Use `ttl=days` |
| url | URL to jump to when clicking push, supports URL Scheme and Universal Link | Same |
