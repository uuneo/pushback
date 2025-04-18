
*Thanks to [BARK](https://github.com/Finb/Bark) for the open-source project*

#### Unable to Receive Push Notifications
Check if the Device Token is normal in the app settings. If it's not normal, refer to [here](#DeviceToken显示未知).<br/>
If it's normal, try restarting the device. If you still can't receive the push notification, check if the push request returns a status code of 200.<br/>
If everything looks normal but the issue persists, you can report it in the [Bark feedback group](https://t.me/joinchat/OsCbLzovUAE0YjY1).

#### Device Token Shows as Unknown
This is likely because the device is not properly connected to the Apple server, which might also affect iMessage and other app notifications.<br/>
You can try switching networks, restarting your phone, or if you're using a VPN for Apple services, try disabling the VPN.<br/>
This issue is related to the connection between the user's device and Apple’s servers. The author cannot provide assistance, and you will need to resolve it yourself.

#### Push Notification Request Limits
Normal requests (HTTP status code 200) have no restrictions.<br>
However, if there are more than 1000 failed requests (HTTP status codes 400, 404, 500) within 5 minutes, the <b>IP will be banned for 24 hours</b>.

#### Receiving Unknown Push Notifications (e.g., NoContent)
Possible reasons:<br>
1. If you sent a push using Safari, when you input any URL, Safari may auto-complete the history search and match the Bark API URL, triggering a pre-load push notification.
2. If you sent the Bark API URL to a chat app like WeChat's file transfer assistant, WeChat might occasionally send requests to the URL and trigger a push.
3. Push Key leak – It’s recommended to reset the Key on the server list page.

#### Expired Notifications Not Working
Try <b>restarting the device</b> to resolve this issue.

#### Cannot Save Notification History, or Can't Copy from Pull-Down Notification
Try <b>restarting the device</b>.<br />
This may happen due to an issue with the push service extension ([UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)), which prevents the code for saving notifications from running properly.

#### Auto-Copy Push Notifications Not Working
After iOS 14.5, due to tighter permissions, it's no longer possible to automatically copy the push content to the clipboard upon receiving a notification.<br/>
You can temporarily pull down the notification or swipe left on the lock screen to view and automatically copy the content, or click the push notification's copy button.

#### Default Notification History List
When you open the app again, it will jump to the last opened page.<br />
Simply exit the app while on the history message page, and the next time you open the app, it will show the history page.

#### Does the Push API Support POST Requests?
Pushback supports both GET and POST requests and also supports JSON.<br>
The parameter names are the same regardless of the request method, refer to [Usage Tutorial](/tutorial#请求方式).

#### Push Failure Due to Special Characters in the Push Content, such as URLs, or Push Anomalies (e.g., + turns into a space)
This issue occurs because the entire URL is not formatted properly, and it commonly happens when manually constructing URLs.<br>
When constructing a URL, make sure to URL-encode the parameters.

```sh
# Example
https://push.uuneo.com/key/{push_content}

# If {push_content} is
"a/b/c/"

# The final URL will be
https://push.uuneo.com/key/a/b/c/
# This will return a 404 error because it can’t find the correct route.

# Instead, URL-encode {push_content} before appending
https://push.uuneo.com/key/a%2Fb%2Fc%2F

```
If you are using a mature HTTP library, the parameters will be automatically handled, and you won’t need to manually encode them.<br>
However, if you are manually constructing the URL, pay extra attention to special characters in the parameters. **It's best to URL-encode the parameters regardless of whether they contain special characters.**

#### How to Ensure Privacy and Security
Refer to [Privacy and Security](/privacy)
