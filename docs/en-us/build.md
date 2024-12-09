*Thanks to the [BARK](https://github.com/Finb/Bark) open-source project*  
## Download Source Code  
Download the source code from GitHub: [pushback](https://github.com/uuneo/pushbackServer)  
Or use:  
```sh  
git clone https://github.com/uuneo/pushbackServer.git 
```

## Configure Dependencies  
- Golang 1.18+  
- Go Mod (env GO111MODULE=on)  
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)  

## Cross-Compile for All Platforms  
```sh  
# Linux AMD version  
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main.go  
# Compile and run locally  
go build -o main.go  
# For other platforms, ask ChatGPT  
