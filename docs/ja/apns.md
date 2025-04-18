
 *[BARK](https://github.com/Finb/Bark) オープンソースプロジェクトに感謝します*  
### APNSインターフェースを直接呼び出す
デバイスのDeviceToken（アプリ内で取得可能）がある場合、サーバーを追加せずにAppleのAPNSインターフェースを呼び出して、デバイスにプッシュ通知を直接送信できます。<br>
以下はコマンドラインを使用してプッシュ通知を送信する例です：

```shell
# 環境変数を設定
# キーファイルをダウンロード https://github.com/uuneo/pushbackServer/tree/main/deploy/pushback.p8
# 以下にキーファイルのパスを記入
TOKEN_KEY_FILE_NAME=
# アプリ設定からDeviceTokenをコピーしてここに記入
DEVICE_TOKEN=

# 以下は変更しないでください
TEAM_ID=FUWV6U942Q
AUTH_KEY_ID=BNY5GUGV38
TOPIC=me.uuneo.Meoworld
APNS_HOST_NAME=api.push.apple.com

# トークンを生成
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# 可能であれば、このトークンをキャッシュするようスクリプトを改善してください。同じトークンを30分以内に再利用し、30分ごとに再生成してください。
# Appleのドキュメントでは、トークン生成の最小間隔は20分、最大有効期間は60分とされています。
# 頻繁な再生成は失敗する可能性があり、1時間以上経過したトークンは機能しません。
# 非公式なテストに基づくと、短い間隔での生成でも動作する場合がありますが、注意が必要です。
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

# プッシュ通知を送信
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}

```
### プッシュペイロード形式
https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification を参照してください<br>
`"mutable-content": 1` を含めることを確認してください。これがないとプッシュ通知拡張が実行されず、通知が保存されません。<br>

例:
```js
{
    "aps": {
        "mutable-content": 1,
        "alert": {
            "title": "タイトル",
            "body": "本文"
        },
        "category": "myNotificationCategory",
        "sound": "minuet.caf"
    },
    "icon": "https://day.app/assets/images/avatar.jpg"
}
```