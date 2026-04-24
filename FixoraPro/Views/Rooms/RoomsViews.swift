import SwiftUI

// MARK: - Rooms List (global)
struct RoomsListView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    var projectId: UUID?
    @State private var showAddRoom = false
    @State private var appeared = false

    var displayedRooms: [Room] {
        if let pid = projectId {
            return projectsVM.rooms.filter { $0.projectId == pid }
        }
        return projectsVM.rooms
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if displayedRooms.isEmpty {
                    EmptyStateView(
                        icon: "square.dashed",
                        title: "No Rooms Yet",
                        subtitle: "Add rooms to start mapping your cables",
                        actionTitle: "Add Room",
                        action: { showAddRoom = true }
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(displayedRooms) { room in
                                NavigationLink(destination: RoomDetailView(room: room)) {
                                    RoomCard(room: room, onDelete: { projectsVM.deleteRoom(room) })
                                }
                                .buttonStyle(PlainButtonStyle())
                                .offset(y: appeared ? 0 : 20)
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
            .navigationTitle("Rooms")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddRoom = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.accentCyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(projectId: projectId ?? projectsVM.projects.first?.id ?? UUID())
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: Room
    var onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentPurple.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.accentPurpleSoft)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(FixoraFont.heading(15))
                        .foregroundColor(Color.textPrimary)
                    Text(String(format: "%.1f × %.1f m", room.width, room.height))
                        .font(FixoraFont.caption(12))
                        .foregroundColor(Color.textInactive)
                }

                Spacer()

                Menu {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(Color.textInactive)
                }
            }

            // Cable type indicators
            HStack(spacing: 8) {
                ForEach(CableType.allCases, id: \.self) { type in
                    let count = room.cables.filter { $0.type == type }.count
                    if count > 0 {
                        HStack(spacing: 4) {
                            Circle().fill(type.color).frame(width: 6, height: 6)
                            Text("\(count) \(type.rawValue)")
                                .font(FixoraFont.caption(11))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(type.color.opacity(0.1))
                        .cornerRadius(6)
                    }
                }

                if room.cables.isEmpty {
                    Text("No cables mapped")
                        .font(FixoraFont.caption(11))
                        .foregroundColor(Color.textInactive)
                }
            }

            // Stats row
            HStack(spacing: 16) {
                RoomStat(icon: "bolt.horizontal.fill", value: "\(room.cables.count)", label: "Cables", color: .accentCyan)
                RoomStat(icon: "powerplug.fill", value: "\(room.points.count)", label: "Points", color: .pointActive)
                RoomStat(icon: "photo.fill", value: "\(room.photoAttachments.count)", label: "Photos", color: .accentPurple)
            }
        }
        .cardStyle()
        .alert("Delete Room", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All cable data in this room will be deleted.")
        }
    }
}

struct RoomStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
            Text(value).font(FixoraFont.subheading(13)).foregroundColor(Color.textPrimary)
            Text(label).font(FixoraFont.caption(11)).foregroundColor(Color.textInactive)
        }
    }
}

// MARK: - Add Room
struct AddRoomView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let projectId: UUID
    @State private var name = ""
    @State private var width: Double = 4.0
    @State private var height: Double = 3.0
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room Name")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                            TextField("e.g. Living Room", text: $name)
                                .textFieldStyle(FixoraTextFieldStyle())
                                .focused($nameFocused)
                        }

                        // Dimensions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Room Dimensions")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)

                            // Width slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Width")
                                        .font(FixoraFont.body(14))
                                        .foregroundColor(Color.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.1f m", width))
                                        .font(FixoraFont.mono(14))
                                        .foregroundColor(Color.accentCyan)
                                }
                                Slider(value: $width, in: 1...20, step: 0.1)
                                    .accentColor(Color.accentCyan)
                            }

                            // Height slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Length")
                                        .font(FixoraFont.body(14))
                                        .foregroundColor(Color.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.1f m", height))
                                        .font(FixoraFont.mono(14))
                                        .foregroundColor(Color.accentCyan)
                                }
                                Slider(value: $height, in: 1...20, step: 0.1)
                                    .accentColor(Color.accentCyan)
                            }
                        }
                        .cardStyle()

                        // Preview
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preview")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)

                            GeometryReader { geo in
                                let scale = min(geo.size.width / width, 120 / height)
                                let rw = width * scale
                                let rh = height * scale

                                ZStack {
                                    if #available(iOS 17.0, *) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.wallFill)
                                            .stroke(Color.accentCyan, lineWidth: 2)
                                            .frame(width: rw, height: rh)
                                    } else {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.wallFill)
                                            .frame(width: rw, height: rh)
                                        
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .stroke(Color.accentCyan, lineWidth: 2)
                                            .frame(width: rw, height: rh)
                                    }
                                    Text(String(format: "%.1f×%.1f m", width, height))
                                        .font(FixoraFont.caption(10))
                                        .foregroundColor(Color.accentCyan)
                                }
                                .position(x: geo.size.width / 2, y: 70)
                            }
                            .frame(height: 140)
                            .background(Color.cardBg)
                            .cornerRadius(12)
                        }

                        Button("Create Room") {
                            guard !name.isEmpty else { return }
                            projectsVM.addRoom(name: name, width: width, height: height, projectId: projectId)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Room")
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

// MARK: - Room Detail
struct RoomDetailView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    var room: Room
    @State private var showCableMap = false
    @State private var showPhotos = false
    @State private var showNotes = false
    @State private var showSafety = false
    @State private var showAddPoint = false

    var currentRoom: Room {
        projectsVM.rooms.first(where: { $0.id == room.id }) ?? room
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Stats
                    HStack(spacing: 12) {
                        RoomDetailStat(value: "\(currentRoom.cables.count)", label: "Cables", color: .accentCyan)
                        RoomDetailStat(value: "\(currentRoom.points.count)", label: "Points", color: .pointActive)
                        RoomDetailStat(value: "\(currentRoom.safetyZones.count)", label: "Zones", color: .statusDanger)
                        RoomDetailStat(value: "\(currentRoom.photoAttachments.count)", label: "Photos", color: .accentPurple)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Quick actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        RoomActionButton(
                            icon: "cable.connector.horizontal",
                            title: "Cable Map",
                            subtitle: "\(currentRoom.cables.count) cables",
                            color: .accentCyan
                        ) { showCableMap = true }

                        RoomActionButton(
                            icon: "photo.stack.fill",
                            title: "Photos",
                            subtitle: "\(currentRoom.photoAttachments.count) attached",
                            color: .accentPurple
                        ) { showPhotos = true }

                        RoomActionButton(
                            icon: "note.text",
                            title: "Notes",
                            subtitle: currentRoom.notes.isEmpty ? "No notes" : "Has notes",
                            color: .accentCyanLight
                        ) { showNotes = true }

                        RoomActionButton(
                            icon: "exclamationmark.triangle.fill",
                            title: "Safety Zones",
                            subtitle: "\(currentRoom.safetyZones.count) zones",
                            color: .statusWarning
                        ) { showSafety = true }
                    }
                    .padding(.horizontal, 20)

                    // Cable list
                    if !currentRoom.cables.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cables")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)

                            ForEach(currentRoom.cables) { cable in
                                CableListRow(cable: cable, onDelete: {
                                    projectsVM.deleteCable(cable, from: room.id)
                                })
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                    }

                    // Points list
                    if !currentRoom.points.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Points & Sockets")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)

                            ForEach(currentRoom.points) { point in
                                PointListRow(point: point, onDelete: {
                                    projectsVM.deletePoint(point, from: room.id)
                                })
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 80)
                }
            }
        }
        .navigationTitle(currentRoom.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCableMap) { CableMapView(room: currentRoom) }
        .sheet(isPresented: $showPhotos) { PhotosView(room: currentRoom) }
        .sheet(isPresented: $showNotes) { NotesView(room: currentRoom) }
        .sheet(isPresented: $showSafety) { SafetyZonesView(room: currentRoom) }
    }
}

struct RoomDetailStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(FixoraFont.heading(22))
                .foregroundColor(color)
            Text(label)
                .font(FixoraFont.caption(11))
                .foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct RoomActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FixoraFont.subheading(14))
                        .foregroundColor(Color.textPrimary)
                    Text(subtitle)
                        .font(FixoraFont.caption(11))
                        .foregroundColor(Color.textInactive)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(color.opacity(0.07))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(IconButtonStyle())
    }
}

struct CableListRow: View {
    let cable: Cable
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(cable.type.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(cable.label.isEmpty ? cable.type.rawValue : cable.label)
                    .font(FixoraFont.subheading(13))
                    .foregroundColor(Color.textPrimary)
                Text("Depth: \(String(format: "%.1f", cable.depth)) cm · \(cable.points.count) points")
                    .font(FixoraFont.caption(11))
                    .foregroundColor(Color.textInactive)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color.statusDanger.opacity(0.7))
            }
            .buttonStyle(IconButtonStyle())
        }
        .padding(.vertical, 6)
    }
}

struct PointListRow: View {
    let point: CablePoint
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: point.type.icon)
                .font(.system(size: 14))
                .foregroundColor(Color.pointActive)
                .frame(width: 28, height: 28)
                .background(Color.pointActive.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(point.label.isEmpty ? point.type.rawValue : point.label)
                    .font(FixoraFont.subheading(13))
                    .foregroundColor(Color.textPrimary)
                Text("Depth: \(String(format: "%.1f", point.depth)) cm")
                    .font(FixoraFont.caption(11))
                    .foregroundColor(Color.textInactive)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color.statusDanger.opacity(0.7))
            }
            .buttonStyle(IconButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
