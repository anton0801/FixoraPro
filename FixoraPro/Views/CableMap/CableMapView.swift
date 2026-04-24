import SwiftUI

// MARK: - Cable Map View Model
class CableMapViewModel: ObservableObject {
    @Published var currentPoints: [CGPoint] = []
    @Published var isDrawing = false
    @Published var selectedCableType: CableType = .electric
    @Published var currentDepth: Double = 3.0
    @Published var currentLabel: String = ""
    @Published var showTypeSelector = false
    @Published var showDepthInfo = false
    @Published var showAddPoint = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var selectedCable: Cable? = nil
    @Published var activeTool: Tool = .draw

    enum Tool {
        case draw, point, safetyZone, erase
    }

    func startDrawing(at point: CGPoint) {
        isDrawing = true
        currentPoints = [point]
    }

    func addPoint(_ point: CGPoint) {
        guard isDrawing else { return }
        if let last = currentPoints.last {
            let dx = point.x - last.x
            let dy = point.y - last.y
            if sqrt(dx*dx + dy*dy) > 8 {
                currentPoints.append(point)
            }
        }
    }

    func finalizeCable() -> Cable? {
        guard currentPoints.count >= 2 else {
            currentPoints = []
            isDrawing = false
            return nil
        }
        let cable = Cable(
            type: selectedCableType,
            points: currentPoints,
            depth: currentDepth,
            label: currentLabel.isEmpty ? selectedCableType.rawValue : currentLabel
        )
        currentPoints = []
        isDrawing = false
        return cable
    }

    func cancelDrawing() {
        currentPoints = []
        isDrawing = false
    }
}

// MARK: - CableMapView
struct CableMapView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = CableMapViewModel()
    let room: Room
    @EnvironmentObject var settingsVM: SettingsViewModel

    var currentRoom: Room {
        projectsVM.rooms.first(where: { $0.id == room.id }) ?? room
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Toolbar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Tool buttons
                            ForEach([
                                (CableMapViewModel.Tool.draw, "pencil.tip", "Draw"),
                                (.point, "plus.circle", "Point"),
                                (.safetyZone, "exclamationmark.triangle", "Zone"),
                                (.erase, "eraser", "Erase")
                            ], id: \.2) { tool, icon, label in
                                ToolButton(
                                    icon: icon,
                                    label: label,
                                    isActive: vm.activeTool == tool,
                                    action: { vm.activeTool = tool }
                                )
                            }

                            Divider()
                                .frame(height: 32)
                                .background(Color.divider)

                            // Cable type
                            Button {
                                vm.showTypeSelector = true
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(vm.selectedCableType.color)
                                        .frame(width: 10, height: 10)
                                    Text(vm.selectedCableType.rawValue)
                                        .font(FixoraFont.caption(12))
                                        .foregroundColor(Color.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.textInactive)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(vm.selectedCableType.color.opacity(0.15))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(vm.selectedCableType.color.opacity(0.4), lineWidth: 1))
                            }

                            // Depth
                            Button {
                                vm.showDepthInfo = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.to.line")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.accentPurpleSoft)
                                    Text("\(String(format: "%.0f", vm.currentDepth))cm")
                                        .font(FixoraFont.mono(12))
                                        .foregroundColor(Color.accentPurpleSoft)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.accentPurple.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color.bgSoft)
                    .overlay(Divider().background(Color.divider), alignment: .bottom)

                    // Canvas
                    GeometryReader { geo in
                        ZStack {
                            // Grid
                            if settingsVM.showGrid {
                                CanvasGrid(size: geo.size, gridSize: CGFloat(settingsVM.gridSize))
                            }

                            // Room outline
                            RoomOutlineView(room: currentRoom, canvasSize: geo.size)

                            // Existing safety zones
                            ForEach(currentRoom.safetyZones) { zone in
                                SafetyZoneOverlay(zone: zone, canvasSize: geo.size)
                            }

                            // Existing cables
                            ForEach(currentRoom.cables) { cable in
                                CablePathView(
                                    cable: cable,
                                    isSelected: vm.selectedCable?.id == cable.id,
                                    showDepth: settingsVM.showDepthLabels
                                )
                                .onTapGesture {
                                    if vm.activeTool == .erase {
                                        projectsVM.deleteCable(cable, from: room.id)
                                    } else {
                                        vm.selectedCable = vm.selectedCable?.id == cable.id ? nil : cable
                                    }
                                }
                            }

                            // Existing points
                            ForEach(currentRoom.points) { point in
                                CablePointMarker(point: point)
                                    .position(canvasPosition(for: point.position, in: geo.size))
                                    .onTapGesture {
                                        if vm.activeTool == .erase {
                                            projectsVM.deletePoint(point, from: room.id)
                                        }
                                    }
                            }

                            // Current drawing
                            if vm.currentPoints.count > 1 {
                                Path { path in
                                    path.move(to: vm.currentPoints[0])
                                    for p in vm.currentPoints.dropFirst() {
                                        path.addLine(to: p)
                                    }
                                }
                                .stroke(
                                    vm.selectedCableType.color,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 4])
                                )
                                .cyanGlow(radius: 4)
                            }
                        }
                        .background(Color.bgMain)
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { value in
                                    handleDrag(value: value, in: geo)
                                }
                                .onEnded { value in
                                    handleDragEnd(in: geo)
                                }
                        )
                        .onTapGesture { location in
                            handleTap(at: location, in: geo)
                        }
                    }
                }

                // Cancel drawing overlay
                if vm.isDrawing {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                vm.cancelDrawing()
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button("Finish Cable") {
                                if let cable = vm.finalizeCable() {
                                    projectsVM.addCable(cable, to: room.id)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("\(currentRoom.name) — Cable Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgSoft, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.showAddPoint = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showTypeSelector) {
            CableTypeSelector(selectedType: $vm.selectedCableType, label: $vm.currentLabel)
        }
        .sheet(isPresented: $vm.showDepthInfo) {
            DepthInfoView(depth: $vm.currentDepth)
        }
        .sheet(isPresented: $vm.showAddPoint) {
            AddPointView(room: currentRoom)
        }
        .alert("Cable Map", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    private func handleDrag(value: DragGesture.Value, in geo: GeometryProxy) {
        if vm.activeTool == .draw {
            if !vm.isDrawing {
                vm.startDrawing(at: value.location)
            } else {
                var pt = value.location
                if settingsVM.snapToGrid {
                    let grid = CGFloat(settingsVM.gridSize)
                    pt.x = round(pt.x / grid) * grid
                    pt.y = round(pt.y / grid) * grid
                }
                vm.addPoint(pt)
            }
        }
    }

    private func handleDragEnd(in geo: GeometryProxy) {
        if vm.activeTool == .draw && vm.currentPoints.count >= 2 {
            // Keep drawing active - user taps "Finish"
        } else if vm.activeTool == .draw {
            vm.cancelDrawing()
        }
    }

    private func handleTap(at location: CGPoint, in geo: GeometryProxy) {
        if vm.activeTool == .point {
            vm.showAddPoint = true
        } else if vm.activeTool == .safetyZone {
            let zone = SafetyZone(
                rect: CGRect(x: location.x - 40, y: location.y - 30, width: 80, height: 60),
                reason: "Marked zone",
                severity: .danger
            )
            projectsVM.addSafetyZone(zone, to: room.id)
        }
    }

    private func canvasPosition(for modelPoint: CGPoint, in size: CGSize) -> CGPoint {
        // Model coords → canvas coords (1:1 in this version, scaled by room)
        return modelPoint
    }
}

// MARK: - Canvas Components
struct CanvasGrid: View {
    let size: CGSize
    let gridSize: CGFloat

    var body: some View {
        Canvas { ctx, s in
            var x: CGFloat = 0
            while x <= s.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: s.height))
                ctx.stroke(p, with: .color(Color.gridLine.opacity(0.5)), lineWidth: 0.5)
                x += gridSize
            }
            var y: CGFloat = 0
            while y <= s.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: s.width, y: y))
                ctx.stroke(p, with: .color(Color.gridLine.opacity(0.5)), lineWidth: 0.5)
                y += gridSize
            }
        }
    }
}

struct RoomOutlineView: View {
    let room: Room
    let canvasSize: CGSize

    var body: some View {
        let margin: CGFloat = 24
        let scaleX = (canvasSize.width - margin * 2) / max(CGFloat(room.width) * 50, 1)
        let scaleY = (canvasSize.height - margin * 2) / max(CGFloat(room.height) * 50, 1)
        let scale = min(scaleX, scaleY, 1.0)

        let rw = CGFloat(room.width) * 50 * scale
        let rh = CGFloat(room.height) * 50 * scale

        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.wallFill.opacity(0.3))
                .frame(width: rw, height: rh)
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2)

            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.wallOutline, lineWidth: 2)
                .frame(width: rw, height: rh)
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2)

            // Dimension labels
            Text(String(format: "%.1f m", room.width))
                .font(FixoraFont.mono(10))
                .foregroundColor(Color.textInactive)
                .position(x: canvasSize.width / 2, y: canvasSize.height / 2 + rh / 2 + 14)

            Text(String(format: "%.1f m", room.height))
                .font(FixoraFont.mono(10))
                .foregroundColor(Color.textInactive)
                .rotationEffect(.degrees(-90))
                .position(x: canvasSize.width / 2 - rw / 2 - 16, y: canvasSize.height / 2)
        }
    }
}

struct CablePathView: View {
    let cable: Cable
    var isSelected: Bool
    var showDepth: Bool

    var body: some View {
        ZStack {
            if cable.points.count >= 2 {
                // Glow
                Path { p in
                    p.move(to: cable.points[0])
                    for pt in cable.points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(cable.type.color.opacity(isSelected ? 0.5 : 0.25), lineWidth: isSelected ? 14 : 10)

                // Main line
                Path { p in
                    p.move(to: cable.points[0])
                    for pt in cable.points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(cable.type.color, style: StrokeStyle(lineWidth: isSelected ? 4 : 2.5, lineCap: .round, lineJoin: .round))

                // Start dot
                Circle()
                    .fill(cable.type.color)
                    .frame(width: 8, height: 8)
                    .position(cable.points[0])

                // End dot
                Circle()
                    .fill(cable.type.color)
                    .frame(width: 8, height: 8)
                    .position(cable.points.last!)

                // Depth label
                if showDepth, let mid = cable.points.middle {
                    Text("\(String(format: "%.0f", cable.depth))cm")
                        .font(FixoraFont.mono(9))
                        .foregroundColor(cable.type.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.bgPrimary.opacity(0.8))
                        .cornerRadius(4)
                        .position(mid)
                }
            }
        }
    }
}

extension Array {
    var middle: Element? {
        guard !isEmpty else { return nil }
        return self[count / 2]
    }
}

struct SafetyZoneOverlay: View {
    let zone: SafetyZone
    let canvasSize: CGSize

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(zone.severity.color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(zone.severity.color.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
            .frame(width: zone.rect.width, height: zone.rect.height)
            .position(x: zone.rect.midX, y: zone.rect.midY)
            .overlay(
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(zone.severity.color)
                    .font(.system(size: 12))
                    .position(x: zone.rect.midX, y: zone.rect.midY)
            )
    }
}

struct CablePointMarker: View {
    let point: CablePoint

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.pointActive.opacity(0.2))
                .frame(width: 20, height: 20)

            Image(systemName: point.type.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.pointActive)
        }
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isActive ? Color.accentCyan : Color.textSecondary)
                Text(label)
                    .font(FixoraFont.caption(9))
                    .foregroundColor(isActive ? Color.accentCyan : Color.textInactive)
            }
            .frame(width: 52, height: 48)
            .background(isActive ? Color.accentCyan.opacity(0.12) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? Color.accentCyan.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(IconButtonStyle())
    }
}

// MARK: - Cable Type Selector
struct CableTypeSelector: View {
    @Binding var selectedType: CableType
    @Binding var label: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 20) {
                    ForEach(CableType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(type.color.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: type.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(type.color)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.rawValue)
                                        .font(FixoraFont.subheading(16))
                                        .foregroundColor(Color.textPrimary)
                                    Text(type.description)
                                        .font(FixoraFont.caption(13))
                                        .foregroundColor(Color.textInactive)
                                }

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.accentCyan)
                                }
                            }
                            .cardStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Label input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cable Label (optional)")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        TextField("e.g. Main power line", text: $label)
                            .textFieldStyle(FixoraTextFieldStyle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Cable Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgMain, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentCyan)
                }
            }
        }
    }
}

// MARK: - Depth Info
struct DepthInfoView: View {
    @Binding var depth: Double
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Visual
                    ZStack {
                        VStack(spacing: 0) {
                            Color.wallFill.frame(height: 80)
                            Color.bgPrimary.frame(height: 40)
                        }
                        .cornerRadius(12)
                        .overlay(
                            VStack {
                                Spacer().frame(height: CGFloat(depth) * 4)
                                HStack {
                                    Image(systemName: "cable.connector.horizontal")
                                        .foregroundColor(Color.accentCyan)
                                    Text("\(String(format: "%.0f", depth)) cm")
                                        .font(FixoraFont.mono(13))
                                        .foregroundColor(Color.accentCyan)
                                }
                                Spacer()
                            }
                        )
                    }
                    .frame(height: 120)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Cable Depth")
                                .font(FixoraFont.subheading(16))
                                .foregroundColor(Color.textPrimary)
                            Spacer()
                            Text(String(format: "%.1f cm", depth))
                                .font(FixoraFont.mono(16))
                                .foregroundColor(Color.accentPurple)
                        }

                        Slider(value: $depth, in: 0.5...15, step: 0.5)
                            .accentColor(Color.accentPurple)
                    }
                    .cardStyle()

                    // Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Common Depths")
                            .font(FixoraFont.subheading(14))
                            .foregroundColor(Color.textPrimary)

                        HStack(spacing: 10) {
                            ForEach([1.5, 3.0, 5.0, 8.0], id: \.self) { preset in
                                Button {
                                    withAnimation { depth = preset }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(String(format: "%.1f", preset))
                                            .font(FixoraFont.mono(14))
                                            .foregroundColor(depth == preset ? Color.bgPrimary : Color.accentPurple)
                                        Text("cm")
                                            .font(FixoraFont.caption(10))
                                            .foregroundColor(depth == preset ? Color.bgPrimary.opacity(0.7) : Color.textInactive)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(depth == preset ? Color.accentPurple : Color.accentPurple.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(IconButtonStyle())
                            }
                        }
                    }

                    Button("Apply Depth") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .navigationTitle("Cable Depth")
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

// MARK: - Add Point
struct AddPointView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let room: Room
    @State private var pointType: CablePoint.PointType = .socket
    @State private var label = ""
    @State private var depth: Double = 5.0

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Type
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Point Type")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)

                            ForEach(CablePoint.PointType.allCases, id: \.self) { type in
                                Button {
                                    pointType = type
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(Color.pointActive)
                                            .frame(width: 36)
                                        Text(type.rawValue)
                                            .font(FixoraFont.body(15))
                                            .foregroundColor(Color.textPrimary)
                                        Spacer()
                                        if pointType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color.accentCyan)
                                        }
                                    }
                                    .cardStyle(padding: 14)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Label")
                                .font(FixoraFont.caption(13))
                                .foregroundColor(Color.textSecondary)
                            TextField("e.g. Bedroom outlet", text: $label)
                                .textFieldStyle(FixoraTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Installation Depth")
                                    .font(FixoraFont.caption(13))
                                    .foregroundColor(Color.textSecondary)
                                Spacer()
                                Text(String(format: "%.1f cm", depth))
                                    .font(FixoraFont.mono(13))
                                    .foregroundColor(Color.accentPurple)
                            }
                            Slider(value: $depth, in: 0.5...20, step: 0.5)
                                .accentColor(Color.accentPurple)
                        }

                        Button("Add Point") {
                            let point = CablePoint(
                                type: pointType,
                                position: CGPoint(x: 150, y: 150),
                                label: label,
                                depth: depth
                            )
                            projectsVM.addPoint(point, to: room.id)
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Point")
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

// MARK: - Safety Zones
struct SafetyZonesView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let room: Room
    @State private var newReason = ""
    @State private var severity: SafetyZone.Severity = .danger
    @State private var showAdd = false

    var currentRoom: Room {
        projectsVM.rooms.first(where: { $0.id == room.id }) ?? room
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()

                VStack(spacing: 0) {
                    if currentRoom.safetyZones.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(Color.textInactive)
                            Text("No Safety Zones")
                                .font(FixoraFont.heading(18))
                                .foregroundColor(Color.textSecondary)
                            Text("Tap + to mark a danger area on the map")
                                .font(FixoraFont.body(14))
                                .foregroundColor(Color.textInactive)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(currentRoom.safetyZones) { zone in
                                SafetyZoneRow(zone: zone)
                                    .listRowBackground(Color.bgMain)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            projectsVM.deleteSafetyZone(zone, from: room.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.bgMain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Safety Zones")
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
        .sheet(isPresented: $showAdd) {
            AddSafetyZoneSheet(room: room)
        }
    }
}

struct SafetyZoneRow: View {
    let zone: SafetyZone

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(zone.severity.color)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(zone.severity.color.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(zone.reason)
                    .font(FixoraFont.subheading(14))
                    .foregroundColor(Color.textPrimary)
                Text(zone.severity.rawValue)
                    .font(FixoraFont.caption(12))
                    .foregroundColor(zone.severity.color)
            }
        }
        .padding(.vertical, 6)
    }
}

struct AddSafetyZoneSheet: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.dismiss) var dismiss
    let room: Room
    @State private var reason = ""
    @State private var severity: SafetyZone.Severity = .danger

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgMain.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        TextField("e.g. High voltage cable", text: $reason)
                            .textFieldStyle(FixoraTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Severity")
                            .font(FixoraFont.caption(13))
                            .foregroundColor(Color.textSecondary)
                        Picker("Severity", selection: $severity) {
                            Text("Warning").tag(SafetyZone.Severity.warning)
                            Text("Danger").tag(SafetyZone.Severity.danger)
                        }
                        .pickerStyle(.segmented)
                    }

                    Button("Add Zone") {
                        let zone = SafetyZone(
                            rect: CGRect(x: 60, y: 60, width: 100, height: 80),
                            reason: reason.isEmpty ? "Marked zone" : reason,
                            severity: severity
                        )
                        projectsVM.addSafetyZone(zone, to: room.id)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add Safety Zone")
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
