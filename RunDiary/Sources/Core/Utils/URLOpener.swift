//
//  URLOpener.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

import UIKit

@MainActor
enum URLOpener {
  static func open(url urlString: String) {
    guard let url = URL(string: urlString),
      UIApplication.shared.canOpenURL(url)
    else { return }
    UIApplication.shared.open(url)
  }

  static func openSettings() {
    open(url: UIApplication.openSettingsURLString)
  }
}
