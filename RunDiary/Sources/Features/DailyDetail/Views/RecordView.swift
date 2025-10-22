//
//  RecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct RecordView: View {
    let record: RunningRecord
    
    init(record: RunningRecord) {
        self.record = record
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 1: HealthKit 데이터 + 주법 + 통증 부위 + 신발
            SectionContainer {
                VStack(alignment: .leading, spacing: 16) {
                    // HealthKit 데이터
                    if record.distanceInKilometers != nil || record.averagePace != nil || record.durationInSeconds != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 20) {
                                if let distance = record.distanceInKilometers {
                                    RecordRowView(title: "거리", value: String(format: "%.2f km", distance))
                                }

                                if let duration = record.formattedDuration {
                                    RecordRowView(title: "소요시간", value: duration)
                                }
                            }

                            HStack(spacing: 20) {
                                if let pace = record.averagePace {
                                    RecordRowView(title: "평균 페이스", value: pace)
                                }

                                if let heartRate = record.averageHeartRate {
                                    RecordRowView(title: "평균 심박수", value: "\(heartRate) bpm")
                                }
                            }

                            HStack(spacing: 20) {
                                if let cadence = record.averageCadence {
                                    RecordRowView(title: "평균 케이던스", value: "\(cadence) spm")
                                }
                            }
                        }

                        Divider()
                            .padding(.vertical, 10)
                    }

                    // 주법/스타일
                    if let style = record.runningStyle {
                        DetailRowView(title: "주법", value: style.rawValue)
                    }

                    // 통증 부위
                    if !record.painAreas.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("통증 부위")
                                .font(.caption)
                                .foregroundColor(.gray)

                            DynamicGridLayout(items: record.painAreas) { item in
                                Text(item.rawValue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // 신발
                    if let shoes = record.shoes {
                        DetailRowView(title: "신발", value: shoes)
                    }
                }
            }

            // 섹션 2: 수면시간, 식사여부, 음주여부
            SectionContainer {
                VStack(alignment: .leading, spacing: 14) {
                    if let sleep = record.condition.sleep {
                        DetailRowView(title: "수면", value: "\(sleep)시간")
                    }

                    DetailIconRowView(title: "식사", isChecked: record.condition.meal)
                    DetailIconRowView(title: "음주", isChecked: record.condition.alcohol)
                }
            }

            // 섹션 3: 날씨 데이터
            SectionContainer {
                WeatherSectionView(weather: record.weather)
            }

            // 섹션 4: 셀프 피드백 점수, 메모
            SectionContainer {
                VStack(alignment: .leading, spacing: 12) {
                    SatisfactionView(satisfaction: record.satisfaction)

                    if let memo = record.condition.memo {
                        VStack(spacing: 20) {
                            Image("quotes_leading")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .opacity(0.3)

                            Text(memo)
                                .font(.body)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)

                            Image("quotes_trailing")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .opacity(0.3)
                        }
                    }
                }
            }

            // 지도
            if record.hasMap {
                SectionContainer {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            Text("지도 영역")
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
}

private struct RecordRowView: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailRowView: View {
    let title: String
    let value: String

    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}

private struct DetailIconRowView: View {
    let title: String
    let isChecked: Bool

    init(title: String, isChecked: Bool) {
        self.title = title
        self.isChecked = isChecked
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)

            Spacer()

            Image(systemName: isChecked ? "checkmark.app.fill" : "xmark.app.fill")
                .foregroundColor(isChecked ? .blue : .gray)
                .font(.title3)
        }
    }
}

private struct SectionContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

private struct SatisfactionView: View {
    let satisfaction: Int?

    init(satisfaction: Int?) {
        self.satisfaction = satisfaction
    }

    var body: some View {
        if let satisfaction = satisfaction {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= satisfaction ? "star.fill" : "star")
                        .foregroundColor(index <= satisfaction ? .yellow : .gray.opacity(0.3))
                        .font(.system(size: 20))
                }
            }
        }
    }
}

private struct WeatherSectionView: View {
    let weather: Weather?

    init(weather: Weather?) {
        self.weather = weather
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let weather = weather {
                VStack(spacing: 14) {
                    WeatherItemView(
                        icon: "thermometer",
                        value: String(format: "%.1f°C", weather.temperature)
                    )

                    WeatherItemView(
                        icon: "humidity",
                        value: "\(weather.humidity)%"
                    )

                    WeatherItemView(
                        icon: "wind",
                        value: String(format: "%.1fm/s", weather.windSpeed)
                    )
                }
            } else {
                Text("날씨 데이터 없음")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
    }
}

private struct WeatherItemView: View {
    let icon: String
    let value: String

    init(icon: String, value: String) {
        self.icon = icon
        self.value = value
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.caption)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
