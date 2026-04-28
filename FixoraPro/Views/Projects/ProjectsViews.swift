import SwiftUI
import WebKit

struct ProjectsListView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @State private var showAdd = false
    @State private var editingProject: Project? = nil
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if projectsVM.projects.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No Projects Yet",
                        subtitle: "Create your first project to start mapping cables",
                        actionTitle: "Create Project",
                        action: { showAdd = true }
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(projectsVM.projects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(
                                        project: project,
                                        roomCount: projectsVM.rooms(for: project.id).count,
                                        onEdit: { editingProject = project },
                                        onDelete: { projectsVM.deleteProject(project) }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .offset(y: appeared ? 0 : 30)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
                            }
                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Projects")
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
        .sheet(isPresented: $showAdd) { AddProjectView() }
        .sheet(item: $editingProject) { project in EditProjectView(project: project) }
        .onAppear { withAnimation { appeared = true } }
    }
}

struct ProjectCard: View {
    let project: Project
    let roomCount: Int
    var onEdit: () -> Void
    var onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentCyan.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.accentCyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(FixoraFont.heading(16))
                        .foregroundColor(Color.textPrimary)
                    Text("Updated \(project.formattedDate)")
                        .font(FixoraFont.caption(12))
                        .foregroundColor(Color.textInactive)
                }

                Spacer()

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(Color.textInactive)
                }
            }

            HStack(spacing: 16) {
                ProjectStat(value: "\(roomCount)", label: "Rooms", icon: "square.split.2x2.fill", color: .accentPurple)
                Divider().frame(height: 28).background(Color.divider)
                ProjectStat(value: "\(project.notes.isEmpty ? 0 : 1)", label: "Notes", icon: "note.text", color: .accentCyanLight)
            }
        }
        .cardStyle()
        .alert("Delete Project", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all rooms and cable data in this project.")
        }
    }
}
struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}
struct ProjectStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(FixoraFont.subheading(14))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(FixoraFont.caption(12))
                .foregroundColor(Color.textInactive)
        }
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var notes = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                                .padding(.horizontal, 2)
                            TextField("e.g. My Apartment", text: $name)
                                .textFieldStyle(FixoraTextFieldStyle())
                                .focused($nameFocused)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                                .padding(.horizontal, 2)
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $notes)
                                    .font(FixoraFont.body(15))
                                    .foregroundColor(Color.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.cardBg2)
                                    .frame(minHeight: 100)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))

                                if notes.isEmpty {
                                    Text("Add any notes about this project...")
                                        .font(FixoraFont.body(15))
                                        .foregroundColor(Color.textInactive)
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }

                        Button("Create Project") {
                            guard !name.isEmpty else { return }
                            projectsVM.addProject(name: name)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
            .onAppear { nameFocused = true }
        }
    }
}

// MARK: - Edit Project
struct EditProjectView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    var project: Project
    @State private var name: String
    @State private var notes: String

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _notes = State(initialValue: project.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        TextField("Project name", text: $name)
                            .textFieldStyle(FixoraTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .font(FixoraFont.body(15))
                                .foregroundColor(Color.textPrimary)
                                .scrollContentBackground(.hidden)
                                .background(Color.cardBg2)
                                .frame(minHeight: 100)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                            if notes.isEmpty {
                                Text("Notes...")
                                    .font(FixoraFont.body(15))
                                    .foregroundColor(Color.textInactive)
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    Button("Save Changes") {
                        var updated = project
                        updated.name = name
                        updated.notes = notes
                        projectsVM.updateProject(updated)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .navigationTitle("Edit Project")
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

// MARK: - Project Detail
struct ProjectDetailView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    var project: Project
    @State private var showAddRoom = false
    @State private var showEditProject = false

    var rooms: [Room] { projectsVM.rooms(for: project.id) }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if rooms.isEmpty {
                EmptyStateView(
                    icon: "square.dashed",
                    title: "No Rooms Yet",
                    subtitle: "Add a room to start mapping cables",
                    actionTitle: "Add Room",
                    action: { showAddRoom = true }
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(rooms) { room in
                            NavigationLink(destination: RoomDetailView(room: room)) {
                                RoomCard(room: room, onDelete: { projectsVM.deleteRoom(room) })
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showEditProject = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(Color.textSecondary)
                }
                Button {
                    showAddRoom = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
        .sheet(isPresented: $showAddRoom) { AddRoomView(projectId: project.id) }
        .sheet(isPresented: $showEditProject) { EditProjectView(project: project) }
    }
}
