//
//  KMAWeatherManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import CoreLocation

final class KMAWeatherManager: WeatherManagerProtocol {
    private let apiKey: String?
    private let baseURL = "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0"

    init(apiKey: String? = nil) {
        self.apiKey = apiKey
    }

    func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> Weather {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw WeatherError.apiKeyMissing
        }

        guard let location = location else {
            throw WeatherError.locationRequired
        }

        // 위경도를 기상청 격자 좌표로 변환
        let grid = convertToGrid(lat: location.latitude, lon: location.longitude)

        // 날짜를 기상청 API 형식으로 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let baseDate = dateFormatter.string(from: date)

        dateFormatter.dateFormat = "HHmm"
        let baseTime = "0600" // 기상청 API 기준 시간 (조정 필요)

        // API 엔드포인트 구성
        let endpoint = "\(baseURL)/getUltraSrtFcst"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "serviceKey", value: apiKey),
            URLQueryItem(name: "numOfRows", value: "100"),
            URLQueryItem(name: "pageNo", value: "1"),
            URLQueryItem(name: "dataType", value: "JSON"),
            URLQueryItem(name: "base_date", value: baseDate),
            URLQueryItem(name: "base_time", value: baseTime),
            URLQueryItem(name: "nx", value: "\(grid.nx)"),
            URLQueryItem(name: "ny", value: "\(grid.ny)")
        ]

        guard let url = components.url else {
            throw WeatherError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.networkError
        }

        // JSON 파싱
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(KMAWeatherResponse.self, from: data)

        return parseWeatherData(from: apiResponse)
    }

    private func parseWeatherData(from response: KMAWeatherResponse) -> Weather {
        guard let items = response.response.body.items.item else {
            return Weather(temperature: 20.0, humidity: 60, windSpeed: 2.0)
        }

        var temperature: Double = 20.0
        var humidity: Int = 60
        var windSpeed: Double = 2.0

        for item in items {
            switch item.category {
            case "T1H", "TMP": // 기온
                temperature = Double(item.fcstValue) ?? temperature
            case "REH": // 습도
                humidity = Int(item.fcstValue) ?? humidity
            case "WSD": // 풍속
                windSpeed = Double(item.fcstValue) ?? windSpeed
            default:
                break
            }
        }

        return Weather(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed
        )
    }

    private func convertToGrid(lat: Double, lon: Double) -> (nx: Int, ny: Int) {
        // 기상청 격자 좌표 변환 공식 (간략화)
        // 실제로는 Lambert Conformal Conic 투영법 사용
        // TODO: 정확한 변환 공식 적용 필요

        let RE = 6371.00877 // 지구 반경(km)
        let GRID = 5.0       // 격자 간격(km)
        let SLAT1 = 30.0     // 투영 위도1(degree)
        let SLAT2 = 60.0     // 투영 위도2(degree)
        let OLON = 126.0     // 기준점 경도(degree)
        let OLAT = 38.0      // 기준점 위도(degree)
        let XO = 43.0        // 기준점 X좌표(GRID)
        let YO = 136.0       // 기준점 Y좌표(GRID)

        let DEGRAD = Double.pi / 180.0
        let re = RE / GRID
        let slat1 = SLAT1 * DEGRAD
        let slat2 = SLAT2 * DEGRAD
        let olon = OLON * DEGRAD
        let olat = OLAT * DEGRAD

        let sn = tan(Double.pi * 0.25 + slat2 * 0.5) / tan(Double.pi * 0.25 + slat1 * 0.5)
        let sf = tan(Double.pi * 0.25 + slat1 * 0.5)
        let ro = re * sf / pow(sn, slat1)

        let ra = tan(Double.pi * 0.25 + lat * DEGRAD * 0.5)
        let theta = lon * DEGRAD - olon

        let x = ra * sin(theta * sn)
        let y = ro - ra * cos(theta * sn)

        let nx = Int(x + XO + 0.5)
        let ny = Int(y + YO + 0.5)

        return (nx: nx, ny: ny)
    }
}
