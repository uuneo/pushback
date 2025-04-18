*オープンソースプロジェクト [BARK](https://github.com/Finb/Bark) に感謝します*  
## ソースコードのダウンロード  
GitHubからソースコードをダウンロードしてください: [pushback](https://github.com/uuneo/pushbackServer)  
または以下を使用してください:  
```sh  
git clone https://github.com/uuneo/pushbackServer.git 
```

## 依存関係の設定  
- Golang 1.18+  
- Go Mod (環境変数 GO111MODULE=on)  
- Go Mod Proxy (環境変数 GOPROXY=https://goproxy.cn)  

## 全プラットフォーム向けのクロスコンパイル  
```sh  
# Linux AMDバージョン  
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main.go  
# ローカルでコンパイルして実行  
go build -o main.go  
# 他のプラットフォームについては、ChatGPTに相談してください  
```
