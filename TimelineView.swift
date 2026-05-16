import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeEntry.startTime) private var allEntries: [TimeEntry]
    @StateObject private var service = TimelineService()
    @State private var selectedDate: Date = .now
    @State private var showAddEntry = false
    @State private var selectedEntry: TimeEntry?
    @State private var scrollOffset: CGFloat = 0
    
    private var dateEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private var untrackedBlocks: [UntrackedBlock] {
        service.untrackedBlocks(for: selectedDate, entries: dateEntries)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    navigationHeader
                    datePicker
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                timeline24Hour
                                    .padding(.horizontal, 16)
                                Spacer(minLength: 100)
                            }
                            .id("top")
                        }
                        .onAppear {
                            // Scroll to current hour
                            let hour = Calendar.current.component(.hour, from: .now)
                            proxy.scrollTo("hour_\(max(0, hour - 2))", anchor: .top)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddEntry) {
                AddEntryView(defaultDate: selectedDate)
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }
    
    // MARK: - Nav Header
    private var navigationHeader: some View {
        HStack {
            Text("Timeline")
                .font(TSFonts.display(28))
                .foregroundStyle(TSColors.textPrimary)
            Spacer()
            Button {
                showAddEntry = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(TSColors.background)
                    .frame(width: 38, height: 38)
                    .background(TSColors.accent)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }
    
    // MARK: - Date Picker Strip
    private var datePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(-6...0, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
                    DateChip(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 24-hour Timeline
    private var timeline24Hour: some View {
        let hourHeight: CGFloat = 64
        let totalHeight: CGFloat = hourHeight * 24
        
        return ZStack(alignment: .topLeading) {
            // Background grid
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HourRow(hour: hour, height: hourHeight)
                        .id("hour_\(hour)")
                }
            }
            
            // Entry blocks
            GeometryReader { geo in
                let width = geo.size.width - 52 // account for time labels
                
                ForEach(dateEntries) { entry in
                    let cal = Calendar.current
                    let dayStart = cal.startOfDay(for: selectedDate)
                    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
                    let totalSecs = dayEnd.timeIntervalSince(dayStart)
                    
                    let startFrac = entry.startTime.timeIntervalSince(dayStart) / totalSecs
                    let endFrac = entry.endTime.timeIntervalSince(dayStart) / totalSecs
                    let height = max(20, (endFrac - startFrac) * totalHeight)
                    let yOffset = startFrac * totalHeight
                    
                    TimelineBlock(entry: entry, width: width, height: height) {
                        selectedEntry = entry
                    }
                    .offset(x: 52, y: yOffset)
                }
                
                // Untracked blocks
                ForEach(untrackedBlocks) { block in
                    let cal = Calendar.current
                    let dayStart = cal.startOfDay(for: selectedDate)
                    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
                    let totalSecs = dayEnd.timeIntervalSince(dayStart)
                    
                    let startFrac = block.startTime.timeIntervalSince(dayStart) / totalSecs
                    let endFrac = block.endTime.timeIntervalSince(dayStart) / totalSecs
                    let height = max(8, (endFrac - startFrac) * totalHeight)
                    let yOffset = startFrac * totalHeight
                    
                    UntrackedBlock24h(block: block, width: width, height: height) {
                        service.fillUntracked(block, context: context)
                    }
                    .offset(x: 52, y: yOffset)
                }
                
                // Current time indicator (today only)
                if Calendar.current.isDateInToday(selectedDate) {
                    let frac = Date.now.fractionOfDay()
                    CurrentTimeIndicator(width: width + 52)
                        .offset(y: frac * totalHeight - 1)
                }
            }
            .frame(height: totalHeight)
        }
        .frame(height: totalHeight)
    }
}

// MARK: - Hour Row
struct HourRow: View {
    let hour: Int
    let height: CGFloat
    
    var label: String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        default:
            if hour < 12 { return "\(hour)a" }
            return "\(hour - 12)p"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(TSFonts.mono(10))
                .foregroundStyle(TSColors.textSecondary)
                .frame(width: 32, alignment: .trailing)
            
            Rectangle()
                .fill(TSColors.separator)
                .frame(height: 0.5)
        }
        .frame(height: height, alignment: .top)
    }
}

// MARK: - Timeline Block
struct TimelineBlock: View {
    let entry: TimeEntry
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: entry.colorHex).opacity(0.85))
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: entry.colorHex), lineWidth: 1)
                
                if height > 28 {
                    HStack(spacing: 6) {
                        Image(systemName: entry.category.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text(entry.title)
                            .font(TSFonts.body(11))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(height > 50 ? 2 : 1)
                        
                        Spacer()
                        
                        if height > 44 {
                            Text(entry.formattedDuration)
                                .font(TSFonts.mono(10))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                }
            }
        }
        .frame(width: width - 4, height: height)
        .padding(.leading, 2)
    }
}

// MARK: - Untracked Block 24h
struct UntrackedBlock24h: View {
    let block: UntrackedBlock
    let width: CGFloat
    let height: CGFloat
    let onFill: () -> Void
    
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 6)
                .fill(TSColors.warning.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(TSColors.warning.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            
            if height > 32 {
                HStack(spacing: 4) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 9))
                        .foregroundStyle(TSColors.warning.opacity(0.7))
                    Text(block.formattedDuration)
                        .font(TSFonts.mono(10))
                        .foregroundStyle(TSColors.warning.opacity(0.7))
                }
            }
        }
        .frame(width: width - 4, height: height)
        .padding(.leading, 2)
        .onTapGesture {
            onFill()
        }
    }
}

// MARK: - Current Time Indicator
struct CurrentTimeIndicator: View {
    let width: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(TSColors.danger)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(TSColors.danger)
                .frame(height: 1.5)
        }
        .frame(width: width)
    }
}

// MARK: - Date Chip
struct DateChip: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    var dayName: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(TSFonts.body(10))
                    .foregroundStyle(isSelected ? TSColors.background : TSColors.textSecondary)
                Text(dayNumber)
                    .font(TSFonts.headline(16))
                    .foregroundStyle(isSelected ? TSColors.background : TSColors.textPrimary)
            }
            .frame(width: 46, height: 56)
            .background(isSelected ? TSColors.accent : TSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
