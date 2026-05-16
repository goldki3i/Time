# TimeSalad — iOS App

## Overview
TimeSalad is a SwiftUI + SwiftData iOS app that helps you track every hour of your day.  
It combines manual logging, a built-in timer, Screen Time import, and automatic gap detection to give you a full 24-hour picture of how you spend your time.

---

## Features

### 1. 24-Hour Timeline (`TimelineView`)
- Visual block timeline from midnight to midnight
- Color-coded entries by category
- A red current-time indicator for today
- Tap any block to view or edit details
- Tap untracked (dashed) blocks to fill them instantly
- 7-day date strip to browse recent days

### 2. Screen Time Import (`ScreenTimeImportView`)
- Demo import of realistic Screen Time data (Safari, YouTube, Messages, etc.)
- Production path documented: requires `FamilyControls` entitlement from Apple
- Import for any past date

### 3. Timer (`TimerView`)
- Start/stop timer with live elapsed display
- Set title and category while recording
- Auto-saves to SwiftData as a `TimeEntry` on stop
- Persistent across app background/foreground via SwiftData

### 4. Manual Entry (`AddEntryView`)
- Full time range picker (start/end)
- Quick duration buttons: 15m / 30m / 1h / 1.5h / 2h
- Category picker with icons and colors
- Overlap detection with visual warning
- Optional notes

### 5. Untracked Block Detection
- Automatically finds gaps in the timeline
- Shows in "Today" view and overlaid on the 24h timeline
- "Fill" button marks a gap as "Untracked Time"
- "Add" button opens entry sheet pre-filled for the gap

### 6. Coverage Rate (`TodayView`)
- Animated ring showing % of elapsed day that is tracked
- Tracked vs. untracked hours
- Entry count for the day

### 7. 24-Hour Fill Guarantee
- All entries combined with untracked markers account for the full day
- Timeline merges overlapping entries when calculating coverage
- Coverage is based on elapsed time (not full future day)

---

## Architecture

```
TimeSalad/
├── TimeSaladApp.swift          — App entry, ModelContainer setup
├── Models/
│   └── Models.swift            — TimeEntry, ActiveTimer, ActivityCategory, EntryType
├── Services/
│   └── TimelineService.swift   — Business logic: coverage, gaps, CRUD, Screen Time mock
├── Views/
│   ├── ContentView.swift       — Tab navigation
│   ├── TodayView.swift         — Dashboard: ring, stats, gaps, recent entries
│   ├── TimelineView.swift      — 24h block timeline
│   ├── TimerView.swift         — Live timer recording
│   ├── AddEntryView.swift      — Manual time entry form
│   ├── EntryDetailView.swift   — Entry detail + edit + delete
│   ├── InsightsView.swift      — Charts: coverage trend, category breakdown
│   └── ScreenTimeImportView.swift — Screen Time import UI
└── Utilities/
    └── Extensions.swift        — Color(hex:), Date helpers, TSColors, TSFonts
```

### Data Layer
- **SwiftData** with two models: `TimeEntry` and `ActiveTimer`
- `TimelineService` is a `@MainActor ObservableObject` providing all timeline logic
- No external dependencies required

---

## Setup in Xcode

1. Create a new **iOS App** project in Xcode 15+
2. Set **Interface: SwiftUI**, **Storage: SwiftData**
3. Set minimum deployment target to **iOS 17.0**
4. Add all `.swift` files from each folder into the project
5. Build and run on Simulator or device

### Optional: Real Screen Time
To enable real Screen Time data:
1. Add **Family Controls** capability in Signing & Capabilities
2. Request entitlement from Apple: https://developer.apple.com/contact/request/family-controls-distribution
3. Use `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
4. Use `DeviceActivityReport` and `ManagedSettingsStore` APIs from `DeviceActivity` framework

---

## Design System

| Token | Value |
|-------|-------|
| Background | `#0E0E12` |
| Surface | `#1A1A22` |
| Accent (lime) | `#C8FF57` |
| Accent2 (blue) | `#57C8FF` |
| Danger | `#FF5757` |
| Warning | `#FFB347` |
| Success | `#57FF9A` |
| Font | SF Rounded (system) |

---

## License
MIT — free to use, modify, and distribute.
