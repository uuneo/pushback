English | **[中文](README.md)**


<p align="center">
<img src="/docs/_media/egglogo.png" alt="pushback" title="pushback" width="300"/>
</p>

> [!IMPORTANT]
>
> - Some of the project's code is derived from [Bark](https://github.com/Finb/Bark)
> - Compatible with all usage methods of Bark
>




# Pushback
![IOS](https://img.shields.io/badge/IPhone-16+-ff69b4.svg) ![IOS](https://img.shields.io/badge/IPad-16+-ff69b4.svg)
### An iOS application that allows you to push custom notifications to your Apple devices.
[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="Pushback App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR)
[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Pushback App" height="40">](https://apps.apple.com/us/app/pushback-push-to-phone/id6615073345)

## Issue Feedback Telegram Group
[Pushback Feedback Group](https://t.me/+pmCp6gWuAzFjYWQ1)

## Documentation
[View Documentation](https://uuneo.github.io/pushback)


## Usage
1. Open the app and copy the test URL

<img src="/docs/_media/example.jpg" width=365 />

2. Modify the content and request this URL
```
You can send GET or POST requests, and you'll receive a push notification immediately upon success.

URL structure: The first part is the key, followed by three matches
/:key/:body 
/:key/:title/:body 
/:key/: title/:subtitle/:body 

title: The push title, slightly larger than the body text 
subtitle: The push subtitle
body: The push content, use the newline character '\n' for line breaks 
For POST requests, the parameter names are the same as above
```

## Parameters

* url
```
// Click on the push notification to jump to the specified URL
https://push.uuneo.com/yourkey/url?url=https://www.google.com 
```
* group
```
// Specify the push message group to view pushes by group.
https://push.uuneo.com/yourkey/group?group=groupName
```
* icon
```
// Specify the push message icon
https://push.uuneo.com/yourkey/icon?icon=https://pushback.uuneo.com/_media/avatar.png
```
* image
```
// Specify the push message image, Pictures are automatically saved to albums
https://push.uuneo.com/yourkey/icon?image=https://pushback.uuneo.com/_media/avatar.png
```
|手动保存|自动保存|
|-|-|
|<img src="/docs/_media/shoudong.gif" width="350">|<img src="/docs/_media/auto.gif" width="350">|

* video
```
// Specify the push message video and drop it down to play it
https://push.uuneo.com/yourkey/icon?video=https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-360p.mp4
```

* sound
```
// Specify the push message sound
https://push.uuneo.com/yourkey/sound?sound=alarm
```
* call
```
// Play sound repeatedly for 30 seconds
https://push.uuneo.com/yourkey/call?call=1
```
* ciphertext
```
// Encrypted push message
https://push.uuneo.com/yourkey/ciphertext?ciphertext=
```
* Time-sensitive notifications
```
// Set time-sensitive notifications
https://push.uuneo.com/yourkey/时效性通知?level=timeSensitive

// Optional values 
// active: Default value when not set, the system will immediately display the notification by lighting up the screen. 
// timeSensitive: Time-sensitive notification, can be displayed during focus mode. 
// passive: Adds notification to the notification list without lighting up the screen.
```

## Safari/Chrome Extension
 * safari extension does not need to be installed, it comes with the app
 * The browser sends text, images, and links directly to the phone
 * The extension sends Instagram image URLs to the phone, which saves them to the album automatically.
 * [Install Chrome Extension](https://chromewebstore.google.com/detail/pushback/gadgoijjifgnbeehmcapjfipggiijeej)



## Third-Party Libraries Used in the Project
- [Defaults](https://github.com/sindresorhus/Defaults)
- [QRScanner](https://github.com/mercari/QRScanner)
- [realm](https://github.com/realm/realm-swift)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
