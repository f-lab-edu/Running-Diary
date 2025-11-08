import CoreLocation
import Testing
@testable import WeatherKitService

// MARK: - MockWeatherManager Tests

@Test("MockWeatherManager: location이 nil일 때 에러 발생")
func mockWeatherManagerThrowsErrorWhenLocationIsNil() async {
    let manager = MockWeatherManager()
    let date = Date.now

    await #expect(throws: WeatherKitError.missingLocation) {
        try await manager.fetchWeather(for: date, location: nil)
    }
}

@Test("MockWeatherManager: location이 제공되면 데이터 반환")
func mockWeatherManagerReturnsDataWithValidLocation() async throws {
    let manager = MockWeatherManager()
    let date = Date.now
    let location = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    let weather = try await manager.fetchWeather(for: date, location: location)

    // 범위 검증
    #expect(weather.temperature >= 10 && weather.temperature <= 30)
    #expect(weather.humidity >= 40 && weather.humidity <= 80)
    #expect(weather.windSpeed >= 0.5 && weather.windSpeed <= 5.0)
}

@Test("MockWeatherManager: 비동기 함수 정상 실행")
func mockWeatherManagerAsyncExecution() async throws {
    let manager = MockWeatherManager()
    let date = Date.now
    let location = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // 비동기 함수가 정상적으로 완료되는지 확인
    let weather = try await manager.fetchWeather(for: date, location: location)

    #expect(weather.temperature > 0)
}

// MARK: - WeatherKitManager Tests

@Test("WeatherKitManager: location이 nil일 때 에러 발생")
func weatherKitManagerThrowsErrorWhenLocationIsNil() async {
    let manager = WeatherKitManager()
    let date = Date.now

    await #expect(throws: WeatherKitError.missingLocation) {
        try await manager.fetchWeather(for: date, location: nil)
    }
}

@Test("WeatherKitManager: location이 제공되면 정상 동작 시도")
func weatherKitManagerWithValidLocation() async throws {
    let manager = WeatherKitManager()
    let date = Date.now
    let location = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    // 실제 WeatherKit API는 권한 및 환경 설정이 필요하므로
    // 에러가 발생하거나 정상적으로 데이터를 반환할 수 있음
    // 여기서는 location이 nil이 아닌 경우 missingLocation 에러가 발생하지 않는지만 확인
    do {
        let weather = try await manager.fetchWeather(for: date, location: location)
        // 성공한 경우 데이터 검증
        #expect(weather.temperature != 0 || weather.humidity != 0 || weather.windSpeed != 0)
    } catch WeatherKitError.missingLocation {
        Issue.record("location이 제공되었으므로 missingLocation 에러가 발생하면 안됨")
    } catch {
        // 실제 WeatherKit API 호출 실패는 예상 가능 (권한, 네트워크 등)
        // dataUnavailable 또는 다른 시스템 에러는 허용
    }
}

// MARK: - WeatherKitError Tests

@Test("WeatherKitError: missingLocation 케이스 생성")
func weatherKitErrorMissingLocation() {
    let error = WeatherKitError.missingLocation

    #expect(error as Error != nil)
}

@Test("WeatherKitError: dataUnavailable 케이스 생성")
func weatherKitErrorDataUnavailable() {
    let error = WeatherKitError.dataUnavailable

    #expect(error as Error != nil)
}

@Test("WeatherKitError: 에러 타입 동등성")
func weatherKitErrorEquality() {
    let error1 = WeatherKitError.missingLocation
    let error2 = WeatherKitError.missingLocation
    let error3 = WeatherKitError.dataUnavailable

    // 같은 케이스는 동등해야 함
    #expect(error1 == error2)
    // 다른 케이스는 동등하지 않아야 함
    #expect(error1 != error3)
}

// MARK: - Protocol Conformance Tests

@Test("MockWeatherManager: WeatherManagerProtocol 준수")
func mockWeatherManagerConformsToProtocol() {
    let manager: any WeatherManagerProtocol = MockWeatherManager()

    #expect(manager is WeatherManagerProtocol)
}

@Test("WeatherKitManager: WeatherManagerProtocol 준수")
func weatherKitManagerConformsToProtocol() {
    let manager: any WeatherManagerProtocol = WeatherKitManager()

    #expect(manager is WeatherManagerProtocol)
}
