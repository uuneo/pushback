*[BARK](https://github.com/Finb/Bark) 오픈 소스 프로젝트에 감사드립니다.*

#### 개인 정보가 침해될 수 있는 방법 <!-- {docsify-ignore-all} -->

푸시 알림이 전송에서 수신까지의 경로는 다음과 같습니다:<br>
발신자 <font color='red'> → 서버①</font> → Apple APNS 서버 → 사용자의 기기 → <font color='red'>pushback 앱②</font>.

개인 정보는 빨간색으로 표시된 두 지점에서 잠재적으로 침해될 수 있습니다: <br>
* 발신자가 HTTPS를 사용하지 않거나 공용 서버를 사용하는 경우 (작성자가 요청 로그를 볼 수 있음).*
* pushback 앱 자체가 안전하지 않거나, App Store에 업로드된 버전이 수정된 경우.

#### 서버 측 개인 정보 문제 해결
* 오픈 소스 백엔드 코드를 사용하여 [백엔드 서비스를 배포](/deploy.md)하고 HTTPS를 활성화할 수 있습니다.
* 사용자 정의 키를 사용하여 [암호화된 푸시 알림](/encryption)을 통해 알림 내용을 암호화하세요.

#### 앱이 완전히 오픈 소스 코드로 빌드되었는지 확인
앱이 안전하고 작성자를 포함한 누구에 의해서도 수정되지 않았음을 보장하기 위해 pushback은 GitHub Actions를 통해 빌드된 후 App Store에 업로드됩니다.<br>
pushback 앱 설정에서 GitHub Run ID를 확인할 수 있으며, 이를 통해 컴파일 시 사용된 구성 파일, 소스 코드, App Store에 업로드된 버전의 빌드 번호를 확인할 수 있습니다.<br>

같은 버전의 빌드 번호는 App Store에 한 번만 업로드될 수 있으므로 고유합니다.<br>
이 번호를 사용하여 App Store에서 다운로드한 pushback 앱과 비교할 수 있습니다. 번호가 일치하면 App Store에서 다운로드한 앱이 완전히 오픈 소스 코드로 빌드되었음을 증명합니다.

예: pushback 1.2.9 - 3<br> 
https://github.com/uuneo/pushback/actions/runs/3327969456

1. 컴파일 시 사용된 커밋 ID를 찾아 컴파일 당시의 전체 소스 코드를 확인합니다.
2. `.github/workflows/testflight.yaml`을 확인하여 모든 작업을 검증하고 작업에서 출력된 로그가 변조되지 않았는지 확인합니다.
3. 작업 로그 보기: https://github.com/uuneo/pushback/actions/runs/3327969456/jobs/5503414528
4. 로그에서 App ID, Team ID, App Store에 업로드된 버전 및 빌드 번호를 찾습니다.
5. 스토어에서 해당 버전의 IPA를 다운로드하고 로그와 빌드 번호를 비교하여 일치하는지 확인합니다 *(이 번호는 동일한 버전의 앱에 대해 고유하며, 성공적으로 업로드된 후에는 재사용할 수 없습니다)*.

*iOS 자체가 개인 정보를 침해하는지 여부는 고려하지 않습니다.*
