*[BARK](https://github.com/Finb/Bark) 오픈 소스 프로젝트에 감사드립니다.*

## Docker-Compose  
* 구성  

```yaml  
system: # 시스템 설정
  name: "Pushback" # 서비스 이름
  user: "" # 서비스 사용자 이름
  password: "" # 서비스 비밀번호
  host: "0.0.0.0" # 서비스 주소
  port: "8180" # 서비스 포트
  mode: "release" # debug, release
  dbType: "default" # 데이터베이스 유형
  dbPath: "./" # 데이터베이스 파일 경로
  hostName: "https://push.uuneo.com" # 서비스 도메인

mysql: # 데이터베이스 설정
  host: "localhost"
  port: "3306"
  user: "root"
  password: "root"

apple: # 애플 푸시 설정
  keyId: "BNY5GUGV38"
  teamId: "FUWV6U942Q"
  topic: "me.uuneo.Meoworld"
  develop: true # 푸시 프로그램 모드
  adminId: "" # 관리자 ID
  apnsPrivateKey: 

```
## Docker 배포  


```shell
docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  neouu/pushback:latest
```

## Docker-compose 배포  
* 프로젝트의 `/deploy` 폴더를 서버로 복사한 후, 아래 명령어를 실행하세요.  
* `/data/config.yaml` 구성 파일이 반드시 있어야 하며, 그렇지 않으면 서비스가 시작되지 않습니다. 필요에 따라 파일의 구성 옵션을 수정할 수 있습니다.

* 시작  
```shell  
docker-compose up -d 
```

## 수동 배포

1. 플랫폼에 맞는 실행 파일 다운로드:  
   <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a>  
   또는 직접 컴파일:  
   <a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. 실행  
```sh
./binary-file-name -c config.yaml
```
3. 필요 시  
```sh
chmod +x binary-file-name
```
`pushback-server`는 반드시 구성 파일을 지정하여 실행해야 합니다.


## 기타

1. 앱 측에서 <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>을 서버로 전송해야 합니다. <br>서버가 푸시 요청을 받으면 Apple 서버로 푸시 알림을 전송하며, 이후 휴대폰이 푸시 알림을 수신합니다.

2. 서버 측 코드: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. 앱 코드: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>
