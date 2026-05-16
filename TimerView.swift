import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @Query private var activeTimers: [ActiveTimer]
    @StateObject private var service = TimelineService()
    
    @State private var timerTitle: String = ""
    @State private var selectedCategory: ActivityCategory = .other
    @State private var showCategoryPicker = false
    @State private var elapsed: TimeInterval = 0
    @State private var ticker: Timer? = nil
    
    private var activeTimer: ActiveTimer? { activeTimers.first }
    private var hasActiveTimer: Bool { activeTimer != nil }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Timer")
                            .font(TSFonts.display(28))
                            .foregroundStyle(TSColors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if hasActiveTimer {
                                activeTimerSection
                            } else {
                                newTimerSection
                            }
                            
                            recentTimerSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { startTicker() }
            .onDisappear { stopTicker() }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selected: $selectedCategory)
            }
        }
    }
    
    // MARK: - Active Timer Section
    private var activeTimerSection: some View {
        guard let timer = activeTimer else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(TSColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(TSColors.danger.opacity(0.4), lineWidth: 1)
                        )
                    
                    VStack(spacing: 16) {
                        // Pulsing indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(TSColors.danger)
                                .frame(width: 8, height: 8)
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: elapsed)
                            Text("RECORDING")
                                .font(TSFonts.mono(11))
                                .foregroundStyle(TSColors.danger)
                                .tracking(2)
                        }
                        
                        // Elapsed time
                        Text(timer.formattedElapsed)
                            .font(.system(size: 64, weight: .black, design: .monospaced))
                            .foregroundStyle(TSColors.textPrimary)
                            .contentTransition(.numericText())
                            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                                elapsed = timer.elapsed
                            }
                        
                        // Edit title
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(TSColors.surfaceElevated)
                            TextField("What are you doing?", text: $timerTitle)
                                .font(TSFonts.body(16))
                                .foregroundStyle(TSColors.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .onAppear { timerTitle = timer.title }
                        }
                        .frame(height: 44)
                        
                        // Category
                        Button {
                            showCategoryPicker = true
                        } label: {
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundStyle(Color(hex: selectedCategory.defaultColor))
                                Text(selectedCategory.displayName)
                                    .font(TSFonts.body(14))
                                    .foregroundStyle(TSColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(TSColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(TSColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Stop button
                        Button {
                            stopTimerAction(timer)
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop & Save")
                                    .font(TSFonts.headline(16))
                            }
                            .foregroundStyle(TSColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(TSColors.danger)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }
                
                // Discard button
                Button {
                    discardTimer(timer)
                } label: {
                    Text("Discard")
                        .font(TSFonts.body(14))
                        .foregroundStyle(TSColors.textSecondary)
                }
            }
        )
    }
    
    // MARK: - New Timer Section
    private var newTimerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(TSColors.surface)
                
                VStack(spacing: 16) {
                    Image(systemName: "timer")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(TSColors.accent)
                    
                    Text("00:00")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(TSColors.textSecondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TSColors.surfaceElevated)
                        TextField("Activity name...", text: $timerTitle)
                            .font(TSFonts.body(16))
                            .foregroundStyle(TSColors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .frame(height: 44)
                    
                    Button {
                        showCategoryPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedCategory.icon)
                                .foregroundStyle(Color(hex: selectedCategory.defaultColor))
                            Text(selectedCategory.displayName)
                                .font(TSFonts.body(14))
                                .foregroundStyle(TSColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(TSColors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(TSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        startTimerAction()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Timer")
                                .font(TSFonts.headline(16))
                        }
                        .foregroundStyle(TSColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TSColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Recent Timers
    @Query(
        filter: #Predicate<TimeEntry> { $0.entryType == "timer" },
        sort: \TimeEntry.startTime,
        order: .reverse
    ) private var timerEntries: [TimeEntry]
    
    private var recentTimerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Timers")
                .font(TSFonts.headline(16))
                .foregroundStyle(TSColors.textPrimary)
            
            if timerEntries.isEmpty {
                Text("Your timer recordings will appear here.")
                    .font(TSFonts.body(14))
                    .foregroundStyle(TSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(TSColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(timerEntries.prefix(5)) { entry in
                    EntryRowView(entry: entry)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func startTimerAction() {
        let timer = ActiveTimer(
            title: timerTitle,
            category: selectedCategory,
            colorHex: selectedCategory.defaultColor
        )
        context.insert(timer)
        try? context.save()
    }
    
    private func stopTimerAction(_ timer: ActiveTimer) {
        service.stopTimer(timer, title: timerTitle.isEmpty ? timer.title : timerTitle, category: selectedCategory, context: context)
        timerTitle = ""
        selectedCategory = .other
    }
    
    private func discardTimer(_ timer: ActiveTimer) {
        context.delete(timer)
        try? context.save()
        timerTitle = ""
    }
    
    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let t = activeTimer {
                elapsed = t.elapsed
            }
        }
    }
    
    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}

// MARK: - Category Picker
struct CategoryPickerView: View {
    @Binding var selected: ActivityCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                List {
                    ForEach(ActivityCategory.allCases, id: \.self) { cat in
                        Button {
                            selected = cat
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(hex: cat.defaultColor))
                                    .frame(width: 32)
                                
                                Text(cat.displayName)
                                    .font(TSFonts.body(16))
                                    .foregroundStyle(TSColors.textPrimary)
                                
                                Spacer()
                                
                                if selected == cat {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(TSColors.accent)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                        .listRowBackground(TSColors.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TSColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
