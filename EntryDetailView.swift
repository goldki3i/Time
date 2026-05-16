import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = TimelineService()
    
    let entry: TimeEntry
    
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedCategory: ActivityCategory
    @State private var notes: String
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    
    init(entry: TimeEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _startTime = State(initialValue: entry.startTime)
        _endTime = State(initialValue: entry.endTime)
        _selectedCategory = State(initialValue: entry.category)
        _notes = State(initialValue: entry.notes)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Color header
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: entry.colorHex).opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: entry.colorHex).opacity(0.3), lineWidth: 1)
                                )
                            
                            VStack(spacing: 12) {
                                Image(systemName: entry.category.icon)
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color(hex: entry.colorHex))
                                
                                if isEditing {
                                    TextField("Activity name", text: $title)
                                        .font(TSFonts.display(22))
                                        .foregroundStyle(TSColors.textPrimary)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text(entry.title)
                                        .font(TSFonts.display(22))
                                        .foregroundStyle(TSColors.textPrimary)
                                }
                                
                                HStack(spacing: 8) {
                                    Label(entry.entryType.displayName, systemImage: entry.entryType.iconName)
                                        .font(TSFonts.mono(12))
                                        .foregroundStyle(TSColors.textSecondary)
                                    Text("•")
                                        .foregroundStyle(TSColors.textSecondary)
                                    Text(entry.category.displayName)
                                        .font(TSFonts.mono(12))
                                        .foregroundStyle(TSColors.textSecondary)
                                }
                            }
                            .padding(24)
                        }
                        
                        // Time details
                        VStack(spacing: 12) {
                            DetailRow(label: "Duration", value: entry.formattedDuration, icon: "clock")
                            DetailRow(label: "Time", value: entry.timeRangeString, icon: "calendar.clock")
                            
                            if let bundleID = entry.appBundleID {
                                DetailRow(label: "App", value: bundleID, icon: "apps.iphone")
                            }
                        }
                        .padding(16)
                        .background(TSColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        if !entry.notes.isEmpty || isEditing {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(TSFonts.headline(14))
                                    .foregroundStyle(TSColors.textSecondary)
                                
                                if isEditing {
                                    TextEditor(text: $notes)
                                        .font(TSFonts.body(14))
                                        .foregroundStyle(TSColors.textPrimary)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 80)
                                } else {
                                    Text(entry.notes)
                                        .font(TSFonts.body(14))
                                        .foregroundStyle(TSColors.textPrimary)
                                }
                            }
                            .padding(16)
                            .background(TSColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Delete button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                                .font(TSFonts.body(14))
                                .foregroundStyle(TSColors.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TSColors.danger.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(TSColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing { saveChanges() }
                        else { isEditing = true }
                    }
                    .foregroundStyle(TSColors.accent)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Entry?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    service.deleteEntry(entry, context: context)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveChanges() {
        entry.title = title
        entry.startTime = startTime
        entry.endTime = endTime
        entry.category = selectedCategory
        entry.colorHex = selectedCategory.defaultColor
        entry.notes = notes
        try? context.save()
        isEditing = false
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(TSColors.textSecondary)
                .frame(width: 20)
            Text(label)
                .font(TSFonts.body(14))
                .foregroundStyle(TSColors.textSecondary)
            Spacer()
            Text(value)
                .font(TSFonts.mono(13))
                .foregroundStyle(TSColors.textPrimary)
        }
    }
}
