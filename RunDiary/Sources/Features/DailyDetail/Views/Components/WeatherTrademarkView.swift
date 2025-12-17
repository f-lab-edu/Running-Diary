//
//  WeatherTrademarkView.swift
//  RunDiary
//
//  Created by Claude on 12/17/25.
//

import Models
import SwiftUI

struct WeatherTrademarkView: View {
    let trademark: WeatherTrademark

    var body: some View {
        if let legalPageURL = trademark.legalPageURL {
            Button {
                UIApplication.shared.open(legalPageURL)
            } label: {
                HStack(spacing: 4) {
                    Text("Weather from")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if let imageURL = trademark.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 14)
                            case .failure, .empty:
                                Text("Apple")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Text("Apple")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With image URL
        WeatherTrademarkView(
            trademark: WeatherTrademark(
                imageURL: URL(string: "https://weatherkit.apple.com/assets/branding/en/Apple_Weather_wx_mark.png"),
                legalPageURL: URL(string: "https://weatherkit.apple.com/legal-attribution.html")
            )
        )

        // Without image URL
        WeatherTrademarkView(
            trademark: WeatherTrademark(
                imageURL: nil,
                legalPageURL: URL(string: "https://weatherkit.apple.com/legal-attribution.html")
            )
        )
    }
}
