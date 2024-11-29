*Thanks to the [BARK](https://github.com/Finb/Bark) open-source project.*

#### How Privacy Can Be Compromised <!-- {docsify-ignore-all} -->

The route of a push notification from sending to receiving is as follows:<br>
Sender <font color='red'> → Server①</font> → Apple APNS Server → Your Device → <font color='red'>pushback APP②</font>.

Privacy can potentially be compromised at the two red-marked points: <br>
* The sender does not use HTTPS or uses a public server (the author could see the request logs).*
* The pushback App itself is insecure, or the version uploaded to the App Store has been modified.

#### Resolving Server-Side Privacy Issues
* You can use the open-source backend code to [deploy your backend service](/deploy.md) and enable HTTPS.
* Use [encrypted push notifications](/encryption) with custom keys to encrypt the notification content.

#### Ensuring the App Is Built Entirely from Open-Source Code
To ensure the App is secure and unmodified by anyone (including the author), pushback is built by GitHub Actions and then uploaded to the App Store.<br>
In the pushback App settings, you can find the GitHub Run ID, which links to the configuration files, source code used during compilation, and the build number of the version uploaded to the App Store.<br>

The build number for the same version can only be uploaded to the App Store once, making it unique.<br>
You can use this number to compare with the pushback App downloaded from the store. If they match, it proves the App downloaded from the App Store is entirely built from open-source code.

Example: pushback 1.2.9 - 3<br> 
https://github.com/uuneo/pushback/actions/runs/3327969456

1. Find the commit ID used during compilation to view the complete source code at the time of compilation.
2. Check `.github/workflows/testflight.yaml` to verify all actions and ensure that the logs printed by the actions were not tampered with.
3. View the Action Logs: https://github.com/uuneo/pushback/actions/runs/3327969456/jobs/5503414528
4. Find the App ID, Team ID, the version uploaded to the App Store, and the build number in the logs.
5. Download the corresponding version IPA from the store and compare the build number with the logs to ensure they match *(this number is unique to the same version of the App and cannot be reused once successfully uploaded)*.

*This does not consider whether iOS itself compromises privacy.*
