# 러닝 기록 다이어리

## 개요
- SwiftUI + TCA
- Feature 모듈화, 단방향 데이터 흐름
- 목표: 일자별 러닝 기록 및 컨디션 관리

## 주요 화면
1. **일자별 기록** (메인): 날짜 Carousel, HealthKit 데이터, 통증/주법/컨디션, 신발, 날씨, 경로
2. **캘린더 뷰**: 만족도 시각화
3. **기록 추가/편집**: HealthKit 불러오기 또는 수동 입력

## 기술 스택
- **아키텍처**: TCA (@Reducer, State, Action, Dependency)
- **저장소**: SwiftData (Repository 패턴)
- **연동**: HealthKit (거리/심박/케이던스/경로), 신발 API, 날씨 API

## 우선순위
1. ✅ 셋업
2. 🔄 UI 기본 구조 (날짜 Carousel, Mock 데이터)
3. ⏳ HealthKit 연동
4. ⏳ 기록 추가 화면
5. ⏳ 캘린더 뷰
6. ⏳ SwiftData + Repository
7. ⏳ 외부 API 연동

## 코딩 규칙
- **네이밍**: SwiftLint + Swift API Guidelines
  - 타입: UpperCamelCase (`~View`, `~Feature`)
  - 변수/함수: lowerCamelCase
- **TCA**: `@Reducer` 매크로, State/Action 분리, `@Dependency` 주입
- **접근 제어**: 기본 internal, 불필요시 private
- **테스트**: Reducer는 TestStore로 필수, Dependency는 Mock 구현

자세한 예시: 기존 Feature 파일 참고

## 협업
Git 워크플로우, 커밋/PR 규칙: [CONTRIBUTING.md](./CONTRIBUTING.md)