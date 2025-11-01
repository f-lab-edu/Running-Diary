import Foundation
import Testing
@testable import HealthKitService

// MARK: - HealthKitError Tests

@Suite("HealthKitError Tests")
struct HealthKitErrorTests {
    @Test("HealthKitError.notAvailable has correct localized description")
    func testNotAvailableErrorDescription() {
        let error = HealthKitError.notAvailable
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }

    @Test("HealthKitError.authorizationFailed has correct localized description")
    func testAuthorizationFailedErrorDescription() {
        let error = HealthKitError.authorizationFailed
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }

    @Test("HealthKitError.dataNotFound has correct localized description")
    func testDataNotFoundErrorDescription() {
        let error = HealthKitError.dataNotFound
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }

    @Test("HealthKitError cases are equatable")
    func testEquatable() {
        #expect(HealthKitError.notAvailable == HealthKitError.notAvailable)
        #expect(HealthKitError.authorizationFailed == HealthKitError.authorizationFailed)
        #expect(HealthKitError.dataNotFound == HealthKitError.dataNotFound)

        #expect(HealthKitError.notAvailable != HealthKitError.authorizationFailed)
        #expect(HealthKitError.notAvailable != HealthKitError.dataNotFound)
        #expect(HealthKitError.authorizationFailed != HealthKitError.dataNotFound)
    }
}

// MARK: - HealthKitRunningData Tests

@Suite("HealthKitRunningData Tests")
struct HealthKitRunningDataTests {
    @Test("HealthKitRunningData initializes with all properties")
    func testInitializationWithAllData() {
        let routeData = Data([0x01, 0x02, 0x03])

        let data = HealthKitRunningData(
            distance: 5.2,
            duration: 1800.0,
            averagePace: "5'30\"",
            averageHeartRate: 155,
            averageCadence: 180,
            routeData: routeData
        )

        #expect(data.distance == 5.2)
        #expect(data.duration == 1800.0)
        #expect(data.averagePace == "5'30\"")
        #expect(data.averageHeartRate == 155)
        #expect(data.averageCadence == 180)
        #expect(data.routeData == routeData)
    }

    @Test("HealthKitRunningData initializes with nil values")
    func testInitializationWithNilValues() {
        let data = HealthKitRunningData(
            distance: nil,
            duration: nil,
            averagePace: nil,
            averageHeartRate: nil,
            averageCadence: nil,
            routeData: nil
        )

        #expect(data.distance == nil)
        #expect(data.duration == nil)
        #expect(data.averagePace == nil)
        #expect(data.averageHeartRate == nil)
        #expect(data.averageCadence == nil)
        #expect(data.routeData == nil)
    }

    @Test("HealthKitRunningData initializes with mixed values")
    func testInitializationWithMixedValues() {
        let data = HealthKitRunningData(
            distance: 10.5,
            duration: 3600.0,
            averagePace: nil,
            averageHeartRate: 145,
            averageCadence: nil,
            routeData: nil
        )

        #expect(data.distance == 10.5)
        #expect(data.duration == 3600.0)
        #expect(data.averagePace == nil)
        #expect(data.averageHeartRate == 145)
        #expect(data.averageCadence == nil)
        #expect(data.routeData == nil)
    }

    @Test("HealthKitRunningData handles edge case values")
    func testEdgeCaseValues() {
        let data = HealthKitRunningData(
            distance: 0.0,
            duration: 0.0,
            averagePace: "",
            averageHeartRate: 0,
            averageCadence: 0,
            routeData: Data()
        )

        #expect(data.distance == 0.0)
        #expect(data.duration == 0.0)
        #expect(data.averagePace == "")
        #expect(data.averageHeartRate == 0)
        #expect(data.averageCadence == 0)
        #expect(data.routeData == Data())
    }
}
