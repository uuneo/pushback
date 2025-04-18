
 *[BARK](https://github.com/Finb/Bark) 오픈 소스 프로젝트에 감사드립니다.*  
### APNS 인터페이스 직접 호출
앱에서 기기의 DeviceToken을 가지고 있다면, 서버를 추가하지 않고도 Apple의 APNS 인터페이스를 호출하여 기기에 푸시 알림을 직접 보낼 수 있습니다.<br>
아래는 명령줄을 통해 푸시 알림을 보내는 예제입니다:

```shell
# 환경 변수 설정
# 키 다운로드 https://github.com/uuneo/pushbackServer/tree/main/deploy/pushback.p8
# 아래에 키 파일 경로를 입력하세요
TOKEN_KEY_FILE_NAME=
# 앱 설정에서 DeviceToken을 복사하여 여기에 입력하세요
DEVICE_TOKEN=

# 아래는 수정하지 마세요
TEAM_ID=FUWV6U942Q
AUTH_KEY_ID=BNY5GUGV38
TOPIC=me.uuneo.Meoworld
APNS_HOST_NAME=api.push.apple.com

# TOKEN 생성
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# 가능하다면 이 Token을 캐시하도록 스크립트를 개선하세요. 동일한 Token을 30분 이내에 재사용하고, 30분마다 새로 생성하세요.
# Apple의 문서에 따르면 Token 생성 최소 간격은 20분이며, 최대 유효 기간은 60분입니다.
# 빈번한 재생성은 실패할 수 있으며, 1시간 이상된 Token은 작동하지 않습니다.
# 비공식 테스트에 따르면 짧은 간격으로 생성해도 작동할 수 있지만 주의가 필요합니다.
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

# 푸시 알림 전송
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}
```

### 푸시 페이로드 형식
https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification<br>
`"mutable-content": 1`을 포함해야 합니다. 그렇지 않으면 푸시 알림 확장이 실행되지 않고 알림이 저장되지 않습니다.<br>

예제:
```js
{
    "aps": {
        "mutable-content": 1,
        "alert": {
            "title": "title",
            "body": "body"
        },
        "category": "myNotificationCategory",
        "sound": "minuet.caf"
    },
    "icon": "https://day.app/assets/images/avatar.jpg"
}
```