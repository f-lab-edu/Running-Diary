//
//  View+Extensions.swift
//  CommonFoundation
//
//  Created by 김혜지 on 11/4/25.
//

import SwiftUI

extension View {
    public var screenHeight: CGFloat {
        UIScreen.current?.bounds.height ?? 0
    }

    public var screenWidth: CGFloat {
        UIScreen.current?.bounds.width ?? 0
    }
}

private extension UIWindow {
    static var current: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)
    }
}

private extension UIScreen {
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
}
