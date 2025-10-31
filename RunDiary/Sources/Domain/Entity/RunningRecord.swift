//
//  RunningRecord.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import Foundation

struct RunningRecord: Identifiable, Equatable {
  let id: UUID
  let date: Date
  let distanceInKilometers: Double
  let durationInSeconds: TimeInterval  // seconds
  let averagePace: String  // min/km
  let averageHeartRate: Int  // bpm
  let averageCadence: Int  // steps/min
  let painAreas: [PainArea]
  let runningStyle: RunninStyle?
  let condition: RunningCondition
  let shoes: String?
  let weather: Weather?
  let difficultyLevel: DifficultyLevel?
  let routeData: Data?  // HealthKit route data
  let hasMap: Bool

  var distanceInMiles: Double {
    durationInSeconds * 0.621371
  }

  var formattedDuration: String {
    let hours = Int(durationInSeconds) / 3600
    let minutes = (Int(durationInSeconds) % 3600) / 60
    let seconds = Int(durationInSeconds) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  init(
    id: UUID = UUID(),
    date: Date,
    distanceInKilometers: Double,
    durationInSeconds: TimeInterval,
    averagePace: String,
    averageHeartRate: Int,
    averageCadence: Int,
    painAreas: [PainArea] = [],
    runningStyle: RunninStyle?,
    condition: RunningCondition = RunningCondition(),
    shoes: String? = nil,
    weather: Weather? = nil,
    difficultyLevel: DifficultyLevel? = nil,
    routeData: Data? = nil,
    hasMap: Bool = false
  ) {
    self.id = id
    self.date = date
    self.distanceInKilometers = distanceInKilometers
    self.durationInSeconds = durationInSeconds
    self.averagePace = averagePace
    self.averageHeartRate = averageHeartRate
    self.averageCadence = averageCadence
    self.painAreas = painAreas
    self.runningStyle = runningStyle
    self.condition = condition
    self.shoes = shoes
    self.weather = weather
    self.difficultyLevel = difficultyLevel
    self.routeData = routeData
    self.hasMap = hasMap
  }
}

struct HealthKitDataModel: Equatable {
  let distance: Double  // km
  let durationInSeconds: TimeInterval  // seconds
  let averagePace: String  // min/km
  let averageHeartRate: Int  // bpm
  let averageCadence: Int  // steps/min
  let routeData: Data?

  var formattedDistance: String {
    distance == 0 ? "" : distance.to2f
  }
  var formattedDuration: String {
    durationInSeconds == 0 ? "" : durationInSeconds.formatted
  }
  var formattedAverageHeartRate: String {
    averageHeartRate == 0 ? "" : averageHeartRate.toString
  }
  var formattedAverageCadence: String {
    averageCadence == 0 ? "" : averageCadence.toString
  }
}

struct RunningCondition: Equatable {
  let sleep: Int?  // 수면 시간
  let meal: Bool  // 식사 여부
  let alcohol: Bool  // 음주 여부
  let memo: String?  // 기타 메모

  init(
    sleep: Int? = nil,
    meal: Bool = false,
    alcohol: Bool = false,
    memo: String? = nil
  ) {
    self.sleep = sleep
    self.meal = meal
    self.alcohol = alcohol
    self.memo = memo
  }
}

struct Weather: Equatable {
  let temperature: Double  // 기온 (°C)
  let humidity: Int  // 습도 (%)
  let windSpeed: Double  // 풍속 (m/s)

  init(
    temperature: Double,
    humidity: Int,
    windSpeed: Double
  ) {
    self.temperature = temperature
    self.humidity = humidity
    self.windSpeed = windSpeed
  }
}

enum DifficultyLevel: Int, CaseIterable {
  case veryEasy = 1
  case easy
  case medium
  case hard
  case veryHard

  var displayName: String {
    switch self {
    case .veryEasy:
      return "매우 쉬움"
    case .easy:
      return "쉬움"
    case .medium:
      return "보통"
    case .hard:
      return "어려움"
    case .veryHard:
      return "매우 어려움"
    }
  }
}
