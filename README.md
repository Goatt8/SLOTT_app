# SLOTT_APP

<table>
<tr>
<td width="60%" valign="middle">

<img src="./assets/logo/logo.jpeg" width="120">

<h3>매 시간 슬롯에 기록하는 일상 공유 영상 소셜 플랫폼</h3>

<p><strong>SLOTT</strong>은 매 시간 슬롯에 짧은 일상 영상을 기록하고, 그룹 구성원들과 하루를 공유하는 영상 기반 소셜 브이로그 서비스입니다.</p>

<p>기존 텍스트·사진 중심 SNS를 넘어, 숏폼 영상을 활용해 친구들과 더 생생하고 몰입감 있는 일상을 교류할 수 있도록 설계했습니다.</p>

<p>
<a href="https://apps.apple.com/kr/app/slott/id6778327738">App Store로 이동</a>
</p>

<p>
<img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=Flutter&logoColor=white">
<img src="https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=Swift&logoColor=white">
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=Firebase&logoColor=black">
</p>

</td>
<td width="40%" align="center" valign="middle">

<img width= 60% src="https://github.com/user-attachments/assets/dd42c0d7-2318-437b-be88-7cd8c4ffa815" />


</td>
</tr>
</table>





_____________________
<br>






## 🛠 Tech Stack

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=Dart&logoColor=white) ![Swift](https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=Swift&logoColor=white) ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=Firebase&logoColor=black) ![iOS](https://img.shields.io/badge/iOS-000000?style=flat-square&logo=Apple&logoColor=white)

| Category | Tech Stack |
| :--- | :--- |
| **Platforms & Languages** | Flutter, Dart, Swift, iOS |
| **Backend & Auth** | Firebase Authentication, Cloud Firestore, Firebase Storage |
| **Push Notification** | Firebase Cloud Messaging, APNs, Cloud Functions |
| **Video & Media** | Flutter Camera, Cached Video Player, AVFoundation |
| **Native Integration** | Flutter MethodChannel, Swift Native Module, CocoaPods |
| **App Architecture** | Screen / Service / Model / Widget 구조 |
| **Distribution** | Xcode, IPA BUIld, Apple Transporter |

_____________________
<br>



## 주요 기능

#### :ballot_box_with_check: 로그인 및 인증시스템
- Firestore 휴대폰 번호 인증 기반 로그인
- 카카오톡 및 소셜 인증 로그인 (추후 업데이트)

#### :ballot_box_with_check: 슬롯 영상 공유
- 초대코드(groupID)를 입력해 그룹생성 및 참여
- 각 시간대별 쇼츠 영상 공유
- 개별 슬롯에 들어가는 사용자 폰트, 텍스트 컬러 커스터마이징
- 부적절한 영상 신고 및 유저 차단기능
- 00:00 ~ 24:00 하루 간 영상 하나의 비디오파일로 추출 시스템
- 그룹내 인원이 슬롯 업데이트 시 푸시알림 및 안읽음 버튼
- 영상에 대한 그룹별 대화방기능 및 좋아요 피드백 버튼 (추후 업데이트)


#### :ballot_box_with_check: 유저 프로필 커스텀
- 프로필 사진, 이름 재 커스텀 기능
- 앱 전체적인 key컬러 커스텀 (슬롯 텍스트, 폰트 커스터마이징과 연동)
- 앱 전체적인 테마 블랙/화이트 테마 선택, 현재는 블랙만 (추후 업데이트)



---------------------
<br>

## App Store 심사 대응 과정

<details>
<summary><strong>App Store 제출 심사 대응 과정</strong></summary>

- **플랫폼:** iOS (Apple App Store)
- **관련 가이드라인:** GUIdeline 1.2 - User Generated Content (사용자 생성 콘텐츠)
- **현상:** 앱 출시 심사 중, 사용자가 사진, 영상, 댓글 등을 공유할 수 있는 기능(UGC)이 존재함에도 불구하고 **부적절한 콘텐츠와 불량 사용자를 제한하기 위한 충분한 예방 조치(Precautions)가 부족하다**는 이유로 심사 거절(Reject) 처리가 됨.


<img width="70%" alt="image" src="https://github.com/user-attachments/assets/1d7f084e-4992-4b83-8fcb-47f3da80ab4c" />

<img width="70%" alt="image" src="https://github.com/user-attachments/assets/f2d514e5-6849-42bf-ad24-e5cdf6f87a23" />

### 📝 애플측의 피드백 - 누락요소

> 1. **EULA(이용약관) 명시 부족:** 가입 시 '개인정보 처리방침(Privacy)' 동의는 받았으나, 불량 유저 제재 방침이 담긴 'EULA(최종 사용자 라이선스 계약)' 동의 절차가 명확하지 않음.
> 2. **신고 및 차단 시스템 부재:** 부적절한 글을 피드에서 숨기거나 불량 유저를 차단하는 기능이 UI/UX 상에 구현되어 있지 않음.
> 3. **운영자 처리 프로세스 미비:** 신고된 콘텐츠를 24시간 이내에 검토 및 삭제하고, 불량 유저를 추방할 수 있는 명확한 정책과 시스템이 부재함.


### ① 정책 보완 (EULA 업데이트)

- 기존 약관에 해당 내용을 명시 추가 `SLOTT 이용약관 (Terms of Use / EULA)`
- **핵심 조항 명시 (6, 7, 17조):** 혐오, 음란, 저작권 침해 등 금지되는 콘텐츠의 기준을 명확히 정의함.
- **24시간 이내 처리 조치:** "타 사용자가 신고/차단한 콘텐츠에 대해 운영자가 **24시간 이내에 검토 후 삭제 및 유저 정지(추방)** 조치를 취한다"는 핵심 문구를 **국문**으로 추가함.
- 로그인 화면 진입부에 EULA 동의 체크박스를 노션(Notion) 링크와 함께 배치하여 유저가 가입 전 반드시 동의하도록 프로세스 구현.

### ② 앱 내 기능 구현 (기능 개발)

- **신고(Flag) 기능:** 게시글 및 댓글 영역에 신고 팝업 버튼을 추가하고, 신고 발생 시 서버(Firebase) 및 관리자 이메일로 해당 데이터(그룹명, 작성자, 사유 등)가 즉시 전송되도록 파이프라인 구축.
- **유저 차단(Block) 기능:** 부적절한 사용자를 차단할 수 있는 차단버튼 구현.
- **실시간 피드 숨김(Instant Removal):** 사용자가 '차단' 또는 '신고'를 누르는 즉시, 로컬 상태(State) 관리 및 서버 데이터 필터링을 통해 **해당 콘텐츠가 사용자의 피드에서 실시간으로 즉시 사라지도록 UX 구현** (애플의 핵심 요구사항 충족).

### ③ 심사 대응 (App Store Connect 제출) - 심사 성공

- 실물 iOS 기기(iPhone)를 활용하여 애플 심사관이 요구한 시나리오를 화면 녹화(Screen Recording)함.
    - *시나리오:* [가입 전 EULA 약관 확인 및 동의] ➡️ [피드 내 부적절한 콘텐츠 신고] ➡️ [불량 유저 차단 및 피드에서 즉시 숨겨지는 모습 시연]
- 해당 영상을 App Store Connect의 `App Review Information (Notes)` 영역에 첨부하고, 심사 피드백 메세지에 요구사항 완료 답변을 작성하여 재심사를 요청함.





</details>

____________
<br>

## 기술적 문제해결 과정

<details>
<summary><strong>1. 그룹 인원수에 따른 동적 슬롯 레이아웃</strong></summary>
    
> #### 문제
> SLOTT은 그룹 인원에 따라 2개부터 최대 10개의 영상 슬롯을 한 화면에 표시해야 했습니다. 모든 인원수에 동일한 UI 레이아웃을 적용하면 세로축이 지나치게 작아지거나 빈 공간이 발생했고, 영상의 가독성과 화면 활용도가 떨어졌습니다.

* ✅ AppLayoutPolicy 구현 : 그룹 인원수와 사용자가 선택한 보기 방식에 따라 레이아웃 설정을 반환하는 `AppLayoutPolicy`를 구현했습니다.
- 2~6명: 세로형 레이아웃 지원
- 3명, 4명, 6명: 세로형과 격자형 전환 지원
- 7~10명: 화면 활용도를 위해 격자형 레이아웃 적용
- 인원수에 따라 열 개수와 전체 슬롯 개수를 동적으로 결정
- 실제 인원이 없는 칸은 빈 슬롯으로 처리
- 레이아웃 계산과 화면 렌더링 로직을 분리하여 유지보수성 개선

```dart
static GroupUIPreset presetFor({
  reqUIred int memberCount,
  reqUIred bool useDiceLayout,
}) {
  final allowDice = supportsDiceLayout(memberCount);
  final allowVertical = supportsVerticalLayout(memberCount);
  final forceDice = isDiceOnlyMemberCount(memberCount);

  final willUseDice =
      forceDice ||
      (useDiceLayout && allowDice) ||
      (!allowVertical && allowDice);

  final layoutSpec = willUseDice
      ? diceSpecByMemberCount(memberCount)
      : verticalSpecByMemberCount(memberCount);

  return GroupUIPreset(
    layoutSpec: layoutSpec,
    // UI 설정 생략
  );
}
```
```
return layoutSpec.useGrid
    ? _bUIldGridLayout(...)
    : _bUIldVerticalLayout(...);
```

</details>
    
<details>
<summary><strong>2. 사용자 목록과 슬롯 소유권을 분리한 다중 슬롯 설계</strong></summary>

> #### 문제
> 초기에는 그룹의 `memberIds` 배열 순서를 기준으로 사용자의 슬롯 위치를 결정했습니다. 1인 1슬롯

```text
memberIds[0] → 0번 슬롯
memberIds[1] → 1번 슬롯
```

> 하지만 유저가 중복으로 들어가 각 슬롯을 원하는대로 커스텀 할 수 있다면 앱의 취지와도 잘맞고 더 다양한 창의성이 나올 수 있다는 생각이 들었습니다.


✅ slotOwnerIds, slotIndex
그룹 참여자 목록인 memberIds와 슬롯 소유권을 나타내는 slotOwnerIds를 분리했습니다.
또 slotIndex를 부여해 memberIds 순서로 위치가 강제되지않고, 원하는 슬롯칸에 유저가 슬롯을 차지할 수 있게끔 설정했습니다. 
```
memberIds
 └ ["userA", "userB"]

slotOwnerIds
 └ ["userA", "userB", "userA", null]
```

</details>

<details>
<summary><strong>3. 인증 방식 선정 및 확장성 고려</strong></summary>

> #### 문제
> 회원가입 과정에서 Apple 로그인, 카카오 로그인, Passkey 등 다양한 인증 방식을 함께 제공하는 방안을 검토했습니다. 
> 하지만 첫 출시 단계에서 여러 인증 수단을 동시에 구현하면 다음과 같은 부담이 발생합니다.

- 인증 서비스별 SDK와 플랫폼별 정책 관리
- 개발비용 및 테스트 범위 증가
- 핵심 기능 개발 일정 지연

✅ 초기 버전에서는 전화번호 문자 인증을 단일 인증 방식으로 채택했습니다.

#### 고려 사항
#### 문자 인증은 초기 진입 과정을 단순하게 만들 수 있지만 다음과 같은 한계가 있습니다.

* SMS 발송 비용과 국가별 지원 범위
* 전화번호 변경 시 계정 복구 처리
* 해외 사용자 접근성
* SIM 교체 및 번호 재사용에 따른 보안 문제


</details>

<details>
<summary><strong>4. 영상 로딩 에러 해결</strong></summary>

> #### 문제
> 기존에는 시간대마다 컨트롤러를 생성해 필수적으로 영상로딩 렉이 동반되었습니다. 

✅ 해결 : 시간대 변경마다 화면 전체를 교체하던 구조에서 PreloadPageView 기반 페이지 전환 구조로 변경했습니다. 현재 시간대를 기준으로 인접 페이지와 영상 컨트롤러만 미리 준비하고, 범위를 벗어난 컨트롤러는 해제하여 자연스러운 전환과 메모리 사용량 사이의 균형을 확보했습니다.


📌 개선 전 문제점( 1.0.1 버전 )
* 현재 시간대 앞뒤로 컨트롤러생성방법은 적절하나 영상을 전부 재생시키는게 비효율적
* NetworkImage(_currentProfileUrl!) 매번 프로필 url로 프로필이미지를 네트워킹 하는게아닌 캐싱을 이용해서 프로필사진 로딩 렉 개선


✅ 업데이트 개선 후 ( 1.0.2버전 ): 그럼에도 여전히 앱을 빌드하고 접속했을때 영상과 프로필사진을 가져오는데있어 약간의 잔렉이 발생함을 확인할 수 있었습니다. 이 부분을 개선해 최대한 사용성에 불편감을 없애는데 집중할 예정입니다.

* 현재 시간대 영상만 play() / 이전, 이후 영상은 컨트롤러 생성 재생은 pause()
* CachedNetworkImageProvider 프로필 매번 Url 네트워킹아닌 캐싱방식으로 변경


</details>

<details>
<summary><strong>5. 영상 합성방식 고민</strong></summary>

> #### 문제
> 초기에는 서버 또는 Cloud Functions에서 영상을 합성하는 방식을 고려했습니다.  
> 하지만 서버 기반 합성은 비용 부담이 있고, 영상을 업로드한 뒤 합성 결과물을 다시 내려받는 과정에서 발생하는 대기 시간이 사용자 경험을 해칠 수 있다고 판단했습니다.

✅ 서버에서 영상을 합성하는 방식 대신, iOS 네이티브의 `AVFoundation`을 활용해 기기 내부에서 영상을 합성하도록 구조를 변경했습니다.
Flutter에서는 영상 합성에 필요한 슬롯 정보, 영상 경로, 텍스트, 폰트, 색상 등의 데이터를 설계도 형태로 구성하고,  
Swift에서는 네이티브 코드로 전달받아 영상 합성을 담당하도록 구현했습니다.

- 시간대별 슬롯 영상을 하나의 페이지 영상으로 합성
- 각 슬롯 위치에 맞게 영상 크롭 및 배치
- 영상이 없는 슬롯에는 빈 배경과 시간 표시 렌더링
- 텍스트, 시간, 폰트 스타일을 오버레이로 합성
- 여러 시간대 페이지 영상을 하나의 일일 영상으로 연결
- 완성된 영상을 기기 갤러리에 저장

</details>

<br>


## 업데이트 계획 및 내역

<details>
<summary> 1.0.1 버전 업데이트 계획 - ✅ 완료</summary>
    
- 이용 등급 연령대 연령 낮추기
- 앱 용량 사이즈 다운
- 불필요한 테스트 파일 제거
- 카메라 버튼 및 텍스트 부자연스러운 UI 개선
    
</details>


<details>
<summary> 1.0.2 버전 업데이트 계획 - ✅ 완료</summary>
    
* 영상 추출 기능추가 - 하루 간 00:00 ~ 24:00 의 영상목록을 하루로그형식으로 추출해주는 기능 추가예정 AvFoundation
* 3일 지난 Post/Storage 영상 정리 로직 3일 기준 적용 /FireStorage 영상 저장경로 수정으로 정리 용이하게 변경
* 카메라 진입시 오류 버퍼링 해결, 카메라 리스트 미리 앱 초기에 캐싱하도록 변경
    
</details>


<details>
<summary> 1.0.3 버전 업데이트 계획 - ✅ 완료</summary>
    
* 푸시알림 시스템 적용
* 촬영화면 비율 수정 -> 가로 카메라 촬영으로 변경해달라는 피드백 -> 촬영 후 영상 후가공으로 가로 세로 비율 전환으로 업데이트 구현
    
</details>


<details>
<summary> 1.0.4 버전 업데이트 계획 - 진행중</summary>
    
* 카카오톡 및 소셜 로그인 구현
    
</details>
