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
지원되는 매개변수 목록입니다. 구체적인 효과는 앱에서 미리 볼 수 있습니다.
모든 매개변수는 다양한 형식을 지원합니다: SubTitle / subTitle / subtitle / sub_title / sub-title /

| 매개변수 | Bark | Pushback 사용 차이 |
| ----- | ----------- | ----------- |
| id | 없음 | UUID, 동일한 id를 전달하면 기존 메시지를 덮어씁니다 |
| title | 푸시 제목 | 동일 |
| subtitle | 푸시 부제목 | 동일 |
| body | 푸시 내용 | 동일 (content/message/data/text를 body의 대체로 지원) |
| markdown | 지원하지 않음 | Markdown 렌더링 (md 약어 지원) |
| level | 푸시 중단 수준.<br>**active**: 기본값, 시스템이 즉시 화면을 켜서 알림을 표시<br>**timeSensitive**: 시간 민감한 알림, 집중 모드에서 표시 가능<br>**passive**: 알림 목록에만 알림을 추가하고 화면을 켜지 않음<br>**critical**: 중요한 알림, 집중 모드나 무음 모드에서도 알림 가능 | 호환됨. 매개변수는 숫자로 대체 가능: `level=1`<br>0: passive<br>1: active<br>2: timeSensitive<br>3...10: critical, 이 모드에서 숫자는 볼륨에 사용됨 (`level=3...10`) |
| volume | `level=critical` 모드에서의 볼륨, 범위 0...10 | 동일 |
| call | 긴 알림, WeChat 전화 알림과 유사 | 동일 |
| badge | 푸시 배지, 임의의 숫자 가능 | 읽지 않은 수 기준으로 계산 |
| autoCopy | iOS 14.5 미만에서 푸시 내용 자동 복사, iOS 14.5 이상에서는 수동으로 길게 누르거나 아래로 당겨야 함 | 이 앱 iOS 16+ |
| copy | 푸시 복사 시, 복사할 내용을 지정. 이 매개변수를 전달하지 않으면 전체 푸시 내용을 복사 | 동일 |
| sound | 푸시에 다른 벨소리 설정 가능 | 앱에서 기본 벨소리 설정 가능 |
| icon | 푸시에 사용자 정의 아이콘 설정, 아이콘은 자동으로 캐시됨 | 동일, 클라우드 아이콘 업로드 추가 지원 |
| image | 이미지 URL 전달, 수신 시 자동으로 다운로드 및 캐시 | 동일 |
| savealbum | 지원하지 않음 | "1"을 전달하면 자동으로 앨범에 이미지 저장 |
| group | 메시지 그룹화, 푸시는 알림 센터에서 `group`별로 표시<br>또한 기록 메시지 목록에서 다른 그룹을 볼 수 있음 | 호환됨 |
| isArchive | `1`을 전달하면 푸시 저장, 다른 값을 전달하면 저장하지 않음, 전달하지 않으면 앱 설정에 따름 | `ttl=일수` 사용 |
| url | 푸시 클릭 시 이동할 URL, URL Scheme과 Universal Link 지원 | 동일 |
