import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            TSColors.background.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(0)
                
                TimelineView()
                    .tabItem {
                        Label("Timeline", systemImage: "timeline.selection")
                    }
                    .tag(1)
                
                TimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    .tag(2)
                
                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.pie.fill")
                    }
                    .tag(3)
            }
            .tint(TSColors.accent)
        }
        .preferredColorScheme(.dark)
    }
}
