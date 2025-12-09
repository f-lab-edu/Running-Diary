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
            return L10n.repositoryErrorNotFound.value
        case .saveFailed:
            return L10n.repositoryErrorSaveFailed.value
        case .updateFailed:
            return L10n.repositoryErrorUpdateFailed.value
        case .deleteFailed:
            return L10n.repositoryErrorDeleteFailed.value
        }
    }
}
