# Running Diary 🏃‍♀️

Running Diary는 단순한 거리와 페이스 기록을 넘어, 러닝 당시의 컨디션과 경험까지 함께 저장하는 러닝 기록 iOS 앱입니다.

## 화면 구성

### 1. 일자별 러닝 기록 화면
- **날짜 캐러셀**: 가로 스크롤 형식으로 날짜 선택 (오늘 기준 전후 2주)
- **러닝 기록 상세 뷰**
  - HealthKit에서 가져온 데이터: 거리, 평균 페이스, 평균 심박수, 평균 케이던스
  - 사용자 입력 데이터: 통증 부위, 주법/스타일, 컨디션 (수면, 식사, 음주, 메모), 신은 신발
  - 러닝 경로 지도
- **"전체보기" 버튼**: 캘린더 화면으로 이동
- **"추가하기" 버튼**: 기록이 없을 때 기록 추가 화면으로 이동

### 2. 캘린더 화면
- **월별 캘린더 UI**: 각 일자마다 러닝 기록 요약 정보 표시
  - Circular progress bar 또는 텍스트로 주요 지표 표기
- **화면 전환**
  - 일자 선택 시 → 해당 일자의 상세 기록 화면으로 이동
  - "X" 버튼 → 일자별 러닝 기록 화면으로 복귀

### 3. 기록 추가 화면
- **HealthKit 연동**: 거리, 페이스, 심박수, 케이던스 자동 불러오기
- **사용자 직접 입력**
  - 통증 부위
  - 주법/스타일
  - 컨디션: 수면, 식사, 음주, 기타 메모
  - 신은 신발
- 일자별 러닝 기록 화면의 "추가하기" 버튼을 통해 진입

## 화면 흐름도

```mermaid
graph LR
    A[일자별 러닝 기록] <--> B[캘린더]
    A <--> C[기록 추가]

    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#ffe1f5
```

## 기술 스택

### Architecture
- **TCA (The Composable Architecture)**: 단방향 데이터 흐름과 합성 가능한 아키텍처
  - **Reducer**: 상태 변화와 비즈니스 로직을 순수 함수로 관리
  - **State**: 불변 상태 관리로 예측 가능한 상태 변화
  - **Effect**: 비동기 작업과 외부 의존성 관리
  - **Dependency**: 의존성 주입을 통한 테스트 용이성
  - **Feature 기반 모듈화**: 각 기능을 독립적인 Reducer로 구성

### Tech Stack
- **SwiftUI**: 선언적 UI 프레임워크
- **TCA**: The Composable Architecture 라이브러리
- **Swift Concurrency**: async/await 기반 비동기 처리

## 개발 환경

- **Xcode**: 16.0+
- **iOS Deployment Target**: 26.0
- **Swift**: 5.0
- **Language**: Swift, SwiftUI