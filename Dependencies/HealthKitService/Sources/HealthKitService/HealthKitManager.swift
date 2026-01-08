//
//  HealthKitManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CoreLocation
import Foundation
import HealthKit
import Models

public final class HealthKitManager: HealthKitManagerProtocol, @unchecked Sendable {
    private let healthStore = HKHealthStore()

    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation)!,
        HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)!,
        HKObjectType.quantityType(forIdentifier: .walkingStepLength)!,
        HKSeriesType.workoutRoute(),
    ]

    public init() {}

    public func ensureAuthorizationIfNeeded() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let statuses = currentAuthorizationStatuses()
        let notDetermined = statuses.filter { $0.value == .notDetermined }.map { $0.key }

        guard !notDetermined.isEmpty else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            throw HealthKitError.authorizationFailed
        }
    }

    private func currentAuthorizationStatuses() -> [HKObjectType: HKAuthorizationStatus] {
        var result: [HKObjectType: HKAuthorizationStatus] = [:]
        for type in typesToRead {
            result[type] = healthStore.authorizationStatus(for: type)
        }
        return result
    }

    // 단일 Date에 대한 피트니스 기록을 가져옵니다.
    public func fetchRunningData(for date: Date) async throws -> [HealthKitWorkout] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.endOfDay(for: date) else {
            return []
        }

        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])

        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            healthStore.execute(query)
        }

        var results: [HealthKitWorkout] = []
        for workout in workouts {
            guard let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
                  let averagePace = calculateAveragePace(from: workout),
                  let averageHeartRate = try await fetchAverageHeartRate(for: workout),
                  let averageCadence = try await fetchAverageCadence(for: workout)
            else { continue }
            
            let activeEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            let runningVerticalOscillation = try await fetchAverageVerticalOscillation(for: workout) ?? 0
            let runningGroundContactTime = try await fetchAverageGroundContactTime(for: workout) ?? 0
            let walkingStepLength = try await fetchAverageStepLength(for: workout) ?? 0
            
            let routeData = try? await fetchRouteData(for: workout)

            let healthKitWorkout = HealthKitWorkout(
                distance: distance,
                duration: workout.duration,
                averagePace: averagePace,
                averageHeartRate: averageHeartRate,
                averageCadence: averageCadence,
                activeEnergyBurned: activeEnergyBurned,
                runningVerticalOscillation: runningVerticalOscillation,
                runningGroundContactTime: runningGroundContactTime,
                walkingStepLength: walkingStepLength,
                routeData: routeData,
                startDate: workout.startDate,
                endDate: workout.endDate
            )
            results.append(healthKitWorkout)
        }
        return results
    }

    private func calculateAveragePace(from workout: HKWorkout) -> String? {
        guard let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)),
              distance > 0
        else {
            return nil
        }

        let durationInMinutes = workout.duration / 60.0
        let paceMinPerKm = durationInMinutes / distance

        let minutes = Int(paceMinPerKm)
        let seconds = Int((paceMinPerKm - Double(minutes)) * 60)

        return String(format: "%d'%02d\"", minutes, seconds)
    }

    private func fetchAverageHeartRate(for workout: HKWorkout) async throws -> Int? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(
                        returning: samples as? [HKQuantitySample] ?? []
                    )
                }
            }
            healthStore.execute(query)
        }

        guard !samples.isEmpty else {
            return nil
        }

        let totalHeartRate = samples.reduce(0.0) {
            $0 + $1.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
        let average = totalHeartRate / Double(samples.count)

        return Int(floor(average))
    }

    private func fetchAverageCadence(for workout: HKWorkout) async throws -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        let totalSteps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: sum ?? 0)
            }
            healthStore.execute(query)
        }
        
        let durationInMinutes = workout.duration / 60.0

        guard durationInMinutes > 0 && totalSteps > 0 else {
            return nil
        }

        let cadence = totalSteps / durationInMinutes

        return Int(cadence)
    }

    private func fetchAverageVerticalOscillation(for workout: HKWorkout) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningVerticalOscillation) else { return nil }
        return try await fetchAverageQuantity(for: workout, type: type, unit: .meterUnit(with: .centi))
    }

    private func fetchAverageGroundContactTime(for workout: HKWorkout) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningGroundContactTime) else { return nil }
        return try await fetchAverageQuantity(for: workout, type: type, unit: .secondUnit(with: .milli))
    }

    private func fetchAverageStepLength(for workout: HKWorkout) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingStepLength) else { return nil }
        return try await fetchAverageQuantity(for: workout, type: type, unit: .meter())
    }

    private func fetchAverageQuantity(for workout: HKWorkout, type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let average = statistics?.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: average)
            }
            healthStore.execute(query)
        }
    }

    private func fetchRouteData(for workout: HKWorkout) async throws -> Data? {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(
                        returning: samples as? [HKWorkoutRoute] ?? []
                    )
                }
            }
            healthStore.execute(query)
        }

        guard let route = routes.first else {
            return nil
        }

        var coordinates: [CLLocationCoordinate2D] = []

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let locations = locations {
                    coordinates.append(contentsOf: locations.map { $0.coordinate })
                }

                if done {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }

        let locations = coordinates.map {
            Location(
                latitude: $0.latitude,
                longitude: $0.longitude
            )
        }

        // [Location]을 JSON Data로 인코딩
        return try? JSONEncoder().encode(locations)
    }

    // startDate ~ endDate 기간에 대한 피트니스 기록을 가져옵니다.
    public func fetchWeeklyRunningData(from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout] {
        let calendar = Calendar.current

        // 시작일부터 종료일까지의 날짜 배열 생성
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        while currentDate <= normalizedEndDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // 각 날짜에 대해 병렬로 데이터 조회
        return await withTaskGroup(of: [HealthKitWorkout].self) { group in
            for date in dates {
                group.addTask { [self] in
                    return (try? await self.fetchRunningData(for: date)) ?? []
                }
            }

            // 결과를 하나의 배열로 합침
            var results: [HealthKitWorkout] = []
            for await result in group {
                results.append(contentsOf: result)
            }

            return results
        }
    }
}
