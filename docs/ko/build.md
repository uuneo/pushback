*[BARK](https://github.com/Finb/Bark) 오픈 소스 프로젝트에 감사드립니다*  
## 소스 코드 다운로드  
GitHub에서 소스 코드를 다운로드하세요: [pushback](https://github.com/uuneo/pushbackServer)  
또는 다음 명령어를 사용하세요:  
```sh  
git clone https://github.com/uuneo/pushbackServer.git 
```

## 종속성 구성  
- Golang 1.18+  
- Go Mod (env GO111MODULE=on)  
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)  

## 모든 플랫폼에 대한 크로스 컴파일  
```sh  
# Linux AMD 버전  
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main.go  
# 로컬에서 컴파일 및 실행  
go build -o main.go  
# 다른 플랫폼의 경우 ChatGPT에 문의하세요  
```
