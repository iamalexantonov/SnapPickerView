//
//  SnapPickerView.swift
//  CafeApp
//
//  Created by Alexey Antonov on 23/10/21.
//

import SwiftUI

public struct SnapPickerView<Content: View, Item: Hashable>: View {
    @Binding var currentItem: Item
    private let items: [Item]
    private let itemWidth: CGFloat
    private let itemHeight: CGFloat
    private let spacing: CGFloat
    private let componentWidth: CGFloat
    private let selectorRadius: CGFloat
    private let selectorColor: Color
    private let selectorLineWidth: CGFloat
    private let itemView: (Item)->Content
    
    public init(currentItem: Binding<Item>, items: [Item], itemWidth: CGFloat, itemHeight: CGFloat, spacing: CGFloat, componentWidth: CGFloat, selectorRadius: CGFloat = 20, selectorColor: Color, selectorLineWidth: CGFloat = 1, @ViewBuilder itemView: @escaping (Item)->Content) {
        _currentItem = currentItem
        self.items = items
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.spacing = spacing
        self.componentWidth = componentWidth
        self.selectorRadius = selectorRadius
        self.selectorColor = selectorColor
        self.selectorLineWidth = selectorLineWidth
        self.itemView = itemView
    }
    
    public var body: some View {
        SnapScrollView(currentItemIndex: Binding<Int>(get: { if let currentIndex = items.firstIndex(of: currentItem) { return currentIndex } else { return 0 } }, set: { currentItem = items[$0] }), items: items, itemWidth: itemWidth, itemSpacing: spacing, screenWidth: componentWidth) { item in
            itemView(item)
        }
        .overlay(RoundedRectangle(cornerRadius: selectorRadius).stroke(lineWidth: selectorLineWidth).frame(width: itemWidth + 10, height: itemHeight + 10))
    }
}

struct SnapScrollView<Content: View, Item: Hashable>: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    
    @Binding var currentItemIndex: Int
    let items: [Item]
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    let content: (Item)->Content
    
    private let contentWidth: CGFloat
    private let initialOffset: CGFloat
    
    init(currentItemIndex: Binding<Int>, items: [Item], itemWidth: CGFloat, itemSpacing: CGFloat, screenWidth: CGFloat, @ViewBuilder content: @escaping (Item)->Content) {
        _currentItemIndex = currentItemIndex
        self.items = items
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self.content = content
        self.contentWidth = CGFloat(items.count) * itemWidth + CGFloat(items.count - 1) * itemSpacing
        initialOffset = (self.contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)
    }
    
    var body: some View {
        HStack(spacing: itemSpacing) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .frame(width: itemWidth)
                    .onTapGesture {
                        if let index = items.firstIndex(of: item) {
                            if currentItemIndex != index {
                                currentItemIndex = Int(index)
                            }
                        }
                    }
            }
        }
            .offset(x: initialOffset + scrollOffset + dragOffset, y: 0)
            .gesture(DragGesture()
                .onChanged({ event in
                    dragOffset = event.translation.width
                })
                .onEnded({ event in
                dragOffset = 0
                if abs(event.translation.width) > itemWidth / 2 + itemSpacing / 2 {
                    scrollOffset += event.translation.width
                    var index = Int(round(-scrollOffset / (itemWidth + itemSpacing)))
                    index = min(index, items.count - 1)
                    index = max(index, 0)
                    
                    currentItemIndex = index
                }
                })
            )
            .onChange(of: currentItemIndex) { newValue in
                withAnimation {
                    scrollOffset = calculateScrollOffset(for: newValue)
                }
            }
            .onChange(of: scrollOffset) { newValue in
                var newOffset = max(newValue, calculateScrollOffset(for: items.count - 1))
                newOffset = min(newOffset, 0)
                
                scrollOffset = newOffset
            }
    }
    
    private func calculateScrollOffset(for index: Int) -> CGFloat {
        -CGFloat(index) * (itemWidth + itemSpacing)
    }
}
