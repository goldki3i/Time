import SwiftUI
import SwiftData

struct ScreenTimeImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var isImporting = false
    @State private var importDone = false
    @State private var selectedDate: Date = .now
    
    var body: some View {
        NavigationStack {
            ZStack {
                TSColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(TSColors.accentSecondary.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 44, weight: .thin))
                                .foregroundStyle(TSColors.accentSecondary)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("Screen Time Import")
                                .font(TSFonts.display(24))
                                .foregroundStyle(TSColors.textPrimary)
                            Text("Import your app usage data from Screen Time to automatically populate your timeline.")
                                .font(TSFonts.body(15))
                                .foregroundStyle(TSColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Notice box
                        VStack(alignment: .leading, spacing: 12) {
                            Label("About Screen Time Access", systemImage: "info.circle.fill")
                                .font(TSFonts.headline(14))
                                .foregroundStyle(TSColors.accentSecondary)
                            
                            Text("Full Screen Time integration requires the FamilyControls entitlement from Apple, which must be requested separately. This demo imports realistic sample data to show how the feature would work.")
                                .font(TSFonts.body(13))
                                .foregroundStyle(TSColors.textSecondary)
                            
                            Divider().background(TSColors.separator)
                            
                            Text("Sample data includes:\n• Safari browsing\n• Messages activity\n• YouTube & Spotify usage\n• Email sessions\n• Social media time")
                                .font(TSFonts.body(13))
                                .foregroundStyle(TSColors.textSecondary)
                        }
                        .padding(16)
                        .background(TSColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(TSColors.accentSecondary.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("IMPORT FOR DATE")
                                .font(TSFonts.mono(11))
                                .foregroundStyle(TSColors.textSecondary)
                                .tracking(1.5)
                            
                            DatePicker("", selection: $selectedDate, in: ...Date.now, displayedComponents: .date)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .padding(14)
                                .background(TSColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        if importDone {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(TSColors.success)
                                Text("Sample data imported successfully!")
                                    .font(TSFonts.body(14))
                                    .foregroundStyle(TSColors.success)
                            }
                            .padding(14)
                            .background(TSColors.success.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Import button
                        Button {
                            importData()
                        } label: {
                            HStack {
                                if isImporting {
                                    ProgressView()
                                        .tint(TSColors.background)
                                } else {
                                    Image(systemName: importDone ? "arrow.clockwise" : "icloud.and.arrow.down")
                                    Text(importDone ? "Import Again" : "Import Sample Data")
                                        .font(TSFonts.headline(16))
                                }
                            }
                            .foregroundStyle(TSColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(TSColors.accentSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isImporting)
                        
                        // How to enable real Screen Time
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Enable Real Screen Time", systemImage: "lock.shield")
                                .font(TSFonts.headline(14))
                                .foregroundStyle(TSColors.textSecondary)
                            
                            Text("To use real Screen Time data, the app requires the com.apple.developer.family-controls entitlement. Add FamilyControls to your app's capabilities in Xcode, then request access using AuthorizationCenter.shared.requestAuthorization(for: .individual).")
                                .font(TSFonts.body(12))
                                .foregroundStyle(TSColors.textSecondary)
                        }
                        .padding(14)
                        .background(TSColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Screen Time")
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
    
    private func importData() {
        isImporting = true
        importDone = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            ScreenTimeService.importSampleData(for: selectedDate, context: context)
            isImporting = false
            importDone = true
        }
    }
}
