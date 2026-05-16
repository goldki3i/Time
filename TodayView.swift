import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeEntry.startTime) private var allEntries: [TimeEntry]
    @StateObject private var service = TimelineService()
    @State private var showAddEntry = false
    @State private var showScreenTimeImport = false
    
    private var todayEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.startTime) }
    }
    
    private var coverage: DayCoverage {
        service.dayCoverage(for: .now, entries: todayEntries)
    }
    
    private var untrackedBlocks: [UntrackedBlock] {
        service.untrackedBlocks(for: .now, entries: todayEntries)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Coverage Ring
                        coverageSection
                        
                        // Quick Stats
                        quickStatsRow
                        
                        // Untracked Blocks
                        if !untrackedBlocks.isEmpty {
                            untrackedSection
                        }
                        
                        // Recent Entries
                        recentEntriesSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddEntry) {
                AddEntryView()
            }
            .sheet(isPresented: $showScreenTimeImport) {
                ScreenTimeImportView()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(TSFonts.body(14))
                    .foregroundStyle(TSColors.textSecondary)
                Text("Today")
                    .font(TSFonts.display(32))
                    .foregroundStyle(TSColors.textPrimary)
            }
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    showScreenTimeImport = true
                } label: {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(TSColors.accentSecondary)
                        .frame(width: 42, height: 42)
                        .background(TSColors.surface)
                        .clipShape(Circle())
                }
                
                Button {
                    showAddEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(TSColors.background)
                        .frame(width: 42, height: 42)
                        .background(TSColors.accent)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, 56)
    }
    
    // MARK: - Coverage Ring
    private var coverageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(TSColors.surface)
            
            HStack(spacing: 24) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(TSColors.separator, lineWidth: 14)
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .trim(from: 0, to: coverage.coverageRate)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [TSColors.accent, TSColors.accentSecondary]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 1.2), value: coverage.coverageRate)
                    
                    VStack(spacing: 2) {
                        Text(coverage.coveragePercent)
                            .font(TSFonts.display(28))
                            .foregroundStyle(TSColors.accent)
                        Text("tracked")
                            .font(TSFonts.body(11))
                            .foregroundStyle(TSColors.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tracked")
                            .font(TSFonts.body(12))
                            .foregroundStyle(TSColors.textSecondary)
                        Text(coverage.totalTracked.hoursMinutesFormatted)
                            .font(TSFonts.headline(20))
                            .foregroundStyle(TSColors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Untracked")
                            .font(TSFonts.body(12))
                            .foregroundStyle(TSColors.textSecondary)
                        Text(coverage.totalUntracked.hoursMinutesFormatted)
                            .font(TSFonts.headline(20))
                            .foregroundStyle(coverage.totalUntracked > 3600 ? TSColors.warning : TSColors.success)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Entries")
                            .font(TSFonts.body(12))
                            .foregroundStyle(TSColors.textSecondary)
                        Text("\(todayEntries.count)")
                            .font(TSFonts.headline(20))
                            .foregroundStyle(TSColors.textPrimary)
                    }
                }
                
                Spacer()
            }
            .padding(20)
        }
    }
    
    // MARK: - Quick Stats Row
    private var quickStatsRow: some View {
        let categorySums = Dictionary(grouping: todayEntries, by: { $0.category })
            .mapValues { entries in entries.reduce(0) { $0 + $1.duration } }
            .sorted { $0.value > $1.value }
            .prefix(4)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(categorySums), id: \.key) { cat, dur in
                    VStack(spacing: 8) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: cat.defaultColor))
                        Text(dur.hoursMinutesFormatted)
                            .font(TSFonts.mono(13))
                            .foregroundStyle(TSColors.textPrimary)
                        Text(cat.displayName)
                            .font(TSFonts.body(10))
                            .foregroundStyle(TSColors.textSecondary)
                    }
                    .frame(width: 80, height: 90)
                    .background(TSColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    // MARK: - Untracked Section
    private var untrackedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(TSColors.warning)
                Text("Untracked Gaps")
                    .font(TSFonts.headline(16))
                    .foregroundStyle(TSColors.textPrimary)
                Spacer()
                Text("\(untrackedBlocks.count) gaps")
                    .font(TSFonts.body(12))
                    .foregroundStyle(TSColors.textSecondary)
            }
            
            ForEach(untrackedBlocks) { block in
                UntrackedBlockRow(block: block) {
                    service.fillUntracked(block, context: context)
                } onAdd: {
                    showAddEntry = true
                }
            }
        }
    }
    
    // MARK: - Recent Entries
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Entries")
                    .font(TSFonts.headline(16))
                    .foregroundStyle(TSColors.textPrimary)
                Spacer()
                NavigationLink("See All") {
                    TimelineView()
                }
                .font(TSFonts.body(14))
                .foregroundStyle(TSColors.accent)
            }
            
            if todayEntries.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.questionmark",
                    message: "No entries yet.\nTap + to add your first entry."
                )
            } else {
                ForEach(todayEntries.sorted { $0.startTime > $1.startTime }.prefix(5)) { entry in
                    EntryRowView(entry: entry)
                }
            }
        }
    }
}

// MARK: - Untracked Block Row
struct UntrackedBlockRow: View {
    let block: UntrackedBlock
    let onFill: () -> Void
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(TSColors.warning.opacity(0.3))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(block.timeRangeString)
                    .font(TSFonts.mono(13))
                    .foregroundStyle(TSColors.textPrimary)
                Text(block.formattedDuration)
                    .font(TSFonts.body(12))
                    .foregroundStyle(TSColors.warning)
            }
            
            Spacer()
            
            Button("Fill") {
                onFill()
            }
            .font(TSFonts.body(12))
            .foregroundStyle(TSColors.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TSColors.warning)
            .clipShape(Capsule())
            
            Button("Add") {
                onAdd()
            }
            .font(TSFonts.body(12))
            .foregroundStyle(TSColors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TSColors.accent.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(12)
        .background(TSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TSColors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Entry Row View
struct EntryRowView: View {
    let entry: TimeEntry
    @Environment(\.modelContext) private var context
    @StateObject private var service = TimelineService()
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: entry.colorHex))
                .frame(width: 4)
            
            Image(systemName: entry.category.icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: entry.colorHex))
                .frame(width: 32, height: 32)
                .background(Color(hex: entry.colorHex).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(TSFonts.headline(14))
                    .foregroundStyle(TSColors.textPrimary)
                    .lineLimit(1)
                Text(entry.timeRangeString)
                    .font(TSFonts.mono(11))
                    .foregroundStyle(TSColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedDuration)
                    .font(TSFonts.mono(13))
                    .foregroundStyle(TSColors.textPrimary)
                
                Image(systemName: entry.entryType.iconName)
                    .font(.system(size: 10))
                    .foregroundStyle(TSColors.textSecondary)
            }
        }
        .padding(12)
        .background(TSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                service.deleteEntry(entry, context: context)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(TSColors.textSecondary)
            Text(message)
                .font(TSFonts.body(14))
                .foregroundStyle(TSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(TSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
