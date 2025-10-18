//
//  DynamicGridLayout.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

/// 항목들이 가로로 배치되다가 공간이 부족하면 자동으로 다음 줄로 넘어가는 동적 그리드 레이아웃
struct DynamicGridLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = 0
    
    init(items: Data, content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                GridContent(
                    items: items,
                    content: content,
                    geometry: geometry,
                    totalHeight: $totalHeight
                )
            }
        }
        .frame(height: totalHeight)
    }
}

private struct GridContent<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    let geometry: GeometryProxy
    @Binding var totalHeight: CGFloat
    
    init(items: Data, content: @escaping (Data.Element) -> Content, geometry: GeometryProxy, totalHeight: Binding<CGFloat>) {
        self.items = items
        self.content = content
        self.geometry = geometry
        self._totalHeight = totalHeight
    }
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                content(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if index == items.count - 1 {
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == items.count - 1 {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(HeightReader(totalHeight: $totalHeight))
    }
}

private struct HeightReader: View {
    @Binding var totalHeight: CGFloat
    
    init(totalHeight: Binding<CGFloat>) {
        self._totalHeight = totalHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    let rect = geometry.frame(in: .local)
                    totalHeight = rect.size.height
                }
        }
    }
}
