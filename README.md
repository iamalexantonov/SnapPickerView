# SnapPickerView

Simple SwiftUI only horizontal scroll picker with snapping. Supports iOS 14+, MacOS 11+.
- Dragging with snap to views
- Clicking on views to scroll immediately
- Colored selector of current value

## Installation

1. Go in menu **File** and select **Add Packages...** item;
2. Enter https://github.com/iamalexantonov/SnapPickerView.git in Search text field;
3. Add at the beggining of your view:
    import SnapPickerView
4. Use it in your code.

## Usage Example

```swift
import SwiftUI
import SnapPickerView

struct ContentView: View {
    @State private var currentItem: String
    let times: ["19:00", "19:30", "20:00", "20:30", "21:00"]

    init(times: [String]) {
        self.times = times
        self.currentItem = times.first ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Selected time: \(currentItem)")
                .padding()
            SnapPickerView(currentItem: $currentItem, items: times, itemWidth: 80, itemHeight: 20, spacing: 80, componentWidth: UIScreen.main.bounds.width, selectorColor: .green) { item in
                Text(item)
            }
        }
    }
}
```
