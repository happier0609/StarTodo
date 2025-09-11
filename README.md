# 📱 StarTodo

Swift로 만든 iOS 앱 프로젝트입니다.  
간단한 설명과 주요 기능들을 소개합니다.

---

## 📌 주요 기능

- ✅ 할 일 목록 추가/삭제
- ✅ 타이머 기능으로 집중 모드
- ✅ 앱 내 데이터 저장 (SwiftData)

---

## 🧱 구조 요약

SplashView (2-3초)
    ↓ fullScreenCover
RootView (TabView)
    ├── MainView (Tab)
    │   ├── AddListView (세그먼트 1)
    │   └── FocusSettingView (세그먼트 2)
    │       ↓ NavigationLink
    │     TimerSettingView
    │       ↓ NavigationLink or fullScreenCover
    │     FocusModeView (세그먼트: Timer, List)
    │       ↓ NavigationLink or sheet
    │     ReportView
    │       ↓ NavigationLink or dismiss()
    │     MainView로 복귀
    └── HistoryView (Tab)

---

## 🏷️ 이슈 태그 정책

| 🏷️ Label | 📌 설명 |
|-----------|---------|
| ✨ `feature` | 새로운 기능 제안 및 구현 |
| 🐞 `bug` | 버그 리포트 및 수정 요청 |
| 🎨 `design` | UI/UX 관련 수정 및 개선 |
| 📚 `docs` | 문서 작성 및 수정 (README 등) |
| 🔧 `refactor` | 코드 리팩토링 (기능 변화 없음) |
| 🛠️ `fix` | 사소한 코드/오류 수정 |
| 🧱 `model` | 모델 관련 작업 |

---

## 📝 이슈 제목 작성 규칙

이슈 제목은 아래 형식을 따릅니다:

### 📌 예시
- `[feature] 집중모드 타이머 추가`
- `[bug] 앱 실행 시 크래시 발생`
- `[refactor] TodoViewModel 구조 개선`

---

## 🌿 브랜치 네이밍 규칙

작업 브랜치는 이슈 번호와 작업 유형을 조합해 아래 형식을 따릅니다:

### 📌 작업 유형 예시
- `feature` – 새로운 기능 개발
- `bugfix` – 버그 수정
- `design` – UI/UX 관련 작업
- `docs` – 문서 작업
- `refactor` – 코드 개선
- `hotfix` – 긴급 수정

### 🧾 브랜치 이름 예시
- `feature/12-focus-timer`
- `bugfix/8-login-crash`
- `design/15-main-ui`

---
