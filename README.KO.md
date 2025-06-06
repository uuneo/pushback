한국어 | **[English](README.EN.md)** | **[中文](README.md)** | **[日本語](README.JA.md)** 


> [!IMPORTANT]
>
>- 프로젝트의 일부 코드는 [Bark](https://github.com/Finb/Bark)에서 가져왔습니다
>
> - 마크다운 스타일링 (완료)
> - 자동 벨소리 변환 (완료)
> - 메시지 내용 읽기 (베타) (완료)


<p align="center">
<img src="/docs/_media/egglogo.png" alt="pushback" title="pushback" width="100"/>
</p>


# Pushback
![IOS](https://img.shields.io/badge/IPhone-16+-ff69b4.svg) ![IOS](https://img.shields.io/badge/IPad-16+-ff69b4.svg) ![Markdown](https://img.shields.io/badge/gcm-markdown-green.svg)
### Apple 기기에 맞춤형 알림을 보낼 수 있는 iOS 애플리케이션입니다.
[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="Pushback App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR)
[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Pushback App" height="40">](https://apps.apple.com/us/app/pushback-push-to-phone/id6615073345)

## 이슈 피드백 텔레그램 그룹
[Pushback 피드백 그룹](https://t.me/+pmCp6gWuAzFjYWQ1)

## 문서
[문서 보기](https://uuneo.github.io/pushback)


## 사용 방법
1. 앱을 열고 테스트 URL을 복사하세요

<img src="/docs/_media/example.jpeg" width=365 />

2. 내용을 수정하고 이 URL을 요청하세요
```
GET 또는 POST 요청을 보낼 수 있으며, 성공하면 즉시 푸시 알림을 받게 됩니다.

URL 구조: 첫 번째 부분은 키이고, 그 다음 세 가지 매치가 있습니다
/:key/:body 
/:key/:title/:body 
/:key/:title/:subtitle/:body 

title: 푸시 제목, 본문 텍스트보다 약간 더 큽니다
subtitle: 푸시 부제목
body: 푸시 내용, 줄 바꿈에는 '\n' 문자를 사용합니다
POST 요청의 경우 매개변수 이름은 위와 동일합니다
```

## 매개변수

* body 
```
// content ｜ message ｜ data ｜ text | == body
https://push.uuneo.com/yourkey/?body=Test
https://push.uuneo.com/yourkey/?content=Test
                                            ...
``

* Markdown
```
//  지정하면 푸시 알림에서 마크다운이 렌더링됩니다
https://push.uuneo.com/yourkey/?markdown=%23%20Pushback%0A%23%23%20Pushback%0A%23%23%23%20Pushback
```

* url
```
// 푸시 알림을 클릭하여 지정된 URL로 이동합니다
https://push.uuneo.com/yourkey/url?url=https://www.google.com 
```
* ttl
```
// ttl = 일수, 0을 전달하면 저장하지 않음; 전달하지 않으면 앱의 내부 설정을 따름
https://push.uuneo.com/yourkey/message-saveduration?ttl=0
```
* group
```
// 푸시 메시지 그룹을 지정하여 그룹별로 푸시를 볼 수 있습니다.
https://push.uuneo.com/yourkey/group?group=groupName
```
* icon
```
// 푸시 메시지 아이콘 지정
https://push.uuneo.com/yourkey/icon?icon=https://pushback.uuneo.com/_media/avatar.png
```
* image
```
// 푸시 메시지 이미지 지정, 이미지는 자동으로 앨범에 저장됩니다
https://push.uuneo.com/yourkey/icon?image=https://pushback.uuneo.com/_media/avatar.png
```

* sound
```
// 푸시 메시지 소리 지정
https://push.uuneo.com/yourkey/sound?sound=alarm
```
* call
```
// 30초 동안 반복적으로 소리를 재생합니다
https://push.uuneo.com/yourkey/call?call=1
```
* ciphertext
```
// 암호화된 푸시 메시지
https://push.uuneo.com/yourkey/ciphertext?ciphertext=
```
* level
```
// 알림 수준 설정 및 시간 민감도 알림
https://push.uuneo.com/yourkey/Timeliness notice?level=timeSensitive

// 선택적 매개변수 값으로 level = 1...10도 사용할 수 있으며, volume은 level보다 우선순위가 높습니다
// passive(0): 화면을 켜지 않고 알림 목록에 알림을 추가합니다.
// active(1): 설정하지 않았을 때의 기본값으로, 시스템이 즉시 화면을 켜서 알림을 표시합니다.
// timeSensitive(2): 시간 민감도 알림으로, 집중 모드 중에도 표시될 수 있습니다.
// critical(3-10): 중요 알림 (0.3에서 1까지의 볼륨을 나타내기도 함).
```

## Safari/Chrome 확장 프로그램
 * Safari 확장 프로그램은 별도 설치가 필요 없으며 앱에 기본 포함되어 있습니다
 * 브라우저에서 텍스트, 이미지, 링크를 직접 휴대폰으로 전송합니다
 * 확장 프로그램은 Instagram 이미지 URL을 휴대폰으로 전송하며, 자동으로 앨범에 저장됩니다
 * [Chrome 확장 프로그램 설치](https://chromewebstore.google.com/detail/pushback/gadgoijjifgnbeehmcapjfipggiijeej)



## 프로젝트에서 사용된 타사 라이브러리
- [Defaults](https://github.com/sindresorhus/Defaults)
- [QRScanner](https://github.com/mercari/QRScanner)
- [realm](https://github.com/realm/realm-swift)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [OpenAI](https://github.com/MacPaw/OpenAI)
- [Splash](https://github.com/AugustDev/Splash)
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)

