//
//  RecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import Models
import SwiftUI

struct RecordView: View {
    let record: RunningRecord
    let onEdit: () -> Void

    init(record: RunningRecord, onEdit: @escaping () -> Void = {}) {
        self.record = record
        self.onEdit = onEdit
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 26) {
                // HealthKit 데이터
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 20) {
                        RecordRowView(title: "거리", value: record.distanceInKilometers.to2f)
                        RecordRowView(title: "소요시간", value: record.formattedDuration)
                    }

                    HStack(spacing: 20) {
                        RecordRowView(title: "평균 페이스", value: record.averagePace)
                        RecordRowView(title: "평균 심박수", value: "\(record.averageHeartRate) bpm")
                    }

                    HStack(spacing: 20) {
                        RecordRowView(title: "평균 케이던스", value: "\(record.averageCadence) spm")
                    }
                }

                Divider()

                // 날씨 데이터
                if let weather = record.weather {
                    WeatherSectionView(weather: weather)
                }

                Divider()

                // 주법
                if let style = record.runningStyle {
                    DetailRowView(title: "주법", value: style.rawValue)
                }

                // 통증 부위
                if !record.painAreas.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("통증 부위")
                            .foregroundColor(.gray)

                        DynamicGridLayout(items: record.painAreas) { item in
                            Text(item.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue700.opacity(0.1))
                                .foregroundColor(.blue700)
                                .cornerRadius(8)
                        }
                    }
                }

                // 신발
                if let shoes = record.shoes {
                    DetailRowView(title: "착용 신발", value: shoes)
                }

                Divider()

                // 수면시간, 식사여부, 음주여부
                VStack(alignment: .leading, spacing: 14) {
                    if let sleep = record.condition.sleep {
                        DetailRowView(title: "수면", value: "\(sleep)시간")
                    }

                    DetailIconRowView(title: "식사", isChecked: record.condition.meal)
                    DetailIconRowView(title: "음주", isChecked: record.condition.alcohol)
                }

//                Divider()

                // 운동 강도
//                DifficultyLevelView(difficultyLevel: record.difficultyLevel?.rawValue)

                // 지도
//                if record.hasMap {
//                    Rectangle()
//                        .fill(Color.gray100)
//                        .frame(height: 200)
//                        .cornerRadius(12)
//                        .overlay(
//                            Text("지도 영역")
//                                .foregroundColor(.gray)
//                        )
//                }

                // 메모
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
                    .padding(.vertical)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(.vertical, 18)
            .padding(.horizontal, 14)

            // 수정 버튼
            EditButton(onEdit: onEdit)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
    }
}

private struct EditButton: View {
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            ZStack {
                Circle()
                    .foregroundColor(.blue300)

                Image(systemName: "pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .fixedSize()
        }
    }
}

private struct Container<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray500)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue700)
            }
            .padding(.leading, 4)
            Spacer()
        }
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
                .foregroundColor(.gray500)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.gray700)
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
                .foregroundColor(isChecked ? .blue700 : .gray300)
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

private struct DifficultyLevelView: View {
    let difficultyLevel: Int?

    init(difficultyLevel: Int?) {
        self.difficultyLevel = difficultyLevel
    }

    var body: some View {
        if let difficultyLevel = difficultyLevel {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= difficultyLevel ? "star.fill" : "star")
                        .foregroundColor(index <= difficultyLevel ? .yellow : .gray.opacity(0.3))
                        .font(.system(size: 20))
                }
            }
        }
    }
}

private struct WeatherSectionView: View {
    let weather: WeatherData

    init(weather: WeatherData) {
        self.weather = weather
    }

    var body: some View {
        HStack(spacing: 0) {
            WeatherItemView(
                icon: "thermometer",
                title: "기온",
                value: String(format: "%.1f°C", weather.temperature)
            )

            Spacer()
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.gray100)
            Spacer()

            WeatherItemView(
                icon: "humidity.fill",
                title: "습도",
                value: "\(weather.humidity)%"
            )

            Spacer()
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.gray100)
            Spacer()

            WeatherItemView(
                icon: "wind",
                title: "풍속",
                value: String(format: "%.1fm/s", weather.windSpeed)
            )
        }
        .padding(.horizontal)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct WeatherItemView: View {
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

// MARK: - Preview

#Preview(traits: .sampleData) {
    ScrollView(.vertical) {
        RecordView(record: RunningRecordModel.preview.toDomain())
    }
}
