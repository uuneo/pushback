
 *[BARK](https://github.com/Finb/Bark) 오픈 소스 프로젝트에 감사드립니다.*

#### 푸시 암호화란 무엇인가요?

푸시 암호화는 사용자 지정 비밀 키를 사용하여 전송 중에 콘텐츠를 암호화하고 복호화함으로써 푸시 콘텐츠를 보호하는 방법입니다. <br> 이를 통해 푸시 콘텐츠는 전송 중에 Pushback 서버나 Apple APNs 서버에 의해 액세스되거나 유출되지 않습니다.

#### 사용자 지정 비밀 키 설정하기
1. 앱의 홈페이지를 엽니다.
2. "푸시 암호화"를 찾아 암호화 설정을 클릭합니다.
3. 암호화 알고리즘을 선택하고, 요구된 대로 키를 입력한 후 "완료"를 클릭하여 사용자 지정 비밀 키를 저장합니다.

#### 암호화된 푸시 알림 보내기
암호화된 푸시를 보내려면 먼저 Pushback 요청 매개변수를 JSON 형식의 문자열로 변환한 다음, 비밀 키와 선택한 알고리즘을 사용하여 문자열을 암호화합니다. 마지막으로 암호화된 암호문을 `ciphertext` 매개변수로 서버에 전송합니다. <br><br>
**예제:**
```python
# Documentation: "https://pushback.uuneo.com/#/ko/encryption"
# python demo: AES 암호화를 사용하여 데이터를 서버에 보냅니다
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


# JSON 데이터
json_string = json.dumps({"title": "이것은 암호화 예제입니다","body": "이것은 암호화된 메시지의 본문입니다", "sound": "typewriter"})

# 필수 32자리
key = b"Jo9XV9b9NghP2JmDivrBbNOoJmofSPt0"
# IV는 무작위로 생성할 수 있지만, 무작위인 경우 iv 매개변수로 전달해야 합니다.
iv= b"sviYoOkg0z9hpp1I"

# 암호화
encrypted_data = encrypt_aes_mode(json_string, key, iv[:12])

# 암호화된 데이터를 Base64 인코딩으로 변환
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("암호화된 데이터 (Base64 인코딩)", encrypted_base64)

deviceKey = 'chao'

res = requests.get(f"https://dev.uuneo.com/{deviceKey}/test", params = {"ciphertext": encrypted_base64})

print(res.text)
```

