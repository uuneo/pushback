*[BARK](https://github.com/Finb/Bark) 오픈 소스 프로젝트에 감사드립니다.*

## 푸시 알림 보내기
1. 앱을 열고 테스트 URL을 복사합니다.

<img src="../_media/example.jpeg" width=365 />

2. 내용을 수정하고 이 URL로 요청을 보냅니다.<br>
GET 또는 POST 요청을 보낼 수 있습니다. 요청이 성공하면 즉시 푸시 알림이 전송됩니다.<br>
Bark와의 차이점: 매개변수 우선순위 【POST > GET > URL 매개변수】. POST 매개변수가 GET 매개변수를 덮어쓰며, GET 매개변수가 URL 매개변수를 덮어씁니다.

## URL 형식
URL은 푸시 키, `title` 매개변수, `body` 매개변수로 구성됩니다. 두 가지 조합 형식이 있습니다:

```
https://push.uuneo.com/:key/:body 
https://push.uuneo.com/:key/:title/:body 
https://push.uuneo.com/:key/:title/:subtitle/:body

```

## 요청 방법
##### GET 요청
매개변수는 URL에 추가됩니다. 예:
```sh
curl https://push.uuneo.com/your_key/PushContent?group=GroupName&copy=CopyText
```
*URL에 매개변수를 수동으로 추가할 때는 올바른 URL 인코딩을 확인하세요. 자세한 내용은 [FAQ: URL 인코딩](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc)를 참조하세요.*

##### POST 요청
매개변수는 요청 본문에 배치됩니다. 예:
```sh
curl -X POST https://push.uuneo.com/your_key \
     -d'body=PushContent&group=GroupName&copy=CopyText'
```
##### POST 요청은 JSON을 지원합니다. 예:
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

##### JSON 요청 키는 요청 본문에 포함될 수 있으며, URL 경로는 `/push`여야 합니다. 예:
```sh
curl -X "POST" "https://push.uuneo.com/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test pushback Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

## 요청 매개변수
지원되는 매개변수 목록은 앱에서 미리보기로 확인할 수 있습니다.

| 매개변수 | Bark | Pushback 사용 차이점 |
| --------- | ---- | -------------------------- |
| id | 없음 | UUID를 전달하여 동일한 id로 기존 메시지 덮어쓰기 |
| title | 푸시 알림 제목 | 동일 |
| subtitle | 푸시 알림 부제목 | 동일 |
| body | 푸시 알림 내용 | 동일, markdown을 전달할 때는 category=markdown 필요 |
| level | 푸시 알림 방해 수준.<br>**active**: 기본값, 시스템이 즉시 화면을 켜고 알림을 표시합니다.<br>**timeSensitive**: 시간 민감 알림, 집중 모드에서도 표시됩니다.<br>**passive**: 화면을 켜지 않고 알림 목록에 추가합니다.<br>**critical**: 중요한 알림, 집중 모드나 무음 모드에서도 표시됩니다. | 호환 가능. 매개변수를 숫자로 대체 가능: `level=1`<br>0: passive<br>1: active<br>2: timeSensitive<br>3...10: critical, 숫자는 볼륨(`level=3...10`)으로 사용됩니다. |
| volume | 중요한 모드 알림의 볼륨 수준. 범위: 0...10 | 동일 |
| call | 긴 알림, WeChat 통화 알림과 유사 | 동일 |
| badge | 푸시 알림 배지, 임의의 숫자 가능 | 앱에서 사용자 지정 배지를 활성화해야 합니다. 그렇지 않으면 읽지 않은 수를 기준으로 계산됩니다. |
| autoCopy | iOS 14.5 이하에서 푸시 내용을 자동으로 복사합니다. iOS 14.5 이상에서는 알림을 길게 누르거나 아래로 당겨야 합니다. | 이 앱에서는 iOS 16+에서만 사용 가능. |
| copy | 푸시 알림을 복사할 때 복사할 내용을 지정합니다. 지정하지 않으면 전체 푸시 내용이 복사됩니다. | 동일 |
| sound | 푸시 알림의 사용자 지정 소리를 설정합니다. | 기본 소리는 앱에서 설정할 수 있습니다. |
| icon | 푸시 알림의 사용자 지정 아이콘을 설정합니다. 사용자 지정 아이콘은 기본 Bark 아이콘을 대체합니다.<br>아이콘은 로컬에 자동으로 캐시되며, 동일한 URL은 한 번만 다운로드됩니다. | 호환 가능 |
| image | 알림을 받을 때 다운로드 및 캐시할 이미지의 URL. | 알림을 아래로 당기거나 앱 내에서 이미지를 볼 수 있습니다.<br>로컬로 이름이 변경된 이미지는 `icon=local_name`을 통해 직접 사용할 수 있습니다. |
| group | 지정된 값으로 알림을 그룹화합니다. 알림 센터에서 그룹화된 알림이 표시되며, 기록 목록에서 필터링할 수 있습니다. | 호환 가능 |
| isArchive | `1`로 설정하면 알림을 저장하고, 다른 값은 저장하지 않습니다. 제공되지 않으면 앱 설정에 따라 결정됩니다. | `ttl=days`를 사용합니다. 제공되지 않으면 앱 설정이 사용됩니다. |
| url | 푸시 알림을 클릭할 때 열리는 URL. URL Scheme 및 Universal Link를 지원합니다. | 동일 |
