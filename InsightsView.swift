import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeEntry.startTime) private var allEntries: [TimeEntry]
    @StateObject private var service = TimelineService()
    @State private var selectedPeriod: InsightPeriod = .week
    
    enum InsightPeriod: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
    }
    
    private var todayEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.startTime) }
    }
    
    private var periodEntries: [TimeEntry] {
        let cal = Calendar.current
        let now = Date.now
        switch selectedPeriod {
        case .today:
            return allEntries.filter { cal.isDateInToday($0.startTime) }
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now))!
            return allEntries.filter { $0.startTime >= start }
        case .month:
            let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: now))!
            return allEntries.filter { $0.startTime >= start }
        }
    }
    
    private var categoryBreakdown: [(ActivityCategory, TimeInterval)] {
        let grouped = Dictionary(grouping: periodEntries.filter { $0.entryType != .untracked }, by: { $0.category })
        return grouped.mapValues { $0.reduce(0) { $0 + $1.duration } }
            .sorted { $0.value > $1.value }
    }
    
    private var todayCoverage: DayCoverage {
        service.dayCoverage(for: .now, entries: todayEntries)
    }
    
    private var weekDayCoverages: [(Date, Double)] {
        let cal = Calendar.current
        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: -6 + offset, to: cal.startOfDay(for: .now))!
            let dayEntries = allEntries.filter { cal.isDate($0.startTime, inSameDayAs: date) }
            let coverage = service.dayCoverage(for: date, entries: dayEntries)
            return (date, coverage.coverageRate)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Insights")
                                .font(TSFonts.display(28))
                                .foregroundStyle(TSColors.textPrimary)
                            Spacer()
                        }
                        .padding(.top, 56)
                        
                        // Period selector
                        HStack(spacing: 0) {
                            ForEach(InsightPeriod.allCases, id: \.self) { period in
                                Button {
                                    withAnimation { selectedPeriod = period }
                                } label: {
                                    Text(period.rawValue)
                                        .font(TSFonts.body(14))
                                        .fontWeight(selectedPeriod == period ? .bold : .regular)
                                        .foregroundStyle(selectedPeriod == period ? TSColors.background : TSColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedPeriod == period ? TSColors.accent : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(4)
                        .background(TSColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        // Today's summary cards
                        if selectedPeriod == .today {
                            todaySummaryCards
                        }
                        
                        // Coverage bar chart
                        coverageChart
                        
                        // Category breakdown
                        categoryBreakdownSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Today Summary Cards
    private var todaySummaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Coverage",
                value: todayCoverage.coveragePercent,
                subtitle: "of day tracked",
                icon: "circle.dotted",
                color: TSColors.accent
            )
            StatCard(
                title: "Tracked",
                value: todayCoverage.totalTracked.hoursMinutesFormatted,
                subtitle: "total time",
                icon: "checkmark.circle.fill",
                color: TSColors.success
            )
            StatCard(
                title: "Untracked",
                value: todayCoverage.totalUntracked.hoursMinutesFormatted,
                subtitle: "missing time",
                icon: "questionmark.circle",
                color: TSColors.warning
            )
            StatCard(
                title: "Entries",
                value: "\(todayEntries.count)",
                subtitle: "recorded",
                icon: "list.bullet",
                color: TSColors.accentSecondary
            )
        }
    }
    
    // MARK: - Coverage Chart
    private var coverageChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Coverage")
                .font(TSFonts.headline(16))
                .foregroundStyle(TSColors.textPrimary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(TSColors.surface)
                
                if weekDayCoverages.allSatisfy({ $0.1 == 0 }) {
                    Text("No data yet")
                        .font(TSFonts.body(14))
                        .foregroundStyle(TSColors.textSecondary)
                        .padding(32)
                } else {
                    Chart {
                        ForEach(weekDayCoverages, id: \.0) { date, rate in
                            BarMark(
                                x: .value("Day", date, unit: .day),
                                y: .value("Coverage", rate * 100)
                            )
                            .foregroundStyle(
                                Calendar.current.isDateInToday(date)
                                ? LinearGradient(colors: [TSColors.accent, TSColors.accentSecondary], startPoint: .bottom, endPoint: .top)
                                : LinearGradient(colors: [TSColors.surfaceElevated, TSColors.surface], startPoint: .bottom, endPoint: .top)
                            )
                            .cornerRadius(6)
                        }
                        
                        RuleMark(y: .value("Target", 80))
                            .foregroundStyle(TSColors.accent.opacity(0.4))
                            .lineStyle(StrokeStyle(dash: [5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("80%")
                                    .font(TSFonts.mono(10))
                                    .foregroundStyle(TSColors.accent.opacity(0.6))
                            }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .foregroundStyle(TSColors.textSecondary)
                                .font(TSFonts.mono(10))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, 50, 100]) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))%")
                                        .font(TSFonts.mono(10))
                                        .foregroundStyle(TSColors.textSecondary)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 160)
                    .padding(16)
                }
            }
        }
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(TSFonts.headline(16))
                .foregroundStyle(TSColors.textPrimary)
            
            if categoryBreakdown.isEmpty {
                EmptyStateView(icon: "chart.pie", message: "No entries to show.")
            } else {
                let total = categoryBreakdown.reduce(0) { $0 + $1.1 }
                
                VStack(spacing: 8) {
                    ForEach(categoryBreakdown, id: \.0) { cat, dur in
                        CategoryBar(
                            category: cat,
                            duration: dur,
                            total: total
                        )
                    }
                }
                .padding(16)
                .background(TSColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(TSColors.surface)
            
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                
                Text(value)
                    .font(TSFonts.display(22))
                    .foregroundStyle(TSColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(TSFonts.body(11))
                    .foregroundStyle(TSColors.textSecondary)
            }
            .padding(14)
        }
    }
}

// MARK: - Category Bar
struct CategoryBar: View {
    let category: ActivityCategory
    let duration: TimeInterval
    let total: TimeInterval
    
    var fraction: Double { total > 0 ? duration / total : 0 }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: category.defaultColor))
                    .frame(width: 18)
                
                Text(category.displayName)
                    .font(TSFonts.body(13))
                    .foregroundStyle(TSColors.textPrimary)
                
                Spacer()
                
                Text(duration.hoursMinutesFormatted)
                    .font(TSFonts.mono(12))
                    .foregroundStyle(TSColors.textSecondary)
                
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(TSFonts.mono(12))
                    .foregroundStyle(TSColors.textPrimary)
                    .frame(width: 38, alignment: .trailing)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(TSColors.separator)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: category.defaultColor))
                        .frame(width: geo.size.width * fraction, height: 5)
                        .animation(.spring(duration: 0.6), value: fraction)
                }
            }
            .frame(height: 5)
        }
    }
}
