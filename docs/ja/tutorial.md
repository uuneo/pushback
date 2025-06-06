*オープンソースプロジェクト [BARK](https://github.com/Finb/Bark) に感謝します。*

## プッシュ通知の送信
1. アプリを開き、テストURLをコピーします。

<img src="../_media/example.jpeg" width=365 />

2. コンテンツを変更し、このURLにリクエストを送信します。<br>
GETまたはPOSTリクエストを送信できます。リクエストが成功すると、即座にプッシュ通知が送信されます。<br>
Barkとの違い: パラメータの優先順位 【POST > GET > URLパラメータ】。POSTパラメータはGETパラメータを上書きし、GETパラメータはURLパラメータを上書きします。

## URLフォーマット
URLはプッシュキー、`title`パラメータ、`body`パラメータで構成されます。以下の2つの組み合わせフォーマットがあります：

```
https://push.uuneo.com/:key/:body 
https://push.uuneo.com/:key/:title/:body 
https://push.uuneo.com/:key/:title/:subtitle/:body

```

## リクエスト方法
##### GETリクエスト
パラメータはURLに追加されます。例：
```sh
curl https://push.uuneo.com/your_key/PushContent?group=GroupName&copy=CopyText
```
*パラメータを手動でURLに追加する場合は、適切なURLエンコーディングを確保してください。[FAQ: URLエンコーディング](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc) を参照してください。*

##### POSTリクエスト
パラメータはリクエストボディに配置されます。例：
```sh
curl -X POST https://push.uuneo.com/your_key \
     -d'body=PushContent&group=GroupName&copy=CopyText'
```
##### POSTリクエストはJSONをサポートします。例：
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

##### JSONリクエストキーはリクエストボディに含めることができ、URLパスは`/push`でなければなりません。例：
```sh
curl -X "POST" "https://push.uuneo.com/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test pushback Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```
## リクエストパラメータ
サポートされているパラメータのリストです。具体的な効果はアプリ内でプレビューできます。
すべてのパラメータは以下のような様々な書き方をサポートしています：SubTitle / subTitle / subtitle / sub_title / sub-title /

| パラメータ | Bark | Pushback 使用の違い |
| ----- | ----------- | ----------- |
| id | なし | UUID、同じidを渡すと既存のメッセージを上書きします |
| title | プッシュタイトル | 同じ |
| subtitle | プッシュサブタイトル | 同じ |
| body | プッシュ内容 | 同じ（content/message/data/text を body の代替としてサポート） |
| markdown | サポートなし | Markdownをレンダリング（md の略記をサポート） |
| level | プッシュ中断レベル。<br>**active**：デフォルト値、システムは即座に画面を点灯して通知を表示<br>**timeSensitive**：時限性通知、フォーカスモード中に表示可能<br>**passive**：通知リストにのみ追加、画面点灯なし<br>**critical**：重要通知、フォーカスモードまたはサイレントモード中に通知可能 | 互換性あり。パラメータは数字で代替可能：`level=1`<br>0：passive<br>1：active<br>2：timeSensitive<br>3...10：critical、このモードでは数字が音量に使用されます（`level=3...10`） |
| volume | `level=critical` モードでの音量、範囲 0...10 | 同じ |
| call | 長い通知、WeChatの通話通知に類似 | 同じ |
| badge | プッシュバッジ、任意の数字を指定可能 | 未読数に基づいて計算 |
| autoCopy | iOS 14.5以下でプッシュ内容を自動コピー、iOS 14.5以上では長押しまたはプルダウンが必要 | 本アプリ iOS 16+ |
| copy | プッシュをコピーする際に、コピーする内容を指定。指定しない場合はプッシュ全体をコピー | 同じ |
| sound | プッシュに異なる着信音を設定可能 | アプリ内でデフォルト着信音を設定可能 |
| icon | プッシュにカスタムアイコンを設定、アイコンは自動的にキャッシュ | 同じ、クラウドアイコンのアップロードもサポート |
| image | 画像URLを渡すと、受信時に自動的にダウンロードしてキャッシュ | 同じ |
| savealbum | サポートなし | "1"を渡すと画像を自動的にアルバムに保存 |
| group | メッセージをグループ化、プッシュは通知センターで `group` ごとに表示<br>履歴メッセージリストで異なるグループを表示可能 | 互換性あり |
| isArchive | `1` を渡すとプッシュを保存、他の値を渡すと保存しない、指定しない場合はアプリ設定に従う | `ttl=日数` を使用 |
| url | プッシュをクリックした際にジャンプするURL、URL SchemeとUniversal Linkをサポート | 同じ |
