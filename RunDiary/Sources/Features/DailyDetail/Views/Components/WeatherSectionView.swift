//
//  WeatherSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import Models
import SwiftUI

struct WeatherSectionView: View {
    let weather: WeatherData

    init(weather: WeatherData) {
        self.weather = weather
    }

    var body: some View {
        HStack(spacing: 0) {
            WeatherItemView(
                icon: "thermometer",
                title: L10n.Weather.Field.temperature.value,
                value: String(format: "%.1f°C", weather.temperature)
            )

            Spacer()
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.gray100)
            Spacer()

            WeatherItemView(
                icon: "humidity.fill",
                title: L10n.Weather.Field.humidity.value,
                value: "\(weather.humidity)%"
            )

            Spacer()
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.gray100)
            Spacer()

            WeatherItemView(
                icon: "wind",
                title: L10n.Weather.Field.windSpeed.value,
                value: String(format: "%.1fm/s", weather.windSpeed)
            )
        }
        .padding(.horizontal)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct WeatherItemView: View {
    let icon: String
    let title: String
    let value: String

    init(icon: String, title: String, value: String) {
        self.icon = icon
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue300)
                .frame(height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray500)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue700)
            }
        }
    }
}
