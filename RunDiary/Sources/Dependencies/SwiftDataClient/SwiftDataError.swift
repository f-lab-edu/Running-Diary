//
//  SwiftDataError.swift
//  RunDiary
//
//  Created by 김혜지 on 11/5/25.
//

import Foundation

enum SwiftDataError: LocalizedError, Equatable {
    case notFound
    case saveFailed
    case updateFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            return L10n.Repository.Error.notFound.value
        case .saveFailed:
            return L10n.Repository.Error.saveFailed.value
        case .updateFailed:
            return L10n.Repository.Error.updateFailed.value
        case .deleteFailed:
            return L10n.Repository.Error.deleteFailed.value
        }
    }
}
