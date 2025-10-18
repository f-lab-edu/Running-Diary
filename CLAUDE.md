# 프로젝트: 러닝 기록 다이어리

## 프로젝트 개요

- **목적**: 일자별 러닝 기록 및 컨디션을 관리하는 iOS 앱
- **기술 스택**: SwiftUI + Swift 5.0
- **아키텍처**
  - TCA (The Composable Architecture)
  - Feature 기반 모듈화
  - Reducer 기반 단방향 데이터 흐름

## 주요 기능

### 1. 일자별 러닝 기록 화면 (메인)

- **일자 선택 Carousel**
  - 수평 스크롤 가능한 날짜 선택기
  - 선택된 날짜에 따라 하단 기록 표시

- **기록 상세 정보** (세로 스크롤)
  - HealthKit 연동 데이터
    - 거리 (km)
    - 평균 페이스 (min/km)
    - 평균 심박수 (bpm)
    - 평균 케이던스 (spm)
  - 통증 부위
  - 주법/스타일
  - 컨디션
    - 수면 시간
    - 식사 여부
    - 음주 여부
    - 기타 메모
  - 착용 신발 (외부 API 연동)
  - 날씨 정보
    - 기온
    - 습도
    - 풍속
  - 지도 (러닝 경로)
  - [미정] 만족도 평가

- **기록 추가**
  - 기록 없는 날짜 선택 시 "추가하기" 버튼 표시
  - 모든 항목 수동 입력 가능

### 2. 캘린더 뷰

- **진입**: 일자별 기록 화면 상단 "전체보기" 버튼
- **디자인**: 애플 캘린더 스타일
- **표시**: 만족도 항목을 일자별로 시각화 (미정)

### 3. 러닝 기록 추가/편집

- HealthKit 데이터 불러오기 or 수동 입력
- 모든 상세 항목 입력 폼 제공
- 신발 종류는 외부 API를 통해 검색/선택

## 화면 흐름

```
[앱 실행]
    ↓
[일자별 러닝 기록 화면] ← 메인 화면
    ├─ [일자 Carousel]
    │    └─ "전체보기" 버튼 → [캘린더 뷰]
    ├─ [기록 상세 (스크롤)]
    └─ [추가하기 버튼] → [기록 추가 화면]
             (기록 없을 때만 표시)
```

## 기술 스택 및 아키텍처

### 외부 연동

#### HealthKit

- 권한: 앱 초기 실행 시 요청
- 읽기 권한: 거리, 심박수, 케이던스, 경로 데이터
- 백그라운드 동기화 고려 (TBD)

#### 신발 API

- 외부 API를 통해 신발 정보 검색
- API 명세 미정

#### 날씨 API

- OpenWeatherMap 또는 기상청 API 고려 (TBD)

### 데이터 저장

#### SwiftData (로컬 DB)

- iOS 17+ 네이티브 솔루션
- Repository 패턴으로 추상화
- iCloud 동기화 옵션 (개인 기기 간)

> 구현 전략: Repository 인터페이스로 추상화하여 추후 백엔드 추가 시 교체 용이하게 설계

## 구현 시 고려사항

- **HealthKit 권한**: 앱 초기 실행 시 요청, 거부 시 수동 입력만 가능
- **DB 아키텍처**: Repository 패턴으로 추상화하여 추후 교체 용이하게 설계
- **API 의존성**: 신발 API, 날씨 API 실패 시 Graceful Degradation 적용

## 개발 우선순위

1. ✅ 프로젝트 셋업 & CLAUDE.md 작성
2. 🔄 UI/UX 기본 구조
   - 일자별 기록 화면 레이아웃
   - 날짜 Carousel 컴포넌트
   - Mock 데이터로 기록 표시
3. ⏳ HealthKit 연동
   - 권한 요청 플로우
   - 러닝 데이터 Fetch
4. ⏳ 기록 추가 화면
5. ⏳ 캘린더 뷰
6. ⏳ 데이터 저장
  - SwiftData 모델 정의
  - Repository 구현
  - ViewModel과 연동
7. ⏳ 외부 API 연동 (신발, 날씨)
8. ⏳ 로그인 기능 (미정)

## 개발 규칙

### 코딩 규칙

#### 네이밍 컨벤션 (SwiftLint + Swift API Guidelines)

- **타입**: UpperCamelCase
  - View: `~View` (예: `DailyRecordView`)
  - Reducer: `~Feature` 또는 `~Reducer` (예: `DailyRecordFeature`, `DailyRecordReducer`)
  - State: `State` (Reducer 내부 struct)
  - Action: `Action` (Reducer 내부 enum)
  - Protocol: `~able`, `~Protocol` (예: `Recordable`, `RecordRepositoryProtocol`)
- **변수/함수**: lowerCamelCase
- **상수**: lowerCamelCase (타입 프로퍼티는 예외적으로 UpperCamelCase 가능)
- **약어**: 모두 대문자 or 모두 소문자 (예: `url`, `json`, `UUID`)

#### TCA 스타일

- **Reducer 구조**
  - State, Action, body를 명확하게 분리
  - Reducer는 `@Reducer` 매크로 사용
  - 각 Feature는 독립적인 파일로 분리

**예시**
```swift
@Reducer
struct DailyRecordFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDate: Date = Date()
        var dates: [Date] = []
        var runningRecord: RunningRecord?
        var isLoading: Bool = false
    }

    enum Action {
        case selectDate(Date)
        case fetchRunningRecord(Date)
        case runningRecordResponse(Result<RunningRecord?, Error>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .selectDate(date):
                state.selectedDate = date
                return .run { send in
                    await send(.fetchRunningRecord(date))
                }
            // ...
            }
        }
    }
}
```

- **View와 Reducer 연결**
  - `Store`를 통해 Reducer와 연결
  - `@Bindable`로 양방향 바인딩 구현

```swift
struct DailyRecordView: View {
    let store: StoreOf<DailyRecordFeature>

    var body: some View {
        // WithViewStore 대신 @Bindable 사용
        Text("TCA View")
    }
}
```

- **Dependency 관리**
  - 외부 의존성은 `@Dependency`로 주입
  - HealthKit, API 등은 DependencyClient로 추상화

```swift
@DependencyClient
struct HealthKitClient {
    var fetchRunningData: @Sendable (Date) async throws -> RunningRecord?
}
```

#### SwiftUI 스타일

- 공통 스타일: ViewModifier로 재사용
- Preview 필수 작성
- View 분리: 복잡한 View는 `private struct`로 subview 분리
- View 구조체는 init 메서드 필수 작성

#### 접근 제어

- **기본**: `internal` (명시하지 않음)
- **외부 노출 불필요**: `private` 또는 `fileprivate`
- **모듈 간 공유**: `public` (Framework화 시 고려)

#### 테스트

- Reducer 로직: Unit Test 필수
  - TestStore를 사용한 상태 변화 검증
  - Effect 실행 및 응답 테스트
  - Action 순서 검증
- Dependency: Mock/Test 구현체 작성
- 복잡한 Utils/Manager: Unit Test 작성
- UI 컴포넌트: Snapshot Test 고려 (TBD)

### Git 워크플로우

브랜치 전략, 커밋, PR 규칙 등 협업 가이드라인은 [CONTRIBUTING.md](./CONTRIBUTING.md)를 참고하세요.
