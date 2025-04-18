*オープンソースプロジェクト [BARK](https://github.com/Finb/Bark) に感謝します*

## Docker-Compose  
* 設定  

```yaml  
system: # システム設定
  name: "Pushback" # サービス名
  user: "" # サービスユーザー名
  password: "" # サービスパスワード
  host: "0.0.0.0" # サービスアドレス
  port: "8180" # サービスポート
  mode: "release" # debug, release
  dbType: "default" # データベースタイプ
  dbPath: "./" # データベースファイルパス
  hostName: "https://push.uuneo.com" # サービスドメイン

mysql: # データベース設定
  host: "localhost"
  port: "3306"
  user: "root"
  password: "root"

apple: # Appleプッシュ設定
  keyId: "BNY5GUGV38"
  teamId: "FUWV6U942Q"
  topic: "me.uuneo.Meoworld"
  develop: true # プッシュプログラムのモード
  adminId: "" # 管理者ID
  apnsPrivateKey:  

```
## Docker デプロイ  


```shell
docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  neouu/pushback:latest
```

## Docker-compose デプロイ  
* プロジェクトの `/deploy` フォルダをサーバーにコピーし、以下のコマンドを実行してください。  
* `/data/config.yaml` 設定ファイルが必要です。設定ファイルがない場合、サービスは起動しません。必要に応じてファイル内の設定オプションを変更できます。

* 起動  
```shell  
docker-compose up -d 
```

## 手動デプロイ

1. プラットフォームに基づいて実行ファイルをダウンロードしてください:  
   <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a>  
   または自分でコンパイルしてください:  
   <a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. 実行  
```sh
./binary-file-name -c config.yaml
```
3. 必要に応じて  
```sh
chmod +x binary-file-name
```
`pushback-server` は設定ファイルを指定して実行する必要があることに注意してください。


## その他

1. アプリ側は <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a> をサーバーに送信する責任があります。<br>サーバーがプッシュリクエストを受信すると、Apple のサーバーにプッシュ通知を送信します。その後、電話がプッシュ通知を受信します。

2. サーバー側コード: <a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. アプリコード: <a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

