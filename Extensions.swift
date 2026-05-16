import SwiftUI

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date helpers
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }
    
    func fractionOfDay() -> Double {
        let start = startOfDay
        return timeIntervalSince(start) / (24 * 3600)
    }
    
    func hoursAndMinutesString() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - TimeInterval formatting
extension TimeInterval {
    var hoursMinutesFormatted: String {
        let h = Int(self / 3600)
        let m = Int(self / 60) % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - App Design System
struct TSColors {
    static let background = Color(hex: "#0E0E12")
    static let surface = Color(hex: "#1A1A22")
    static let surfaceElevated = Color(hex: "#22222E")
    static let accent = Color(hex: "#C8FF57")
    static let accentSecondary = Color(hex: "#57C8FF")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8888AA")
    static let separator = Color(hex: "#2A2A3A")
    static let danger = Color(hex: "#FF5757")
    static let warning = Color(hex: "#FFB347")
    static let success = Color(hex: "#57FF9A")
}

struct TSFonts {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
