# MatchedPopover

A lightweight SwiftUI helper for building **matched-geometry popovers** with a clean and reusable API.

`MatchedPopover` lets you attach a popover to any view using `matchedGeometryEffect`, while keeping the presentation logic simple and driven by a single source of truth — just like `sheet(item:)`.

<img src="https://github.com/Livsy90/MatchedPopover/blob/main/MATCHEDPOPOVERDEMO.gif" height="250">

---

## Features

- Matched-geometry based popover animation
- Automatic anchor pairing (source ↔ popover)
- Single source of truth via `Binding<ID?>`
- Full-screen background tap dismissal
- Minimal public API
- iOS 17+ only

---

## Installation

Copy `MatchedPopover` into your project or add it as a Swift Package.

**SPM (example):**

```

[https://github.com/your-username/MatchedPopover](https://github.com/your-username/MatchedPopover)

````

---

## Usage

### Define your popover target

```swift
enum PopoverTarget: String {
    case view1
    case view2
    case view3

    var anchor: UnitPoint {
        switch self {
        case .view1: .leading
        case .view2: .top
        case .view3: .bottom
        }
    }
}
````

---

### Add a selection state

```swift
@State private var selection: PopoverTarget?
```

---

### Mark anchor views

```swift
button(.view1)
    .matchedPopoverSource(
        id: .view1,
        anchor: PopoverTarget.view1.anchor
    )
```

---

### 4️⃣ Attach the popover container

```swift
.matchedPopover(
    selection: $selection,
    anchor: { $0.anchor }
) { id in
    Text("Popover: \(id.rawValue)")
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .padding()
}
```

---

##  How It Works

* Each anchor view uses `matchedGeometryEffect`

* The container renders the popover in an overlay

* Anchor pairing is automatic (`sourceAnchor.opposite`)

* Switching popovers always follows:

  ```
  hide current → show new
  ```

* Tapping anywhere on the screen dismisses the popover

---

## Behavior

* Switching between targets is deterministic
* No "travel morph" animation
* Background tap always dismisses
* Fully controlled via:

```swift
selection: Binding<ID?>
```

---

## Requirements

* iOS 17+
* SwiftUI

---

## 🔗 Repository

GitHub:

[https://github.com/Livsy90/MatchedPopover](https://github.com/your-username/MatchedPopover)

---

## 📄 License

MIT License
