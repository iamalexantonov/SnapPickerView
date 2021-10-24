//
//  SnapPickerView.swift
//  SnapPickerView
//
//  Created by Alexey Antonov on 23/10/21.
//

import SwiftUI
import Combine

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
    
    /**
    Initializer of the **SnapPickerView** struct
     
    - parameters:
     - currentItem: should conform to Hashable protocol, use @State or @Binding variables in the view (**warning**: setter does not work);
     - items: an array of items of the same type as _currentItem_ wrapped value;
     - itemWidth: CGFloat value of the width of each item;
     - itemHeight: CGFloat value of the height of each item;
     - spacing: CGFloat value of the spacing between items;
     - componentWidth: CGFloat value of the width of the component;
     - selectorRadius: CGFloat value of corner radius of the rounded rectangle selection view (optional, default: 20),
     - selectorColor: Color value of the selection view,
     - selectionLineWidth: CGFloat value of the stroke width of rounded rectangle selection view (optional, default: 1)
     - itemView: view of each item that gives current item and builds a SwiftUI view for it
     */
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
        SnapScrollView(items: items, itemWidth: itemWidth, itemSpacing: spacing, screenWidth: componentWidth, onItemChanged: { currentItem = items[$0] }) { item in
            itemView(item)
                .frame(height: itemHeight)
        }
        .frame(width: componentWidth)
        .overlay(RoundedRectangle(cornerRadius: selectorRadius).stroke(lineWidth: selectorLineWidth).foregroundColor(selectorColor).frame(width: itemWidth + 15, height: itemHeight + 10))
    }
}

struct SnapScrollView<Content: View, Item: Hashable>: View {
    @State private var dragOffset: CGFloat = 0
    @StateObject private var viewModel: PickerViewModel<Item>

    let items: [Item]
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    let content: (Item)->Content
    
    private let contentWidth: CGFloat
    private let initialOffset: CGFloat
    
    init(items: [Item], itemWidth: CGFloat, itemSpacing: CGFloat, screenWidth: CGFloat, onItemChanged: @escaping (Int)->Void, @ViewBuilder content: @escaping (Item)->Content) {
        _viewModel = StateObject<PickerViewModel>(wrappedValue: PickerViewModel(items: items, itemWidth: itemWidth, itemSpacing: itemSpacing, onItemChanged: onItemChanged))
        
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
                            viewModel.scrollOffset = calculateScrollOffset(for: index)
                        }
                    }
            }
        }
        .offset(x: initialOffset + viewModel.scrollOffset + dragOffset, y: 0)
            .gesture(DragGesture()
                .onChanged({ event in
                    dragOffset = event.translation.width
                })
                .onEnded({ event in
                    dragOffset = 0
                if abs(event.translation.width) > itemWidth / 2 + itemSpacing / 2 && (calculateScrollOffset(for: items.count-1)...0).contains(viewModel.scrollOffset + event.translation.width) {
                        viewModel.scrollOffset += event.translation.width
                    }
                })
            )
    }
    
    private func calculateScrollOffset(for index: Int) -> CGFloat {
        -CGFloat(index) * (itemWidth + itemSpacing)
    }
}

class PickerViewModel<T: Hashable>: ObservableObject {
    let items: [T]
    let itemWidth: CGFloat
    let itemSpacing: CGFloat
    let onItemChanged: (Int)->Void
    
    @Published var scrollOffset: CGFloat = 0
    
    init(items: [T], itemWidth: CGFloat, itemSpacing: CGFloat, onItemChanged: @escaping (Int)->Void) {
        self.items = items
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self.onItemChanged = onItemChanged
        
        $scrollOffset
            .removeDuplicates()
            .filter {
                let maxOffset = -CGFloat(items.count - 1) * (itemWidth + itemSpacing)
                return (maxOffset...0).contains($0)
            }
            .map { offset->Int in
                var index = Int(round(-offset / (itemWidth + itemSpacing)))
                index = min(index, items.count - 1)
                index = max(index, 0)
                
                return index
            }
            .handleEvents(receiveOutput: { [weak self] index in
                self?.onItemChanged(index)
            })
            .map { index->CGFloat in
                let maxOffset = -CGFloat(items.count - 1) * (itemWidth + itemSpacing)
                let newOffset = -CGFloat(index) * (itemWidth + itemSpacing)
                return min(max(maxOffset, newOffset),0)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] offset in
                self?.scrollOffset = offset
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
}
