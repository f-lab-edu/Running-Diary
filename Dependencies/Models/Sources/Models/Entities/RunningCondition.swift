//
//  RunningCondition.swift
//  Models
//
//  Created by 김혜지 on 10/31/25.
//

public struct RunningCondition: Equatable {
    public let sleep: Int?       // 수면 시간
    public let meal: Bool        // 식사 여부
    public let alcohol: Bool     // 음주 여부
    public let memo: String?     // 기타 메모

    public init(
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
