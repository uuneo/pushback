
 *Thanks to [BARK](https://github.com/Finb/Bark) for the open-source project*

#### What is Push Encryption

Push encryption is a method to protect push content by using a custom secret key to encrypt and decrypt the content during transmission. <br> This way, the push content will not be accessed or leaked by the pushback server or Apple APNs server during transmission.

#### Setting up a Custom Secret Key
1. Open the app's homepage.
2. Find "Push Encryption" and click on the encryption settings.
3. Select the encryption algorithm, enter the key as required, and click "Finish" to save the custom secret key.

#### Sending Encrypted Push Notifications
To send an encrypted push, first convert the pushback request parameters into a JSON formatted string, then encrypt the string using the secret key and the selected algorithm. Finally, send the encrypted ciphertext as the `ciphertext` parameter to the server. <br><br>
**Example:**
```python
# Documentation: "https://pushback.uuneo.com/#/en-us/encryption"
# Python demo: Encrypt data using AES and send it to the server
# pip3 install pycryptodome
# The following is just an encryption example, use it directly in the app

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


# JSON data
json_string = json.dumps({"body": "test", "sound": "birdsong"})

# Must be 32 bytes, this is an example
key = b"BxXqdEFEuALb4SGJMQ5zm2fJLrRIz83R"
# IV can be randomly generated, but if it is random, it needs to be passed in the iv parameter.
iv= b"BipwZliixOcJDOz8"

# Encryption
# The console will print "Qmlwd1psaWl4T2NKE2CTw4aoH2dGiJ2G0G39EbOK3IiKhxm6URNmqRBDlTh1U1CEoAaeX/zD+vygVi68wnKh3iI="
encrypted_data = encrypt_aes_mode(json_string, key, iv[:12])

# Convert the encrypted data to Base64 encoding
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("Encrypted data (Base64 encoded):", encrypted_base64)

deviceKey = '2uvg28SiADdcrXH46f4xmP'

res = requests.get(f"https://push.uuneo.com/{deviceKey}/test", params={"ciphertext": encrypted_base64})

print(res.text)
```
