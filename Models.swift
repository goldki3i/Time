import Foundation
import SwiftData

// MARK: - TimeEntry Model
@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var title: String
    var entryType: EntryType
    var category: ActivityCategory
    var colorHex: String
    var notes: String
    var appBundleID: String? // For Screen Time imports
    var isManual: Bool
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        title: String,
        entryType: EntryType = .manual,
        category: ActivityCategory = .other,
        colorHex: String = "#4A90D9",
        notes: String = "",
        appBundleID: String? = nil,
        isManual: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.entryType = entryType
        self.category = category
        self.colorHex = colorHex
        self.notes = notes
        self.appBundleID = appBundleID
        self.isManual = isManual
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var durationMinutes: Double {
        duration / 60
    }
    
    var durationHours: Double {
        duration / 3600
    }
    
    var formattedDuration: String {
        let hours = Int(durationHours)
        let mins = Int(durationMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    var timeRangeString: String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return "\(fmt.string(from: startTime)) – \(fmt.string(from: endTime))"
    }
}

// MARK: - Entry Type
enum EntryType: String, Codable, CaseIterable {
    case manual = "manual"
    case timer = "timer"
    case screenTime = "screenTime"
    case untracked = "untracked"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .timer: return "Timer"
        case .screenTime: return "Screen Time"
        case .untracked: return "Untracked"
        }
    }
    
    var iconName: String {
        switch self {
        case .manual: return "pencil"
        case .timer: return "timer"
        case .screenTime: return "apps.iphone"
        case .untracked: return "questionmark.circle"
        }
    }
}

// MARK: - Activity Category
enum ActivityCategory: String, Codable, CaseIterable {
    case sleep = "sleep"
    case work = "work"
    case exercise = "exercise"
    case meals = "meals"
    case social = "social"
    case learning = "learning"
    case entertainment = "entertainment"
    case transport = "transport"
    case selfCare = "selfCare"
    case screenTime = "screenTime"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .work: return "Work"
        case .exercise: return "Exercise"
        case .meals: return "Meals"
        case .social: return "Social"
        case .learning: return "Learning"
        case .entertainment: return "Entertainment"
        case .transport: return "Transport"
        case .selfCare: return "Self Care"
        case .screenTime: return "Screen Time"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .work: return "briefcase.fill"
        case .exercise: return "figure.run"
        case .meals: return "fork.knife"
        case .social: return "person.2.fill"
        case .learning: return "book.fill"
        case .entertainment: return "popcorn.fill"
        case .transport: return "car.fill"
        case .selfCare: return "heart.fill"
        case .screenTime: return "apps.iphone"
        case .other: return "circle.fill"
        }
    }
    
    var defaultColor: String {
        switch self {
        case .sleep: return "#5B4FD4"
        case .work: return "#2D9CDB"
        case .exercise: return "#27AE60"
        case .meals: return "#F2994A"
        case .social: return "#EB5757"
        case .learning: return "#6FCF97"
        case .entertainment: return "#BB6BD9"
        case .transport: return "#4F9DDE"
        case .selfCare: return "#F2728A"
        case .screenTime: return "#56CCF2"
        case .other: return "#BDBDBD"
        }
    }
}

// MARK: - Active Timer Model
@Model
final class ActiveTimer {
    var id: UUID
    var startTime: Date
    var title: String
    var category: ActivityCategory
    var colorHex: String
    var isRunning: Bool
    
    init(
        id: UUID = UUID(),
        startTime: Date = .now,
        title: String = "",
        category: ActivityCategory = .other,
        colorHex: String = "#4A90D9",
        isRunning: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.title = title
        self.category = category
        self.colorHex = colorHex
        self.isRunning = isRunning
    }
    
    var elapsed: TimeInterval {
        Date.now.timeIntervalSince(startTime)
    }
    
    var formattedElapsed: String {
        let totalSeconds = Int(elapsed)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - UntrackedBlock
struct UntrackedBlock: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var durationMinutes: Double { duration / 60 }
    
    var formattedDuration: String {
        let hours = Int(durationMinutes / 60)
        let mins = Int(durationMinutes) % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
    
    var timeRangeString: String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return "\(fmt.string(from: startTime)) – \(fmt.string(from: endTime))"
    }
}

// MARK: - Day Coverage
struct DayCoverage {
    let date: Date
    let totalTracked: TimeInterval
    let totalUntracked: TimeInterval
    let entries: [TimeEntry]
    
    var coverageRate: Double {
        totalTracked / (24 * 3600)
    }
    
    var coveragePercent: String {
        String(format: "%.0f%%", coverageRate * 100)
    }
    
    var trackedHours: Double { totalTracked / 3600 }
    var untrackedHours: Double { totalUntracked / 3600 }
}
