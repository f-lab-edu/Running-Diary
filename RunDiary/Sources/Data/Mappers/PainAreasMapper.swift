//
//  PainAreasMapper.swift
//  RunDiary
//
//  Created by Claude on 10/29/25.
//

import Foundation

enum PainAreasMapper {
  /// [PainArea]를 JSON String으로 인코딩
  static func encode(_ painAreas: [PainArea]) -> String? {
    encodeRaw(painAreas.map { $0.rawValue })
  }

  /// [String] raw values를 JSON String으로 인코딩
  static func encodeRaw(_ rawValues: [String]) -> String? {
    guard let data = try? JSONEncoder().encode(rawValues) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  /// JSON String을 [PainArea]로 디코딩
  static func decode(_ jsonString: String?) -> [PainArea] {
    guard let jsonString,
      let data = jsonString.data(using: .utf8),
      let painAreasRaw = try? JSONDecoder().decode([String].self, from: data)
    else {
      return []
    }
    return painAreasRaw.compactMap { PainArea(rawValue: $0) }
  }
}
