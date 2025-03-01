import SwiftUI

// MARK: - Model
struct submissionItem: Identifiable, Codable {
    let id: Int
    var description: String
    let dateAdded: Date
    var displayNumber: Int  // For left side serial numbering
    var sequenceNumber: Int? // For right side duplicate numbering
    var isReceived: Bool = false
    
    static var nextId = 1
    
    static func getNewId() -> Int {
        let currentId = nextId
        nextId += 1
        return currentId
    }
}



extension FileManager {
    static let historyFileName = "submission_history.json"
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func getHistoryFileURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent(historyFileName)
    }
}



// MARK: - UI Constants
enum UIConstants {
    static let primaryColor = Color.blue.opacity(0.8)
    static let secondaryColor = Color(UIColor.systemGray5)
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 3
    static let padding: CGFloat = 16
}



// MARK: - Views

enum NavigationItem: String, Identifiable {
    case today = "Today's submission"
    case history = "History"
    case fullHistory = "View Full History"
    case statistics = "Statistics"  // New case
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .today: return "tshirt"
        case .history: return "calendar"
        case .fullHistory: return "list.bullet.rectangle"
        case .statistics: return "chart.bar.fill"  // New icon
        }
    }
}



struct ContentView: View {
    @StateObject private var viewModel = submissionViewModel()
    @State private var selection: NavigationItem? = .today
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            switch selection {
            case .today:
                TodayView()
            case .history:
                HistoryView()
            case .fullHistory:
                FullHistoryView()
            case .statistics:
                StatisticsView()
            case .none:
                Text("Select an option")
            }
        }
        .environmentObject(viewModel)
    }
}



extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}



struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(UIConstants.primaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(UIConstants.secondaryColor)
        .cornerRadius(UIConstants.cornerRadius)
        .padding(.horizontal)
    }
}



extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}



// MARK: - App
@main
struct submissionTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}



#Preview {
    ContentView()
}
