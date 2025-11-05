//
//  KMAWeatherModels.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

// MARK: - KMA API Response Models

struct KMAWeatherResponse: Codable {
  let response: KMAResponse
}

struct KMAResponse: Codable {
  let body: KMABody
}

struct KMABody: Codable {
  let items: KMAItems
}

struct KMAItems: Codable {
  let item: [KMAItem]?
}

struct KMAItem: Codable {
  let category: String
  let fcstValue: String
}
