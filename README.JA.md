日本語 | **[English](README.EN.md)** | **[中文](README.md)** | **[한국어](README.KO.md)**


> [!IMPORTANT]
>
>- プロジェクトの一部のコードは [Bark](https://github.com/Finb/Bark) から派生しています
>
> - Markdown スタイリング（完了）
> - 着信音の自動変換（完了）
> - メッセージ内容の読み上げ（ベータ版）（完了）


<p align="center">
<img src="/docs/_media/egglogo.png" alt="pushback" title="pushback" width="100"/>
</p>


# Pushback
![IOS](https://img.shields.io/badge/IPhone-16+-ff69b4.svg) ![IOS](https://img.shields.io/badge/IPad-16+-ff69b4.svg) ![Markdown](https://img.shields.io/badge/gcm-markdown-green.svg)
### Apple デバイスにカスタム通知をプッシュできる iOS アプリケーション
[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="Pushback App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR)
[<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Pushback App" height="40">](https://apps.apple.com/us/app/pushback-push-to-phone/id6615073345)

## 問題フィードバック Telegram グループ
[Pushback フィードバックグループ](https://t.me/+pmCp6gWuAzFjYWQ1)

## ドキュメント
[ドキュメントを表示](https://uuneo.github.io/pushback)


## 使い方
1. アプリを開いてテストURLをコピーします

<img src="/docs/_media/example.jpeg" width=365 />

2. 内容を変更してこのURLにリクエストを送信します
```
GETまたはPOSTリクエストを送信でき、成功するとすぐにプッシュ通知を受け取ります。

URLの構造：最初の部分がキーで、その後に3つのマッチパターンがあります
/:key/:body 
/:key/:title/:body 
/:key/:title/:subtitle/:body 

title: プッシュのタイトル、本文より少し大きい文字サイズ
subtitle: プッシュのサブタイトル
body: プッシュの内容、改行には '\n' を使用
POSTリクエストの場合、パラメータ名は上記と同じです
```

## Parameters

* body 
```
// content ｜ message ｜ data ｜ text | == body
https://push.uuneo.com/yourkey/?body=Test
https://push.uuneo.com/yourkey/?content=Test
                                            ...
``

* Markdown
```
// プッシュ通知がMarkdownをレンダリングします
https://push.uuneo.com/yourkey/?markdown=%23%20Pushback%0A%23%23%20Pushback%0A%23%23%23%20Pushback
```

* url
```
// プッシュ通知をクリックして指定されたURLにジャンプします
https://push.uuneo.com/yourkey/url?url=https://www.google.com 
```
* ttl
```
// ttl = 日数、0を渡すと保存しない。指定しない場合はアプリの内部設定に従います
https://push.uuneo.com/yourkey/message-saveduration?ttl=0
```
* group
```
// プッシュメッセージのグループを指定して、グループごとにプッシュを表示できます。
https://push.uuneo.com/yourkey/group?group=groupName
```
* icon
```
// プッシュメッセージのアイコンを指定します
https://push.uuneo.com/yourkey/icon?icon=https://pushback.uuneo.com/_media/avatar.png
```
* image
```
// プッシュメッセージの画像を指定します。画像は自動的にアルバムに保存されます
https://push.uuneo.com/yourkey/icon?image=https://pushback.uuneo.com/_media/avatar.png
```

* sound
```
// プッシュメッセージの音声を指定します
https://push.uuneo.com/yourkey/sound?sound=alarm
```
* call
```
// 30秒間音声を繰り返し再生します
https://push.uuneo.com/yourkey/call?call=1
```
* ciphertext
```
// 暗号化されたプッシュメッセージ
https://push.uuneo.com/yourkey/ciphertext?ciphertext=
```
* level
```
// 通知レベルを設定し、時間に敏感な通知を設定します
https://push.uuneo.com/yourkey/Timeliness notice?level=timeSensitive

// オプションパラメータ値として level = 1...10 も使用可能です。音量は level より優先度が高いです
// passive(0): 画面を点灯せずに通知リストに通知を追加します
// active(1): 設定されていない場合のデフォルト値で、システムは即座に画面を点灯して通知を表示します
// timeSensitive(2): 時間に敏感な通知で、フォーカスモード中も表示可能です
// critical(3-10): 重要通知（0.3から1までの音量も表します）
```

## Safari/Chrome拡張機能
 * Safari拡張機能はインストール不要で、アプリに付属しています
 * ブラウザからテキスト、画像、リンクを直接スマートフォンに送信します
 * 拡張機能はInstagramの画像URLをスマートフォンに送信し、自動的にアルバムに保存されます
 * [Chrome拡張機能をインストール](https://chromewebstore.google.com/detail/pushback/gadgoijjifgnbeehmcapjfipggiijeej)



## プロジェクトで使用されているサードパーティライブラリ
- [Defaults](https://github.com/sindresorhus/Defaults)
- [QRScanner](https://github.com/mercari/QRScanner)
- [realm](https://github.com/realm/realm-swift)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [OpenAI](https://github.com/MacPaw/OpenAI)
- [Splash](https://github.com/AugustDev/Splash)
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)



