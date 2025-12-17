//
//  WeatherTrademark.swift
//  Models
//
//  Created by Claude on 12/17/25.
//

import Foundation

public struct WeatherTrademark: Equatable, Sendable {
    public let imageURL: URL?
    public let legalPageURL: URL?

    public init(imageURL: URL?, legalPageURL: URL?) {
        self.imageURL = imageURL
        self.legalPageURL = legalPageURL
    }
}
