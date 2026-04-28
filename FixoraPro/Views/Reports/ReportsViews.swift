import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false
    @State private var showExport = false
    @State private var exportToast = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Summary card
                        VStack(spacing: 16) {
                            HStack {
                                Text("Project Summary")
                                    .font(FixoraFont.subheading(16))
                                    .foregroundColor(Color.textPrimary)
                                Spacer()
                                Text("\(projectsVM.projects.count) projects")
                                    .font(FixoraFont.caption(12))
                                    .foregroundColor(Color.textInactive)
                            }

                            HStack(spacing: 16) {
                                ReportStat("Projects", "\(projectsVM.projects.count)", .accentCyan)
                                ReportStat("Rooms", "\(projectsVM.rooms.count)", .accentPurple)
                                ReportStat("Cables", "\(projectsVM.totalCables)", .cableElectric)
                                ReportStat("Points", "\(projectsVM.totalPoints)", .pointActive)
                            }
                        }
                        .cardStyle()

                        // Cable breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Cable Distribution")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)

                            ForEach(projectsVM.cableCountByType, id: \.0) { type, count in
                                HStack(spacing: 12) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(type.color)
                                        .frame(width: 32, height: 32)
                                        .background(type.color.opacity(0.1))
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(type.rawValue).font(FixoraFont.subheading(14)).foregroundColor(Color.textPrimary)
                                            Spacer()
                                            Text("\(count) cables").font(FixoraFont.mono(13)).foregroundColor(type.color)
                                        }
                                        GeometryReader { g in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3).fill(Color.divider).frame(height: 6)
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(type.color)
                                                    .frame(width: max(g.size.width * (appeared ? Double(count) / Double(max(projectsVM.totalCables, 1)) : 0), 4), height: 6)
                                                    .animation(.easeOut(duration: 0.8), value: appeared)
                                            }
                                        }.frame(height: 6)
                                    }
                                }
                            }
                        }
                        .cardStyle()

                        // Safety summary
                        let dangers = projectsVM.rooms.flatMap { $0.safetyZones }.filter { $0.severity == .danger }.count
                        let warnings = projectsVM.rooms.flatMap { $0.safetyZones }.filter { $0.severity == .warning }.count

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Safety Overview")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)

                            HStack(spacing: 12) {
                                SafetyReportBadge(count: dangers, label: "Danger\nZones", color: .statusDanger)
                                SafetyReportBadge(count: warnings, label: "Warning\nZones", color: .statusWarning)
                                SafetyReportBadge(count: projectsVM.totalPoints, label: "Socket\nPoints", color: .pointActive)
                                SafetyReportBadge(
                                    count: projectsVM.rooms.flatMap { $0.photoAttachments }.count,
                                    label: "Photo\nRecords",
                                    color: .accentPurple
                                )
                            }
                        }
                        .cardStyle()

                        // Per-room breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Room Details")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)

                            ForEach(projectsVM.rooms) { room in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(room.name).font(FixoraFont.subheading(14)).foregroundColor(Color.textPrimary)
                                        Text(String(format: "%.1f × %.1f m", room.width, room.height))
                                            .font(FixoraFont.caption(12)).foregroundColor(Color.textInactive)
                                    }
                                    Spacer()
                                    HStack(spacing: 10) {
                                        Text("\(room.cables.count) cables").font(FixoraFont.caption(12)).foregroundColor(Color.accentCyan)
                                        Text("\(room.points.count) pts").font(FixoraFont.caption(12)).foregroundColor(Color.pointActive)
                                    }
                                }
                                Divider().background(Color.divider)
                            }
                        }
                        .cardStyle()

                        // Export
                        Button {
                            exportToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                exportToast = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Report")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Toast
                if exportToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.statusSafe)
                            Text("Report exported successfully")
                                .font(FixoraFont.subheading(14))
                                .foregroundColor(Color.textPrimary)
                        }
                        .padding(16)
                        .background(Color.cardBg2)
                        .cornerRadius(14)
                        .darkShadow()
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: exportToast)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

struct ReportStat: View {
    let label: String
    let value: String
    let color: Color

    init(_ label: String, _ value: String, _ color: Color) {
        self.label = label; self.value = value; self.color = color
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(FixoraFont.heading(22)).foregroundColor(color)
            Text(label).font(FixoraFont.caption(10)).foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetyReportBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)").font(FixoraFont.heading(20)).foregroundColor(color)
            Text(label).font(FixoraFont.caption(10)).foregroundColor(Color.textInactive).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

struct FixoraProApprovalView: View {
    let viewModel: FixoraProViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("pro")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var actButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.acceptApproval()
            } label: {
                Image("prob")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.declineApproval()
            } label: {
                Text("Skip")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
}

struct HistoryView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                if projectsVM.history.isEmpty {
                    EmptyStateView(icon: "clock", title: "No History", subtitle: "Actions will appear here", actionTitle: nil, action: nil)
                } else {
                    List {
                        ForEach(projectsVM.history) { entry in
                            HistoryRow(entry: entry)
                                .listRowBackground(Color.bgMain)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        projectsVM.history.removeAll()
                    } label: {
                        Text("Clear")
                            .foregroundColor(Color.statusDanger)
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.icon)
                .font(.system(size: 16))
                .foregroundColor(Color.accentCyan)
                .frame(width: 36, height: 36)
                .background(Color.accentCyan.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.action)
                    .font(FixoraFont.subheading(14))
                    .foregroundColor(Color.textPrimary)
                Text(entry.detail)
                    .font(FixoraFont.caption(12))
                    .foregroundColor(Color.textInactive)
            }

            Spacer()

            Text(entry.formattedTime)
                .font(FixoraFont.caption(10))
                .foregroundColor(Color.textInactive)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @State private var showAdd = false
    @State private var filter: TaskFilter = .all

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case done = "Done"
    }

    var filteredTasks: [RepairTask] {
        switch filter {
        case .all: return projectsVM.tasks
        case .pending: return projectsVM.tasks.filter { !$0.isCompleted }
        case .done: return projectsVM.tasks.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter
                    HStack(spacing: 8) {
                        ForEach(TaskFilter.allCases, id: \.self) { f in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { filter = f }
                            } label: {
                                Text(f.rawValue)
                                    .font(FixoraFont.subheading(13))
                                    .foregroundColor(filter == f ? Color.bgPrimary : Color.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(filter == f ? Color.accentCyan : Color.cardBg2)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(IconButtonStyle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    if filteredTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(Color.textInactive)
                            Text(filter == .done ? "No completed tasks" : "No tasks yet")
                                .font(FixoraFont.heading(18))
                                .foregroundColor(Color.textSecondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRow(task: task)
                                    .listRowBackground(Color.bgPrimary)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            projectsVM.deleteTask(task)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            withAnimation { projectsVM.toggleTask(task) }
                                        } label: {
                                            Label(task.isCompleted ? "Pending" : "Done", systemImage: task.isCompleted ? "circle" : "checkmark")
                                        }
                                        .tint(task.isCompleted ? Color.statusWarning : Color.statusSafe)
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.accentCyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskView() }
    }
}

struct TaskRow: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let task: RepairTask

    var body: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    projectsVM.toggleTask(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? Color.statusSafe : Color.textInactive)
            }
            .buttonStyle(IconButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(FixoraFont.subheading(14))
                    .foregroundColor(task.isCompleted ? Color.textInactive : Color.textPrimary)
                    .strikethrough(task.isCompleted, color: Color.textInactive)

                if !task.detail.isEmpty {
                    Text(task.detail)
                        .font(FixoraFont.caption(12))
                        .foregroundColor(Color.textInactive)
                        .lineLimit(1)
                }

                if let due = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(FixoraFont.caption(11))
                    .foregroundColor(due < Date() && !task.isCompleted ? Color.statusDanger : Color.textInactive)
                }
            }

            Spacer()

            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct AddTaskView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var detail = ""
    @State private var priority: RepairTask.Priority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400)
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                            TextField("e.g. Check junction box", text: $title)
                                .textFieldStyle(FixoraTextFieldStyle())
                                .focused($titleFocused)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details (optional)")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                            TextField("Additional info...", text: $detail)
                                .textFieldStyle(FixoraTextFieldStyle())
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Priority")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)

                            HStack(spacing: 10) {
                                ForEach(RepairTask.Priority.allCases, id: \.self) { p in
                                    Button {
                                        withAnimation { priority = p }
                                    } label: {
                                        Text(p.rawValue)
                                            .font(FixoraFont.subheading(13))
                                            .foregroundColor(priority == p ? Color.bgPrimary : p.color)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(priority == p ? p.color : p.color.opacity(0.1))
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(IconButtonStyle())
                                }
                            }
                        }

                        // Due date
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $hasDueDate) {
                                Text("Due Date")
                                    .font(FixoraFont.subheading(14))
                                    .foregroundColor(Color.textPrimary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.accentCyan))

                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .accentColor(Color.accentCyan)
                                    .colorScheme(.dark)
                            }
                        }
                        .cardStyle()

                        Button("Add Task") {
                            guard !title.isEmpty else { return }
                            projectsVM.addTask(
                                title: title,
                                detail: detail,
                                priority: priority,
                                dueDate: hasDueDate ? dueDate : nil,
                                projectId: projectsVM.projects.first?.id
                            )
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
            .onAppear { titleFocused = true }
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Permission toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .font(FixoraFont.subheading(14))
                                .foregroundColor(Color.textPrimary)
                            Text("Reminders for maintenance tasks")
                                .font(FixoraFont.caption(12))
                                .foregroundColor(Color.textInactive)
                        }
                        Spacer()
                        Toggle("", isOn: $settingsVM.notificationsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color.accentCyan))
                    }
                    .cardStyle()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if projectsVM.notifications.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 48))
                                .foregroundColor(Color.textInactive)
                            Text("No Reminders")
                                .font(FixoraFont.heading(18))
                                .foregroundColor(Color.textSecondary)
                            Text("Tap + to add a reminder")
                                .font(FixoraFont.body(14))
                                .foregroundColor(Color.textInactive)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(projectsVM.notifications) { item in
                                NotificationRow(item: item)
                                    .listRowBackground(Color.bgMain)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            projectsVM.deleteNotification(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").foregroundColor(Color.accentCyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddNotificationView() }
    }
}

struct NotificationRow: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let item: NotificationItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.fill")
                .font(.system(size: 16))
                .foregroundColor(item.isEnabled ? Color.accentCyan : Color.textInactive)
                .frame(width: 36, height: 36)
                .background((item.isEnabled ? Color.accentCyan : Color.textInactive).opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(FixoraFont.subheading(14))
                    .foregroundColor(Color.textPrimary)
                Text(item.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                    .font(FixoraFont.caption(12))
                    .foregroundColor(Color.textInactive)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in projectsVM.toggleNotification(item) }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Color.accentCyan))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct AddNotificationView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var body_ = ""
    @State private var date = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        TextField("Reminder title", text: $title)
                            .textFieldStyle(FixoraTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        TextField("Reminder message", text: $body_)
                            .textFieldStyle(FixoraTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schedule")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        DatePicker("", selection: $date, in: Date()...)
                            .datePickerStyle(.graphical)
                            .accentColor(Color.accentCyan)
                            .colorScheme(.dark)
                    }

                    Button("Schedule Reminder") {
                        guard !title.isEmpty else { return }
                        if !settingsVM.notificationsEnabled {
                            settingsVM.notificationsEnabled = true
                        }
                        projectsVM.addNotification(
                            title: title,
                            body: body_.isEmpty ? "Fixora Pro reminder" : body_,
                            date: date,
                            projectId: projectsVM.projects.first?.id
                        )
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.5 : 1)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
    }
}
