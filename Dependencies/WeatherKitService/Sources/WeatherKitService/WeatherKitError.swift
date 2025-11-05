//
//  WeatherKitError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public enum WeatherKitError: Error {
    case missingLocation
    case dataUnavailable
}
