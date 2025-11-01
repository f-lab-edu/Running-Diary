//
//  String+Extensions.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

extension String {
    public var toDouble: Double {
        Double(self) ?? 0
    }

    public var toInt: Int {
        Int(self) ?? 0
    }
}
