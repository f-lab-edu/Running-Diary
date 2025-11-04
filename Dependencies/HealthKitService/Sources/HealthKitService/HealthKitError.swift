//
//  HealthKitError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public enum HealthKitError: Error, Equatable {
    case notAvailable
    case authorizationFailed
    case dataNotFound
}
