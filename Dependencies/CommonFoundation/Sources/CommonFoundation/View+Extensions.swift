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

    public func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// 뷰의 프레임을 정사각형으로 설정합니다.
    public func square(_ size: CGFloat, alignment: Alignment = .center) -> some View {
        self.frame(width: size, height: size, alignment: alignment)
    }

    public func loadingIndicatorIfNeeded(_ isLoading: Bool, backgroundColor: Color = .clear) -> some View {
        self.overlay {
            GeometryReader { geometry in
                if isLoading {
                    ZStack {
                        backgroundColor

                        ProgressView()
                            .controlSize(.regular)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                }
            }
        }
    }

    public func hideKeyboardOnTapOutside() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
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
