
 *[BARK](https://github.com/Finb/Bark) のオープンソースプロジェクトに感謝します*

#### プッシュ暗号化とは

プッシュ暗号化は、カスタム秘密鍵を使用して送信中のコンテンツを暗号化および復号化することで、プッシュコンテンツを保護する方法です。<br> この方法により、送信中にプッシュバックサーバーやApple APNsサーバーによってプッシュコンテンツがアクセスされたり漏洩したりすることを防ぎます。

#### カスタム秘密鍵の設定
1. アプリのホームページを開きます。
2. 「プッシュ暗号化」を見つけて暗号化設定をクリックします。
3. 暗号化アルゴリズムを選択し、必要に応じて鍵を入力し、「完了」をクリックしてカスタム秘密鍵を保存します。

#### 暗号化されたプッシュ通知の送信
暗号化されたプッシュを送信するには、まずプッシュバックリクエストパラメータをJSON形式の文字列に変換し、その文字列を秘密鍵と選択したアルゴリズムを使用して暗号化します。最後に、暗号化された暗号文を `ciphertext` パラメータとしてサーバーに送信します。<br><br>
**例示:**
```python
# ドキュメント: "https://pushback.uuneo.com/#/ja/encryption"
# python demo: AES暗号化を使用してデータをサーバーに送信
# pip3 install pycryptodome

import json
import base64
import requests
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

def encrypt_aes_mode(data, key, iv):
    cipher = AES.new(key, AES.MODE_GCM, iv)
    padded_data = data.encode()
    encrypted_data, tag = cipher.encrypt_and_digest(padded_data)
    return iv + encrypted_data + tag


# JSONデータ
json_string = json.dumps({"title": "これは暗号化の例です","body": "これは暗号化されたメッセージの本文です", "sound": "typewriter"})

# 32桁でなければなりません
key = b"Jo9XV9b9NghP2JmDivrBbNOoJmofSPt0"
# IVはランダムに生成できますが、ランダムの場合はivパラメータで渡す必要があります。
iv= b"sviYoOkg0z9hpp1I"

# 暗号化
encrypted_data = encrypt_aes_mode(json_string, key, iv[:12])

# 暗号化されたデータをBase64エンコーディングに変換
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("暗号化されたデータ (Base64エンコード)", encrypted_base64)

deviceKey = 'chao'

res = requests.get(f"https://dev.uuneo.com/{deviceKey}/test", params = {"ciphertext": encrypted_base64})

print(res.text)
```

