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
The list of supported parameters, the specific effects can be previewed in the app.

| Parameter | Bark | Pushback Usage Differences |
| --------- | ---- | -------------------------- |
| id | None | Pass UUID to overwrite existing message with same id |
| title | Push notification title | Same |
| subtitle | Push notification subtitle | Same |
| body | Push notification content | Same, requires category=markdown when sending markdown |
| level | Push notification interruption level.<br>**active**: Default, the system will immediately light up the screen to show the notification.<br>**timeSensitive**: Time-sensitive notifications, displayed even during focus mode.<br>**passive**: Adds notifications to the notification list without lighting up the screen.<br>**critical**: Critical notifications, displayed even during focus mode or silent mode. | Compatible. Parameters can be replaced with numbers: `level=1`<br>0: passive<br>1: active<br>2: timeSensitive<br>3...10: critical, where numbers are used for volume (`level=3...10`). |
| volume | Volume level for critical mode notifications. Range: 0...10 | Same |
| call | Long notification, similar to a WeChat call notification | Same |
| badge | Push notification badge, can be any number | Requires enabling custom badges in-app. Otherwise, calculated based on unread count. |
| autoCopy | Automatically copies the push content on iOS 14.5 or below. For iOS 14.5 and above, requires long-pressing or pulling down the notification manually. | Only available on iOS 16+ in this app. |
| copy | Specifies the content to copy when copying a push notification. If not specified, the entire push content will be copied. | Same |
| sound | Sets a custom sound for the push notification. | Default sound can be set in-app. |
| icon | Sets a custom icon for the push notification. The custom icon replaces the default Bark icon.<br>The icon is automatically cached locally, and identical URLs will only be downloaded once. | Compatible |
| image | URL of an image to be downloaded and cached when the notification is received. | Can view the image by pulling down the notification or within the app.<br>Locally renamed images can be directly used via `icon=local_name`. |
| group | Groups notifications by the specified value. Notifications will appear grouped in the notification center and can be filtered in the history list. | Compatible |
| isArchive | `1` to save the notification, any other value to discard. If not provided, the app's settings will determine whether to save. | Uses `ttl=days`. If not provided, app settings are used. |
| url | URL to open when the push notification is clicked. Supports URL Scheme and Universal Link. | Same |
