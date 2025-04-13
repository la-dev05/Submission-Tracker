import SwiftUI
import UserNotifications

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var title: String
    var notes: String?
    var dueDate: Date
    var isCompleted: Bool = false
    var priority: Priority = .none
    var repeatInterval: RepeatInterval = .never
    
    enum Priority: Int, Codable {
        case none = 0
        case low = 1
        case medium = 2
        case high = 3
    }
    
    enum RepeatInterval: Codable {
        case never
        case daily(Int)      // Every n days
        case weekly(Int)     // Every n weeks
        case monthly(Int)    // Every n months
        
        var description: String {
            switch self {
            case .never: return "Never"
            case .daily(let n): return n == 1 ? "Every day" : "Every \(n) days"
            case .weekly(let n): return n == 1 ? "Every week" : "Every \(n) weeks"
            case .monthly(let n): return n == 1 ? "Every month" : "Every \(n) months"
            }
        }
    }
}

extension Reminder.Priority {
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        case .none: return .blue
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [self.color.opacity(0.7), self.color.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

class ReminderManager: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var storeCompletedReminders: Bool {
        didSet {
            UserDefaults.standard.set(storeCompletedReminders, forKey: "storeCompletedReminders")
            if !storeCompletedReminders {
                clearCompletedReminders()
            }
        }
    }
    
    init() {
        self.storeCompletedReminders = UserDefaults.standard.bool(forKey: "storeCompletedReminders")
        requestNotificationPermission()
        loadReminders()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        saveReminders()
        scheduleNotification(for: reminder)
    }
    
    func toggleCompletion(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted.toggle()
            
            if reminders[index].isCompleted {
                cancelNotification(for: reminder)
                
                // Handle repeating reminders
                if case let .daily(n) = reminder.repeatInterval {
                    let nextDate = Calendar.current.date(byAdding: .day, value: n, to: reminder.dueDate) ?? reminder.dueDate
                    reminders[index].dueDate = nextDate
                    reminders[index].isCompleted = false
                    scheduleNotification(for: reminders[index])
                } else if case let .weekly(n) = reminder.repeatInterval {
                    let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: n, to: reminder.dueDate) ?? reminder.dueDate
                    reminders[index].dueDate = nextDate
                    reminders[index].isCompleted = false
                    scheduleNotification(for: reminders[index])
                } else if case let .monthly(n) = reminder.repeatInterval {
                    let nextDate = Calendar.current.date(byAdding: .month, value: n, to: reminder.dueDate) ?? reminder.dueDate
                    reminders[index].dueDate = nextDate
                    reminders[index].isCompleted = false
                    scheduleNotification(for: reminders[index])
                } else if !storeCompletedReminders {
                    // Only remove non-repeating reminders
                    reminders.remove(at: index)
                }
            } else {
                scheduleNotification(for: reminder)
            }
            
            saveReminders()
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        cancelNotification(for: reminder)
        saveReminders()
    }
    
    func clearCompletedReminders() {
        let completedReminders = reminders.filter { $0.isCompleted }
        completedReminders.forEach { reminder in
            cancelNotification(for: reminder)
        }
        reminders.removeAll { $0.isCompleted }
        saveReminders()
    }
    
    func updateReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            saveReminders()
            cancelNotification(for: reminder)
            if !reminder.isCompleted {
                scheduleNotification(for: reminder)
            }
        }
    }
    
    private func scheduleNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let notes = reminder.notes { content.body = notes }
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification(for reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: "savedReminders")
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "savedReminders"),
           let savedReminders = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = savedReminders
        }
    }
}

// Add this new view for completion animation
struct CompletionParticle: View {
    let position: CGPoint
    let color: Color
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .position(position)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    scale = 0.1
                    opacity = 0
                }
            }
    }
}

struct CompletionAnimation: View {
    let center: CGPoint
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { index in
                let angle = Double(index) * 18.0
                let radius = CGFloat.random(in: 20...60)
                let position = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                
                CompletionParticle(
                    position: position,
                    color: [.blue, .purple, .pink, .orange, .green].randomElement()!
                )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isShowing = false
            }
        }
    }
}

struct ReminderListView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    @State private var showingAddReminder = false
    @State private var showCompletedReminders = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSettings = false
    
    var activeReminders: [Reminder] {
        reminderManager.reminders.filter { !$0.isCompleted }
    }
    
    var completedReminders: [Reminder] {
        reminderManager.reminders.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                ).edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(activeReminders) { reminder in
                        ReminderRowView(reminder: reminder)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        reminderManager.deleteReminder(reminder)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    
                    if !completedReminders.isEmpty {
                        Section {
                            ForEach(completedReminders) { reminder in
                                ReminderRowView(reminder: reminder)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                reminderManager.deleteReminder(reminder)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Text("Completed")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(completedReminders.count)")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
                
                // Settings button (keep existing code)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            Toggle("Store Completed Reminders", isOn: $reminderManager.storeCompletedReminders)
                        } label: {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddReminder = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                if !completedReminders.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView()
            }
            .alert("Clear Completed Reminders", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    reminderManager.clearCompletedReminders()
                }
            } message: {
                Text("Are you sure you want to delete all completed reminders? This action cannot be undone.")
            }
        }
    }
}

struct ReminderRowView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    let reminder: Reminder
    @State private var showingCompletion = false
    @State private var itemCenter: CGPoint = .zero
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if (!reminder.isCompleted) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        reminderManager.toggleCompletion(reminder)
                        showingCompletion = true
                    }
                } else {
                    reminderManager.toggleCompletion(reminder)
                }
            }) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(reminder.isCompleted ? .blue : .gray)
            }
            
            Button(action: { showingEditSheet = true }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .strikethrough(reminder.isCompleted)
                    
                    if let notes = reminder.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatDate(reminder.dueDate))
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            priorityIcon(for: reminder.priority)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(reminder.priority.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: reminder.priority.color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    itemCenter = CGPoint(
                        x: geometry.frame(in: .global).midX,
                        y: geometry.frame(in: .global).midY
                    )
                }
            }
        )
        .overlay(
            showingCompletion ?
            CompletionAnimation(center: itemCenter, isShowing: $showingCompletion)
            : nil
        )
        .sheet(isPresented: $showingEditSheet) {
            EditReminderView(reminder: reminder)
        }
    }
    
    private func priorityIcon(for priority: Reminder.Priority) -> some View {
        priority == .none ? AnyView(EmptyView()) : AnyView(
            Text(String(repeating: "!", count: priority.rawValue))
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priority.gradient)
                .foregroundColor(.white)
                .clipShape(Capsule())
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private func formatRepeatIntervalText(type: String, value: Int) -> String {
    switch type {
    case "daily":
        return value == 1 ? "Every day" : "Every \(value) days"
    case "weekly":
        return value == 1 ? "Every week" : "Every \(value) weeks"
    case "monthly":
        return value == 1 ? "Every month" : "Every \(value) months"
    default:
        return "Never"
    }
}

struct AddReminderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reminderManager: ReminderManager
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var priority: Reminder.Priority = .none
    @State private var repeatInterval: Reminder.RepeatInterval = .never
    @State private var repeatValue: Int = 1
    @State private var selectedRepeatType = "never"
    
    init() {
        _title = State(initialValue: "Collect Submitted Items")
        _notes = State(initialValue: "Remember to collect your submitted items")
        _dueDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _priority = State(initialValue: .medium)
    }
    
    private func repeatIntervalText(_ type: String, value: Int) -> String {
        let unit = type.dropLast(2) // removes 'ly' from daily/weekly/monthly
        return "Every \(value) \(unit)\(value == 1 ? "" : "s")"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes)
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker("Due Date", selection: $dueDate)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(Reminder.Priority.none)
                        Text("Low").tag(Reminder.Priority.low)
                        Text("Medium").tag(Reminder.Priority.medium)
                        Text("High").tag(Reminder.Priority.high)
                    }
                }
                
                Section(header: Text("Repeat")) {
                    Picker("Repeat Interval", selection: $selectedRepeatType) {
                        Text("Never").tag("never")
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                    
                    if selectedRepeatType != "never" {
                        Stepper(formatRepeatIntervalText(type: selectedRepeatType, value: repeatValue),
                               value: $repeatValue, in: 1...365)
                    }
                }
            }
            .onChange(of: selectedRepeatType) { oldValue, newValue in
                switch newValue {
                case "daily": repeatInterval = .daily(repeatValue)
                case "weekly": repeatInterval = .weekly(repeatValue)
                case "monthly": repeatInterval = .monthly(repeatValue)
                default: repeatInterval = .never
                }
            }
            .onChange(of: repeatValue) { oldValue, newValue in
                switch selectedRepeatType {
                case "daily": repeatInterval = .daily(newValue)
                case "weekly": repeatInterval = .weekly(newValue)
                case "monthly": repeatInterval = .monthly(newValue)
                default: repeatInterval = .never
                }
            }
            .navigationTitle("New Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let reminder = Reminder(
                            title: title,
                            notes: notes.isEmpty ? nil : notes,
                            dueDate: dueDate,
                            priority: priority,
                            repeatInterval: repeatInterval
                        )
                        reminderManager.addReminder(reminder)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct EditReminderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reminderManager: ReminderManager
    let reminder: Reminder
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var priority: Reminder.Priority
    @State private var repeatInterval: Reminder.RepeatInterval
    @State private var repeatValue: Int
    @State private var selectedRepeatType: String
    
    init(reminder: Reminder) {
        self.reminder = reminder
        _title = State(initialValue: reminder.title)
        _notes = State(initialValue: reminder.notes ?? "")
        _dueDate = State(initialValue: reminder.dueDate)
        _priority = State(initialValue: reminder.priority)
        _repeatInterval = State(initialValue: reminder.repeatInterval)
        
        switch reminder.repeatInterval {
        case .daily(let n):
            _repeatValue = State(initialValue: n)
            _selectedRepeatType = State(initialValue: "daily")
        case .weekly(let n):
            _repeatValue = State(initialValue: n)
            _selectedRepeatType = State(initialValue: "weekly")
        case .monthly(let n):
            _repeatValue = State(initialValue: n)
            _selectedRepeatType = State(initialValue: "monthly")
        case .never:
            _repeatValue = State(initialValue: 1)
            _selectedRepeatType = State(initialValue: "never")
        }
    }
    
    private func repeatIntervalText(_ type: String, value: Int) -> String {
        let unit = type.dropLast(2) // removes 'ly' from daily/weekly/monthly
        return "Every \(value) \(unit)\(value == 1 ? "" : "s")"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes)
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker("Due Date", selection: $dueDate)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(Reminder.Priority.none)
                        Text("Low").tag(Reminder.Priority.low)
                        Text("Medium").tag(Reminder.Priority.medium)
                        Text("High").tag(Reminder.Priority.high)
                    }
                }
                
                Section(header: Text("Repeat")) {
                    Picker("Repeat Interval", selection: $selectedRepeatType) {
                        Text("Never").tag("never")
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                    
                    if selectedRepeatType != "never" {
                        Stepper(formatRepeatIntervalText(type: selectedRepeatType, value: repeatValue),
                               value: $repeatValue, in: 1...365)
                    }
                }
            }
            .onChange(of: selectedRepeatType) { oldValue, newValue in
                switch newValue {
                case "daily": repeatInterval = .daily(repeatValue)
                case "weekly": repeatInterval = .weekly(repeatValue)
                case "monthly": repeatInterval = .monthly(repeatValue)
                default: repeatInterval = .never
                }
            }
            .onChange(of: repeatValue) { oldValue, newValue in
                switch selectedRepeatType {
                case "daily": repeatInterval = .daily(newValue)
                case "weekly": repeatInterval = .weekly(newValue)
                case "monthly": repeatInterval = .monthly(newValue)
                default: repeatInterval = .never
                }
            }
            .navigationTitle("Edit Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedReminder = Reminder(
                            id: reminder.id,
                            title: title,
                            notes: notes.isEmpty ? nil : notes,
                            dueDate: dueDate,
                            isCompleted: reminder.isCompleted,
                            priority: priority,
                            repeatInterval: repeatInterval
                        )
                        reminderManager.updateReminder(updatedReminder)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
