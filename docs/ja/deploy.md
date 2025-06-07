*[BARK](https://github.com/Finb/Bark)のオープンソースプロジェクトに感謝します*

## Docker-Compose 
* 設定

```yaml
system: # システム設定
  name: "pushback" # サービス名
  user: "" # サービスユーザー名
  password: "" # サービスパスワード
  address: "0.0.0.0:8080" # サービスリッスンアドレス
  debug: false # デバッグモードの有効化
  dsn: "" # mysql user:password@tcp(host:port)
  maxApnsClientCount: 1 # 最大APNsクライアント接続数

apple: # Appleプッシュ通知設定
  keyId: "BNY5GUGV38" # キーID
  teamId: "FUWV6U942Q" # チームID
  topic: "me.uuneo.Meoworld" # プッシュトピック
  develop: false # 開発環境
  apnsPrivateKey: |- # APNs秘密鍵
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgvjopbchDpzJNojnc
    o7ErdZQFZM7Qxho6m61gqZuGVRigCgYIKoZIzj0DAQehRANCAAQ8ReU0fBNg+sA+
    ZdDf3w+8FRQxFBKSD/Opt7n3tmtnmnl9Vrtw/nUXX4ldasxA2gErXR4YbEL9Z+uJ
    REJP/5bp
    -----END PRIVATE KEY-----
  adminId: "" # 管理者ID

```

### コマンドライン引数

設定ファイルに加えて、コマンドライン引数または環境変数を使用してサービスを設定することもできます：

| 引数 | 環境変数 | 説明 | デフォルト値 |
|------|----------|------|--------|
| `--addr` | `PB_SERVER_ADDR` | サーバーリッスンアドレス | 空 |
| `--config`, `-c` | `PB_SERVER_CONFIG` | 設定ファイルパス | `/data/config.yaml` |
| `--dsn` | `PB_SERVER_DSN` | MySQL DSN | 空 |
| `--maxApnsClientCount`, `-max` | `PB_MAX_APNS_CLIENT_COUNT` | 最大APNsクライアント数 | 0（制限なし） |
| `--debug` | `PB_DEBUG` | デバッグモードの有効化 | false |
| `--develop`, `-dev` | `PB_DEVELOP` | プッシュ開発モードの有効化 | false |
| `--user`, `-u` | `PB_USER` | サーバーユーザー名 | 空 |
| `--password`, `-p` | `PB_PASSWORD` | サーバーパスワード | 空 |

コマンドライン引数は設定ファイルよりも優先され、環境変数はコマンドライン引数よりも優先されます。

## Dockerデプロイ

```shell
docker run -d --name pushback-server -p 8080:8080 -v ./data:/data  --restart=always  sanvx/pushback:latest
```

## Docker-composeデプロイ
* プロジェクトの`/deploy`フォルダをサーバーにコピーし、以下のコマンドを実行します。
* オプションで`config.yaml`設定ファイルを設定できます。設定項目は必要に応じて変更できます。

* 起動
```shell
docker-compose up -d
```

## 手動デプロイ

1. プラットフォームに応じて実行ファイルをダウンロード：<br> <a href='https://github.com/uuneo/pushbackServer/releases'>https://github.com/uuneo/pushbackServer/releases</a><br>
または自分でコンパイル：<br>
<a href="https://github.com/uuneo/pushbackServer">https://github.com/uuneo/pushbackServer</a>

2. 実行
---
```
./main
```

## その他

1. アプリ側は<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>をサーバーに送信する責任があります。<br>サーバーがプッシュリクエストを受信すると、Appleサーバーにプッシュを送信します。その後、携帯電話がプッシュ通知を受信します。

2. サーバーコード：<a href='https://github.com/uuneo/pushbackServer'>https://github.com/uuneo/pushbackServer</a><br>

3. アプリコード：<a href="https://github.com/uuneo/pushback">https://github.com/uuneo/pushback</a>

