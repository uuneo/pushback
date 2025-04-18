
 *Thanks to the [BARK](https://github.com/Finb/Bark) open-source project*  
### Directly Call APNS Interface
If you have the DeviceToken of a device (available in the app), you can call Apple's APNS interface to send push notifications directly to the device without adding a server to the app.<br>
Below is an example of sending a push notification via the command line:

```shell
# Set environment variables
# Download key https://github.com/uuneo/pushbackServer/tree/main/deploy/pushback.p8
# Fill in the path to the key file below
TOKEN_KEY_FILE_NAME=
# Copy DeviceToken from app settings here
DEVICE_TOKEN=

# Do not modify the following
TEAM_ID=FUWV6U942Q
AUTH_KEY_ID=BNY5GUGV38
TOPIC=me.uuneo.Meoworld
APNS_HOST_NAME=api.push.apple.com

# Generate TOKEN
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# If possible, improve the script to cache this Token. Reuse the same Token within 30 minutes, regenerate it every 30 minutes.
# Apple's documentation specifies a minimum interval of 20 minutes for generating Tokens, with a maximum validity of 60 minutes.
# Frequent regeneration may fail; Tokens older than 1 hour won't work.
# Based on my informal testing, short-interval generation may still work, but caution is advised.
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

# Send push notification
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}
```

### Push Payload Format
Refer to https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification<br>
Ensure to include `"mutable-content": 1`, otherwise the push notification extension won't execute, and the notification won't be saved.<br>

Example:
```js
{
    "aps": {
        "mutable-content": 1,
        "alert": {
            "title": "title",
            "body": "body"
        },
        "category": "myNotificationCategory",
        "sound": "minuet.caf"
    },
    "icon": "https://day.app/assets/images/avatar.jpg"
}
```