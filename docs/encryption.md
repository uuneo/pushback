
 *感谢[BARK](https://github.com/Finb/Bark) 的开源项目*

#### 什么是推送加密

推送加密是一种保护推送内容的方法，它使用自定义秘钥在发送和接收时对推送内容进行加密和解密。<br>这样，推送内容在传输过程中就不会被 pushback 服务器和苹果 APNs 服务器获取或泄露。

#### 设置自定义秘钥
1. 打开APP首页
2. 找到 “推送加密” ，点击加密设置
3. 选择加密算法，按要求填写KEY，点击完成保存自定义秘钥

#### 发送加密推送
要发送加密推送，首先需要把 pushback 请求参数转换成 json 格式的字符串，然后用之前设置的秘钥和相应的算法对字符串进行加密，最后把加密后的密文作为ciphertext参数发送到服务器。<br><br>
**示例：**
```python
# Documentation: "https://pushback.uuneo.com/#/encryption"
# python demo: 使用AES加密数据，并发送到服务器
# pip3 install pycryptodome
# 下面只是一种加密的示例，使用时请在app内直接复制

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


# JSON数据
json_string = json.dumps({"body": "test", "sound": "birdsong"})

# 必须32位 这是一个示例
key = b"BxXqdEFEuALb4SGJMQ5zm2fJLrRIz83R"
# IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。
iv= b"BipwZliixOcJDOz8"

# 加密
# 控制台将打印 "Qmlwd1psaWl4T2NKE2CTw4aoH2dGiJ2G0G39EbOK3IiKhxm6URNmqRBDlTh1U1CEoAaeX/zD+vygVi68wnKh3iI="
encrypted_data = encrypt_aes_mode(json_string, key, iv[:12])

# 将加密后的数据转换为Base64编码
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("加密后的数据（Base64编码", encrypted_base64)

deviceKey = '2uvg28SiADdcrXH46f4xmP'

res = requests.get(f"https://push.uuneo.com/{deviceKey}/test", params = {"ciphertext": encrypted_base64})

print(res.text)

```