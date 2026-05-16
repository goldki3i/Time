import Foundation
import SwiftData
import SwiftUI

// MARK: - Timeline Service
@MainActor
class TimelineService: ObservableObject {
    
    // Returns all entries for a given day, sorted by startTime
    func entries(for date: Date, context: ModelContext) -> [TimeEntry] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { entry in
                entry.startTime >= startOfDay && entry.startTime < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // Returns untracked blocks for a given day
    func untrackedBlocks(for date: Date, entries: [TimeEntry]) -> [UntrackedBlock] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        
        var blocks: [UntrackedBlock] = []
        let sorted = entries
            .filter { $0.entryType != .untracked }
            .sorted { $0.startTime < $1.startTime }
        
        var cursor = dayStart
        
        for entry in sorted {
            let start = max(entry.startTime, dayStart)
            let end = min(entry.endTime, dayEnd)
            
            if cursor < start {
                let gap = start.timeIntervalSince(cursor)
                if gap >= 60 { // Only gaps >= 1 minute
                    blocks.append(UntrackedBlock(startTime: cursor, endTime: start))
                }
            }
            cursor = max(cursor, end)
        }
        
        if cursor < dayEnd {
            let gap = dayEnd.timeIntervalSince(cursor)
            if gap >= 60 {
                // Only show remaining untracked if it's in the past (or near future)
                let now = Date.now
                if cursor < now {
                    let endTime = min(dayEnd, now)
                    if endTime > cursor {
                        blocks.append(UntrackedBlock(startTime: cursor, endTime: endTime))
                    }
                }
            }
        }
        
        return blocks
    }
    
    // Calculates coverage for a day
    func dayCoverage(for date: Date, entries: [TimeEntry]) -> DayCoverage {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let now = Date.now
        let effectiveEnd = min(dayEnd, now)
        
        // Calculate total tracked time, merging overlapping entries
        let totalDay: TimeInterval = effectiveEnd.timeIntervalSince(dayStart)
        let tracked = mergedDuration(entries: entries, in: dayStart...effectiveEnd)
        let untracked = max(0, totalDay - tracked)
        
        return DayCoverage(
            date: date,
            totalTracked: tracked,
            totalUntracked: untracked,
            entries: entries
        )
    }
    
    private func mergedDuration(entries: [TimeEntry], in range: ClosedRange<Date>) -> TimeInterval {
        let sorted = entries
            .filter { $0.entryType != .untracked }
            .compactMap { entry -> (Date, Date)? in
                let s = max(entry.startTime, range.lowerBound)
                let e = min(entry.endTime, range.upperBound)
                return s < e ? (s, e) : nil
            }
            .sorted { $0.0 < $1.0 }
        
        var total: TimeInterval = 0
        var cursor = range.lowerBound
        
        for (s, e) in sorted {
            if s > cursor {
                cursor = s
            }
            if e > cursor {
                total += e.timeIntervalSince(cursor)
                cursor = e
            }
        }
        return total
    }
    
    // Detects overlapping entries
    func overlaps(newStart: Date, newEnd: Date, excluding id: UUID? = nil, entries: [TimeEntry]) -> [TimeEntry] {
        entries.filter { entry in
            if let id, entry.id == id { return false }
            return entry.startTime < newEnd && entry.endTime > newStart
        }
    }
    
    // Adds a new time entry
    func addEntry(
        title: String,
        startTime: Date,
        endTime: Date,
        category: ActivityCategory,
        entryType: EntryType = .manual,
        notes: String = "",
        context: ModelContext
    ) {
        let entry = TimeEntry(
            startTime: startTime,
            endTime: endTime,
            title: title,
            entryType: entryType,
            category: category,
            colorHex: category.defaultColor,
            notes: notes
        )
        context.insert(entry)
        try? context.save()
    }
    
    // Deletes a time entry
    func deleteEntry(_ entry: TimeEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }
    
    // Stops active timer and saves as entry
    func stopTimer(_ timer: ActiveTimer, title: String, category: ActivityCategory, context: ModelContext) {
        let entry = TimeEntry(
            startTime: timer.startTime,
            endTime: .now,
            title: title.isEmpty ? "Untitled" : title,
            entryType: .timer,
            category: category,
            colorHex: category.defaultColor
        )
        context.insert(entry)
        context.delete(timer)
        try? context.save()
    }
    
    // Fill untracked block as "untracked"
    func fillUntracked(_ block: UntrackedBlock, context: ModelContext) {
        let entry = TimeEntry(
            startTime: block.startTime,
            endTime: block.endTime,
            title: "Untracked Time",
            entryType: .untracked,
            category: .other,
            colorHex: "#BDBDBD",
            isManual: false
        )
        context.insert(entry)
        try? context.save()
    }
}

// MARK: - Screen Time Mock Service
// Real Screen Time import requires FamilyControls entitlement.
// This service provides sample/demo data and a structure for real integration.
class ScreenTimeService {
    
    static func importSampleData(for date: Date, context: ModelContext) {
        let cal = Calendar.current
        let base = cal.startOfDay(for: date)
        
        func t(_ h: Int, _ m: Int) -> Date {
            cal.date(byAdding: .minute, value: h * 60 + m, to: base)!
        }
        
        let sampleApps: [(String, String, Date, Date, ActivityCategory)] = [
            ("Safari", "com.apple.mobilesafari", t(8, 0), t(8, 45), .screenTime),
            ("Messages", "com.apple.MobileSMS", t(9, 30), t(9, 50), .social),
            ("YouTube", "com.google.ios.youtube", t(12, 0), t(12, 40), .entertainment),
            ("Spotify", "com.spotify.client", t(14, 0), t(15, 0), .entertainment),
            ("Mail", "com.apple.mobilemail", t(16, 0), t(16, 20), .work),
            ("TikTok", "com.zhiliaoapp.musically", t(21, 0), t(21, 45), .entertainment),
        ]
        
        for (name, bundle, start, end, cat) in sampleApps {
            let entry = TimeEntry(
                startTime: start,
                endTime: end,
                title: name,
                entryType: .screenTime,
                category: cat,
                colorHex: cat.defaultColor,
                appBundleID: bundle,
                isManual: false
            )
            context.insert(entry)
        }
        try? context.save()
    }
}
