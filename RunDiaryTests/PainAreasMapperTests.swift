//
//  PainAreasMapperTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/31/25.
//

import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("PainAreasMapper")
struct PainAreasMapperTests {

  // MARK: - Helper Methods

  /// JSON 문자열을 [String] 배열로 파싱
  private func parseJsonArray(_ jsonString: String?) -> [String]? {
    guard let jsonString,
      let data = jsonString.data(using: .utf8),
      let array = try? JSONDecoder().decode([String].self, from: data)
    else {
      return nil
    }
    return array
  }

  // MARK: - encode Tests

  @Test("encode: 빈 배열 인코딩 시 빈 JSON 배열 생성")
  func encodeEmptyArray() throws {
    let painAreas: [PainArea] = []

    let result = PainAreasMapper.encode(painAreas)
    let parsed = parseJsonArray(result)

    #expect(parsed != nil)
    #expect(parsed?.isEmpty == true)
  }

  @Test("encode: 단일 PainArea 인코딩 시 1개 요소 배열 생성")
  func encodeSinglePainArea() throws {
    let painAreas: [PainArea] = [.knee]

    let result = PainAreasMapper.encode(painAreas)
    let parsed = parseJsonArray(result)

    #expect(parsed?.count == 1)
    #expect(parsed?.first == PainArea.knee.rawValue)
  }

  @Test("encode: 여러 PainArea 인코딩 시 올바른 rawValue 배열 생성")
  func encodeMultiplePainAreas() throws {
    let painAreas: [PainArea] = [.knee, .ankle, .calf]

    let result = PainAreasMapper.encode(painAreas)
    let parsed = parseJsonArray(result)

    #expect(parsed?.count == 3)
    #expect(parsed?.contains(PainArea.knee.rawValue) == true)
    #expect(parsed?.contains(PainArea.ankle.rawValue) == true)
    #expect(parsed?.contains(PainArea.calf.rawValue) == true)
  }

  @Test("encode: 모든 PainArea 케이스 인코딩")
  func encodeAllPainAreas() throws {
    let painAreas = PainArea.allCases

    let result = PainAreasMapper.encode(painAreas)
    let parsed = parseJsonArray(result)

    #expect(parsed?.count == PainArea.allCases.count)

    // 모든 rawValue가 포함되어 있는지 검증
    for painArea in PainArea.allCases {
      #expect(parsed?.contains(painArea.rawValue) == true)
    }
  }

  @Test("encode: 중복된 PainArea 인코딩")
  func encodeDuplicatePainAreas() throws {
    let painAreas: [PainArea] = [.knee, .knee, .ankle]

    let result = PainAreasMapper.encode(painAreas)
    let parsed = parseJsonArray(result)

    #expect(parsed?.count == 3)
    #expect(parsed?.filter { $0 == PainArea.knee.rawValue }.count == 2)
  }

  // MARK: - encodeRaw Tests

  @Test("encodeRaw: 빈 배열 인코딩")
  func encodeRawEmptyArray() throws {
    let rawValues: [String] = []

    let result = PainAreasMapper.encodeRaw(rawValues)
    let parsed = parseJsonArray(result)

    #expect(parsed?.isEmpty == true)
  }

  @Test("encodeRaw: 문자열 배열 인코딩")
  func encodeRawStringArray() throws {
    let rawValues = ["무릎", "발목"]

    let result = PainAreasMapper.encodeRaw(rawValues)
    let parsed = parseJsonArray(result)

    #expect(parsed?.count == 2)
    #expect(parsed?[0] == "무릎")
    #expect(parsed?[1] == "발목")
  }

  // MARK: - decode Tests

  @Test("decode: nil 입력 시 빈 배열 반환")
  func decodeNilInput() throws {
    let result = PainAreasMapper.decode(nil)

    #expect(result.isEmpty)
  }

  @Test("decode: 빈 배열 디코딩")
  func decodeEmptyJsonArray() throws {
    // encode 결과를 활용
    let emptyEncoded = PainAreasMapper.encode([])

    let result = PainAreasMapper.decode(emptyEncoded)

    #expect(result.isEmpty)
  }

  @Test("decode: encode 결과를 올바르게 디코딩")
  func decodeEncodedResult() throws {
    let original: [PainArea] = [.knee, .ankle]

    // encode 결과를 decode의 입력으로 사용
    let encoded = PainAreasMapper.encode(original)
    let result = PainAreasMapper.decode(encoded)

    #expect(result.count == 2)
    #expect(Set(result) == Set(original))
  }

  @Test("decode: 잘못된 JSON 문자열 시 빈 배열 반환")
  func decodeInvalidJson() throws {
    let invalidInputs = [
      "invalid json",
      "{\"key\": \"value\"}",  // 객체 (배열이 아님)
      "[1, 2, 3]",  // 숫자 배열 (문자열 배열이 아님)
      "null",
      "",
    ]

    for invalidJson in invalidInputs {
      let result = PainAreasMapper.decode(invalidJson)
      #expect(result.isEmpty, "'\(invalidJson)'는 빈 배열을 반환해야 함")
    }
  }

  @Test("decode: 유효하지 않은 rawValue 필터링")
  func decodeWithInvalidRawValues() throws {
    // 유효한 값과 유효하지 않은 값이 섞인 배열 생성
    let mixedRawValues = [
      PainArea.knee.rawValue,
      "존재하지않는통증부위",
      PainArea.ankle.rawValue,
      "invalid",
    ]
    let encoded = PainAreasMapper.encodeRaw(mixedRawValues)

    let result = PainAreasMapper.decode(encoded)

    #expect(result.count == 2)
    #expect(result.contains(.knee))
    #expect(result.contains(.ankle))
  }

  @Test("decode: 모든 유효한 PainArea 디코딩")
  func decodeAllValidPainAreas() throws {
    let allPainAreas = PainArea.allCases
    let encoded = PainAreasMapper.encode(allPainAreas)

    let result = PainAreasMapper.decode(encoded)

    #expect(result.count == PainArea.allCases.count)
    #expect(Set(result) == Set(PainArea.allCases))
  }

  // MARK: - Round-trip Tests (Property-based Testing)

  @Test("Round-trip: 빈 배열")
  func roundTripEmptyArray() throws {
    let original: [PainArea] = []

    let encoded = PainAreasMapper.encode(original)
    let decoded = PainAreasMapper.decode(encoded)

    #expect(decoded.isEmpty)
    #expect(Set(decoded) == Set(original))
  }

  @Test("Round-trip: 단일 요소")
  func roundTripSingleElement() throws {
    for painArea in PainArea.allCases {
      let original = [painArea]

      let encoded = PainAreasMapper.encode(original)
      let decoded = PainAreasMapper.decode(encoded)

      #expect(decoded.count == 1)
      #expect(decoded.first == painArea)
    }
  }

  @Test("Round-trip: 여러 요소")
  func roundTripMultipleElements() throws {
    let testCases: [[PainArea]] = [
      [.knee, .ankle],
      [.knee, .ankle, .calf],
      [.thigh, .hip, .sole, .achilles],
      [.ankle, .knee, .calf, .thigh],  // 순서가 다른 경우
    ]

    for original in testCases {
      let encoded = PainAreasMapper.encode(original)
      let decoded = PainAreasMapper.decode(encoded)

      #expect(decoded.count == original.count)
      #expect(Set(decoded) == Set(original))
    }
  }

  @Test("Round-trip: 모든 케이스")
  func roundTripAllCases() throws {
    let original = PainArea.allCases

    let encoded = PainAreasMapper.encode(original)
    let decoded = PainAreasMapper.decode(encoded)

    #expect(decoded.count == original.count)
    #expect(Set(decoded) == Set(original))
  }

  @Test("Round-trip: 중복 요소")
  func roundTripDuplicateElements() throws {
    let original: [PainArea] = [.knee, .knee, .ankle, .ankle, .knee]

    let encoded = PainAreasMapper.encode(original)
    let decoded = PainAreasMapper.decode(encoded)

    // 중복을 포함한 개수 확인
    #expect(decoded.count == original.count)

    // 각 요소의 출현 횟수 확인
    for painArea in Set(original) {
      let originalCount = original.filter { $0 == painArea }.count
      let decodedCount = decoded.filter { $0 == painArea }.count
      #expect(originalCount == decodedCount)
    }
  }

  // MARK: - JSON Structure Tests

  @Test("JSON 구조: encode 결과는 유효한 JSON 배열")
  func encodeProducesValidJsonArray() throws {
    let testCases: [[PainArea]] = [
      [],
      [.knee],
      [.knee, .ankle, .calf],
      PainArea.allCases,
    ]

    for painAreas in testCases {
      let encoded = PainAreasMapper.encode(painAreas)

      // JSON으로 파싱 가능한지 검증
      #expect(encoded != nil)

      let parsed = parseJsonArray(encoded)
      #expect(parsed != nil, "encode 결과는 유효한 JSON 배열이어야 함")
    }
  }

  @Test("JSON 구조: encodeRaw 결과는 유효한 JSON 배열")
  func encodeRawProducesValidJsonArray() throws {
    let testCases: [[String]] = [
      [],
      ["test"],
      ["무릎", "발목"],
      ["a", "b", "c", "d", "e"],
    ]

    for rawValues in testCases {
      let encoded = PainAreasMapper.encodeRaw(rawValues)

      #expect(encoded != nil)

      let parsed = parseJsonArray(encoded)
      #expect(parsed != nil)
      #expect(parsed?.count == rawValues.count)
    }
  }
}
