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

    /**
     뷰의 프레임을 정사각형으로 설정합니다.
     
     - Parameters:
     - size: 정사각형의 한 변의 길이 (width와 height에 동일하게 적용됩니다.)
     - alignment: 뷰가 프레임 내에서 정렬되는 방식 (기본값: .center)
     */
    public func square(_ size: CGFloat, alignment: Alignment = .center) -> some View {
        self.frame(width: size, height: size, alignment: alignment)
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
