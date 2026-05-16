import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = TimelineService()
    
    var defaultDate: Date = .now
    
    @State private var title: String = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedCategory: ActivityCategory = .other
    @State private var notes: String = ""
    @State private var showCategoryPicker = false
    @State private var showOverlapWarning = false
    @State private var hasOverlap = false
    
    @Query(sort: \TimeEntry.startTime) private var allEntries: [TimeEntry]
    
    init(defaultDate: Date = .now) {
        self.defaultDate = defaultDate
        let cal = Calendar.current
        let now = Date.now
        let start = cal.date(bySetting: .minute, value: 0, of: now) ?? now
        let end = cal.date(byAdding: .hour, value: 1, to: start) ?? now
        _startTime = State(initialValue: start)
        _endTime = State(initialValue: end)
    }
    
    private var dayEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDate($0.startTime, inSameDayAs: defaultDate) }
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && endTime > startTime
    }
    
    private var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACTIVITY")
                                .font(TSFonts.mono(11))
                                .foregroundStyle(TSColors.textSecondary)
                                .tracking(1.5)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(TSColors.surface)
                                TextField("What did you do?", text: $title)
                                    .font(TSFonts.headline(18))
                                    .foregroundStyle(TSColors.textPrimary)
                                    .padding(16)
                            }
                        }
                        
                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(TSFonts.mono(11))
                                .foregroundStyle(TSColors.textSecondary)
                                .tracking(1.5)
                            
                            Button {
                                showCategoryPicker = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: selectedCategory.defaultColor).opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: selectedCategory.icon)
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color(hex: selectedCategory.defaultColor))
                                    }
                                    
                                    Text(selectedCategory.displayName)
                                        .font(TSFonts.body(16))
                                        .foregroundStyle(TSColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(TSColors.textSecondary)
                                }
                                .padding(14)
                                .background(TSColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        
                        // Time range
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("TIME RANGE")
                                    .font(TSFonts.mono(11))
                                    .foregroundStyle(TSColors.textSecondary)
                                    .tracking(1.5)
                                Spacer()
                                Text(duration.hoursMinutesFormatted)
                                    .font(TSFonts.mono(12))
                                    .foregroundStyle(TSColors.accent)
                            }
                            
                            HStack(spacing: 12) {
                                // Start time
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Start")
                                        .font(TSFonts.body(12))
                                        .foregroundStyle(TSColors.textSecondary)
                                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .onChange(of: startTime) { _, new in
                                            if endTime <= new {
                                                endTime = new.addingTimeInterval(3600)
                                            }
                                            checkOverlap()
                                        }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(TSColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(TSColors.textSecondary)
                                
                                // End time
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("End")
                                        .font(TSFonts.body(12))
                                        .foregroundStyle(TSColors.textSecondary)
                                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .onChange(of: endTime) { _, _ in checkOverlap() }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(TSColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        
                        // Quick duration buttons
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUICK DURATION")
                                .font(TSFonts.mono(11))
                                .foregroundStyle(TSColors.textSecondary)
                                .tracking(1.5)
                            
                            HStack(spacing: 8) {
                                ForEach([15, 30, 60, 90, 120], id: \.self) { mins in
                                    Button {
                                        endTime = startTime.addingTimeInterval(Double(mins) * 60)
                                        checkOverlap()
                                    } label: {
                                        Text(mins >= 60 ? "\(mins/60)h" : "\(mins)m")
                                            .font(TSFonts.mono(12))
                                            .foregroundStyle(
                                                Int(duration / 60) == mins ? TSColors.background : TSColors.textPrimary
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                Int(duration / 60) == mins ? TSColors.accent : TSColors.surface
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        
                        // Overlap warning
                        if hasOverlap {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(TSColors.warning)
                                Text("This overlaps with an existing entry.")
                                    .font(TSFonts.body(13))
                                    .foregroundStyle(TSColors.warning)
                            }
                            .padding(12)
                            .background(TSColors.warning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES (OPTIONAL)")
                                .font(TSFonts.mono(11))
                                .foregroundStyle(TSColors.textSecondary)
                                .tracking(1.5)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(TSColors.surface)
                                TextEditor(text: $notes)
                                    .font(TSFonts.body(14))
                                    .foregroundStyle(TSColors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .frame(minHeight: 80)
                                if notes.isEmpty {
                                    Text("Add a note...")
                                        .font(TSFonts.body(14))
                                        .foregroundStyle(TSColors.textSecondary)
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TSColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isValid ? TSColors.accent : TSColors.textSecondary)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selected: $selectedCategory)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func checkOverlap() {
        let overlaps = service.overlaps(newStart: startTime, newEnd: endTime, entries: dayEntries)
        hasOverlap = !overlaps.isEmpty
    }
    
    private func save() {
        // Normalize times to the default date
        let cal = Calendar.current
        let dayBase = cal.startOfDay(for: defaultDate)
        
        var sComps = cal.dateComponents([.hour, .minute], from: startTime)
        var eComps = cal.dateComponents([.hour, .minute], from: endTime)
        
        let normalizedStart = cal.date(bySettingHour: sComps.hour ?? 0, minute: sComps.minute ?? 0, second: 0, of: dayBase) ?? startTime
        let normalizedEnd = cal.date(bySettingHour: eComps.hour ?? 0, minute: eComps.minute ?? 0, second: 0, of: dayBase) ?? endTime
        
        service.addEntry(
            title: title.trimmingCharacters(in: .whitespaces),
            startTime: normalizedStart,
            endTime: normalizedEnd,
            category: selectedCategory,
            notes: notes,
            context: context
        )
        dismiss()
    }
}
