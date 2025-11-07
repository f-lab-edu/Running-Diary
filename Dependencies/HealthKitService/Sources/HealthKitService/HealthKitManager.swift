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

public final class HealthKitManager: HealthKitManagerProtocol {
    private let healthStore = HKHealthStore()

    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKSeriesType.workoutRoute(),
    ]

    public init() {}

    public func ensureAuthorizationIfNeeded() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let statuses = currentAuthorizationStatuses()
        let notDetermined = statuses.filter { $0.value == .notDetermined }.map { $0.key }

        if !notDetermined.isEmpty {
            try await healthStore.requestAuthorization(
                toShare: [],
                read: typesToRead
            )
        }
    }

    private func currentAuthorizationStatuses() -> [HKObjectType: HKAuthorizationStatus] {
        var result: [HKObjectType: HKAuthorizationStatus] = [:]
        for type in typesToRead {
            result[type] = healthStore.authorizationStatus(for: type)
        }
        return result
    }

    public func fetchRunningData(for date: Date) async throws -> HealthKitRunningData? {
        // 날짜 범위 설정 (해당 날짜 하루)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.endOfDay(for: date) else {
            return nil
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

        guard let workout = workouts.first else { return nil }
        let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo))
        let averagePace = calculateAveragePace(from: workout)
        let averageHeartRate = try await fetchAverageHeartRate(for: workout)
        let averageCadence = try await fetchAverageCadence(for: workout)
        let routeData = try await fetchRouteData(for: workout)

        return HealthKitRunningData(
            distance: distance,
            duration: workout.duration,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            routeData: routeData,
            startDate: workout.startDate,
            endDate: workout.endDate
        )
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

        return Int(average)
    }

    private func fetchAverageCadence(for workout: HKWorkout) async throws -> Int? {
        guard
            let cadenceType = HKQuantityType.quantityType(
                forIdentifier: .stepCount
            )
        else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: cadenceType,
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

        let totalSteps = samples.reduce(0.0) {
            $0 + $1.quantity.doubleValue(for: .count())
        }
        let durationInMinutes = workout.duration / 60.0

        guard durationInMinutes > 0 else {
            return nil
        }

        let cadence = totalSteps / durationInMinutes

        return Int(cadence)
    }

    private func fetchRouteData(for workout: HKWorkout) async throws -> [HealthKitCoordinateData]? {
        let routeType = HKSeriesType.workoutRoute()

        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
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

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
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

        return coordinates.map {
            HealthKitCoordinateData(
                latitude: $0.latitude,
                longitude: $0.longitude
            )
        }
    }
}
