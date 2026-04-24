import SwiftUI
import PhotosUI

// MARK: - Photos View
struct PhotosView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let room: Room
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var caption = ""
    @State private var selectedPhoto: PhotoAttachment? = nil

    var currentRoom: Room {
        projectsVM.rooms.first(where: { $0.id == room.id }) ?? room
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Add photo button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(Color.accentCyan)
                                Text("Attach Photo")
                                    .font(FixoraFont.subheading(15))
                                    .foregroundColor(Color.accentCyan)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.accentCyan.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentCyan.opacity(0.3), lineWidth: 1.5))
                        }
                        .onChange(of: selectedItem) { item in
                            loadPhoto(item: item)
                        }

                        if currentRoom.photoAttachments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color.textInactive)
                                Text("No photos yet")
                                    .font(FixoraFont.heading(18))
                                    .foregroundColor(Color.textSecondary)
                                Text("Attach photos of the wall to remember cable locations")
                                    .font(FixoraFont.body(14))
                                    .foregroundColor(Color.textInactive)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(currentRoom.photoAttachments) { photo in
                                    PhotoThumbnail(
                                        photo: photo,
                                        onDelete: { projectsVM.deletePhoto(photo, from: room.id) },
                                        onTap: { selectedPhoto = photo }
                                    )
                                }
                            }
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Photos")
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
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo, room: room)
        }
    }

    private func loadPhoto(item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    let photo = PhotoAttachment(imageData: data, caption: "Wall photo")
                    projectsVM.addPhoto(photo, to: room.id)
                }
            }
        }
    }
}

struct PhotoThumbnail: View {
    let photo: PhotoAttachment
    var onDelete: () -> Void
    var onTap: () -> Void
    @State private var showDelete = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBg)

                    if let data = photo.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 130)
                            .clipped()
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.textInactive)
                            .frame(height: 130)
                    }
                }
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Spacer()
                        if !photo.caption.isEmpty {
                            Text(photo.caption)
                                .font(FixoraFont.caption(11))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 6)
                                .lineLimit(1)
                        }
                    }
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                            .cornerRadius(12)
                    )
                )
            }
            .buttonStyle(IconButtonStyle())

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .background(Color.statusDanger)
                    .clipShape(Circle())
                    .padding(6)
            }
            .buttonStyle(IconButtonStyle())
        }
    }
}

struct PhotoDetailView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let photo: PhotoAttachment
    let room: Room
    @State private var caption: String

    init(photo: PhotoAttachment, room: Room) {
        self.photo = photo
        self.room = room
        _caption = State(initialValue: photo.caption)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 20) {
                    if let data = photo.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBg)
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color.textInactive)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        TextField("Add a caption...", text: $caption)
                            .textFieldStyle(FixoraTextFieldStyle())
                    }
                    .padding(.horizontal, 24)

                    Text(photo.createdAt.formatted())
                        .font(FixoraFont.caption(12))
                        .foregroundColor(Color.textInactive)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
    }
}

// MARK: - Notes View
struct NotesView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let room: Room
    @State private var notes: String = ""
    @FocusState private var focused: Bool

    var currentRoom: Room {
        projectsVM.rooms.first(where: { $0.id == room.id }) ?? room
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Character count
                    HStack {
                        Text("Cable notes and observations")
                            .font(FixoraFont.body(14))
                            .foregroundColor(Color.textInactive)
                        Spacer()
                        Text("\(notes.count) chars")
                            .font(FixoraFont.mono(12))
                            .foregroundColor(Color.textInactive)
                    }
                    .padding(.horizontal, 24)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $notes)
                            .font(FixoraFont.body(15))
                            .foregroundColor(Color.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Color.cardBg2)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
                            .padding(.horizontal, 24)
                            .focused($focused)

                        if notes.isEmpty {
                            Text("Add notes about cables, wiring, materials, installation dates...")
                                .font(FixoraFont.body(15))
                                .foregroundColor(Color.textInactive)
                                .padding(.horizontal, 40)
                                .padding(.top, 16)
                                .allowsHitTesting(false)
                        }
                    }

                    Button("Save Notes") {
                        projectsVM.updateNotes(notes, roomId: room.id)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("Notes — \(currentRoom.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
            .onAppear {
                notes = currentRoom.notes
                focused = true
            }
        }
    }
}
