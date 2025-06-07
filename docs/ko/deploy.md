*[BARK](https://github.com/Finb/Bark) 오픈소스 프로젝트에 감사드립니다*

## Docker-Compose 
* 설정

```yaml
system: # 시스템 설정
  name: "pushback" # 서비스 이름
  user: "" # 서비스 사용자 이름
  password: "" # 서비스 비밀번호
  address: "0.0.0.0:8080" # 서비스 리스닝 주소
  debug: false # 디버그 모드 활성화
  dsn: "" # mysql user:password@tcp(host:port)
  maxApnsClientCount: 1 # 최대 APNs 클라이언트 연결 수

apple: # Apple 푸시 알림 설정
  keyId: "BNY5GUGV38" # 키 ID
  teamId: "FUWV6U942Q" # 팀 ID
  topic: "me.uuneo.Meoworld" # 푸시 토픽
  develop: false # 개발 환경
  apnsPrivateKey: |- # APNs 개인 키
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgvjopbchDpzJNojnc
    o7ErdZQFZM7Qxho6m61gqZuGVRigCgYIKoZIzj0DAQehRANCAAQ8ReU0fBNg+sA+
    ZdDf3w+8FRQxFBKSD/Opt7n3tmtnmnl9Vrtw/nUXX4ldasxA2gErXR4YbEL9Z+uJ
    REJP/5bp
    -----END PRIVATE KEY-----
  adminId: "" # 관리자 ID

```

### 명령줄 매개변수

설정 파일 외에도 명령줄 매개변수나 환경 변수를 사용하여 서비스를 구성할 수 있습니다:

| 매개변수 | 환경 변수 | 설명 | 기본값 |
|---------|----------|------|--------|
| `--addr` | `PB_SERVER_ADDR` | 서버 리스닝 주소 | 비어있음 |
| `--config`, `-c` | `PB_SERVER_CONFIG` | 설정 파일 경로 | `/data/config.yaml` |
| `--dsn` | `PB_SERVER_DSN` | MySQL DSN | 비어있음 |
| `--maxApnsClientCount`, `-max` | `PB_MAX_APNS_CLIENT_COUNT` | 최대 APNs 클라이언트 수 | 0（제한 없음） |
| `--debug` | `PB_DEBUG` | 디버그 모드 활성화 | false |
| `--develop`, `-dev` | `PB_DEVELOP` | 푸시 개발 모드 활성화 | false |
| `--user`, `-u` | `PB_USER` | 서버 사용자 이름 | 비어있음 |
| `--password`, `-p` | `PB_PASSWORD` | 서버 비밀번호 | 비어있음 |

명령줄 매개변수는 설정 파일보다 우선순위가 높으며, 환경 변수는 명령줄 매개변수보다 우선순위가 높습니다.

## Docker 배포

```shell
docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  sanvx/pushback:latest
```

## Docker-compose 배포
* 프로젝트의 `/deploy` 폴더를 서버에 복사한 후 다음 명령을 실행합니다.
* 선택적으로 `config.yaml` 설정 파일을 구성할 수 있으며, 설정 항목은 필요에 따라 수정할 수 있습니다.

* 시작
```shell
docker-compose up -d
```

## 수동 배포

1. 플랫폼에 따라 실행 파일 다운로드:<br> <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a><br>
또는 직접 컴파일:<br>
<a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. 실행
---
```
./main
```

## 기타

1. 앱은 <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>을 서버로 전송할 책임이 있습니다.<br>서버가 푸시 요청을 수신하면 Apple 서버로 푸시를 전송합니다. 그 후 휴대폰이 푸시 알림을 수신합니다.

2. 서버 코드: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. 앱 코드: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

