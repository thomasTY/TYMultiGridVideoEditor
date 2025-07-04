import SwiftUI
import UniformTypeIdentifiers
import AVKit

struct PlaceholderView: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(color)
            Text(title).font(.title2).foregroundColor(Theme.secondaryTextColor)
        }
    }
}

struct CanvasView: View {
    @ObservedObject private var appState = AppState.shared
    @State private var isTargeted = false
    // 全局主控
    @State private var isPlaying = false
    @State private var isMuted = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 5 // 默认5s，后续根据所有素材最大时长动态调整
    @State private var timer: Timer? = nil
    // 选中单元格（多选）
    @State private var selectedCells: Set<Int> = []
    // 拖拽排序状态
    @State private var draggedAssetId: UUID? = nil
    // 参数Binding
    @Binding var rowCount: Int
    @Binding var colCount: Int
    @Binding var cellAspect: CGFloat
    @Binding var rowSpacing: CGFloat
    @Binding var colSpacing: CGFloat
    @Binding var canvasAspectRatio: CGFloat
    let canvasPadding: CGFloat

    var body: some View {
        ZStack {
            // 背景色+圆角+阴影
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.secondaryBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            VStack(spacing: 0) {
                // 头部栏
                HStack {
                    Text("画布区")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.primaryTextColor)
                    Spacer()
                }
                .padding(12)
                .background(Theme.headerBackgroundColor)
                // 分割线
                Divider().opacity(0.7)
                // 画布宫格区
                GeometryReader { geo in
                    ZStack {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCells.removeAll()
                            }
                        let rows = rowCount
                        let cols = colCount
                        let W = geo.size.width - 2 * canvasPadding
                        let H = geo.size.height - 60 - 2 * canvasPadding
                        let cellH = (H - CGFloat(rows-1)*rowSpacing) / CGFloat(rows)
                        let cellW = cellH * cellAspect
                        let totalCellW = CGFloat(cols) * cellW
                        let actualColSpacing: CGFloat = cols > 1 ? max((W - totalCellW) / CGFloat(cols - 1), colSpacing) : 0
                        CanvasGridView(
                            rows: rows,
                            cols: cols,
                            cellW: cellW,
                            cellH: cellH,
                            actualColSpacing: actualColSpacing,
                            rowSpacing: rowSpacing,
                            selectedCells: selectedCells,
                            appState: appState,
                            currentTime: currentTime,
                            isPlaying: isPlaying,
                            isMuted: isMuted,
                            removeAsset: removeAsset,
                            handleCellTap: handleCellTap,
                            draggedAssetId: $draggedAssetId
                        )
                        .padding(canvasPadding)
                    }
                }
                .aspectRatio(canvasAspectRatio, contentMode: .fit)
                .padding(.horizontal, 12)
                .padding(.bottom, 0)
                // 播放控制栏
                VStack(spacing: 0) {
                    HStack {
                        Button(action: togglePlay) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Button(action: toggleMute) {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        let safeDuration = duration > 0 ? duration : 0.01
                        Slider(value: $currentTime, in: 0...safeDuration, step: 0.01, onEditingChanged: { editing in
                            if !editing { syncAllPlayers() }
                        })
                        .accentColor(Theme.accentColor)
                        .disabled(duration <= 0)
                        Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.leading, 4)
                    }
                    .padding([.leading, .trailing, .bottom], 8)
                }
                .background(Color.black.opacity(0.7))
                .frame(height: 60)
            }
        }
        .padding(10)
        .onAppear {
            updateDuration()
        }
        .onChange(of: appState.canvasAssets) { _ in
            updateDuration()
        }
        .onChange(of: appState.mediaAssets) { _ in
            updateDuration()
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    if let idStr = object as? String {
                        let ids = idStr.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
                        for assetId in ids {
                            addAsset(assetId)
                        }
                    }
                }
                return true
            }
            return false
        }
    }
    
    private func addAsset(_ assetId: UUID) {
        if !appState.canvasAssets.contains(assetId) {
            appState.canvasAssets.append(assetId)
            appState.addAssetToCanvas(assetId)
        }
    }
    
    private func removeAsset(_ assetId: UUID) {
        appState.canvasAssets.removeAll { $0 == assetId }
        appState.removeAssetFromCanvas(assetId)
    }
    private func updateDuration() {
        // 取所有素材最大时长，图片5s
        let maxVideo = appState.mediaAssets.filter { appState.canvasAssets.contains($0.id) && $0.type == .video }.compactMap { $0.duration }.max() ?? 0
        let hasImage = appState.mediaAssets.contains { appState.canvasAssets.contains($0.id) && $0.type == .image }
        let maxImage = hasImage ? 5.0 : 0.0
        duration = max(maxVideo, maxImage)
        if currentTime > duration { currentTime = duration }
    }
    private func togglePlay() {
        isPlaying.toggle()
        syncAllPlayers()
    }
    private func toggleMute() {
        isMuted.toggle()
        syncAllPlayers()
    }
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            if isPlaying {
                currentTime += 0.03
                if currentTime >= duration {
                    currentTime = duration
                    isPlaying = false
                    stopTimer()
                }
                syncAllPlayers()
            }
        }
    }
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    private func syncAllPlayers() {
        NotificationCenter.default.post(name: .canvasGlobalSync, object: nil, userInfo: [
            "currentTime": currentTime,
            "isPlaying": isPlaying,
            "isMuted": isMuted
        ])
    }
    private func formatTime(_ t: Double) -> String {
        let totalSeconds = Int(t)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let ms = Int((t - Double(totalSeconds)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, ms)
    }
    // 多选辅助方法
    private func handleCellTap(at index: Int) {
        if NSEvent.modifierFlags.contains(.command) {
            if selectedCells.contains(index) {
                selectedCells.remove(index)
            } else {
                selectedCells.insert(index)
            }
        } else {
            selectedCells = [index]
        }
    }
}

struct CanvasAssetCell: View {
    let assetId: UUID?
    let cellSize: CGSize
    let isSelected: Bool
    let showSplitLine: Bool
    let removeAction: (() -> Void)?
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            // 遮罩层
            Rectangle()
                .fill(Color.black.opacity(0.85))
                .frame(width: cellSize.width, height: cellSize.height)
                .clipped()
                .overlay(
                    Group {
                        if let assetId = assetId, let asset = appState.mediaAssets.first(where: { $0.id == assetId }) {
                            if asset.url == nil {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(Text("无效素材").foregroundColor(.gray).font(.caption))
                            } else if asset.type == .image {
                                if let img = asset.thumbnail {
                                    Image(nsImage: img)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Rectangle().fill(Color.gray.opacity(0.3))
                                }
                            } else if asset.type == .video, let _ = asset.url {
                                // 只显示首帧静态图
                                if let img = asset.thumbnail {
                                    Image(nsImage: img)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Rectangle().fill(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    }
                    .frame(width: cellSize.width, height: cellSize.height)
                    .clipped()
                )
            // 分割线（浅蓝色粗实线）
            if showSplitLine {
                SplitLineOverlay(size: cellSize, color: Color.blue.opacity(0.7), lineWidth: 3)
            }
            // 选中时显示白色虚线和4角圆点
            if isSelected {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundColor(.white)
                    .frame(width: cellSize.width-2, height: cellSize.height-2)
                // 4角圆点
                ForEach(0..<4) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .position(cornerPosition(i, in: cellSize))
                }
            }
            // 删除按钮
            if let removeAction = removeAction {
                Button(action: removeAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Theme.accentColor)
                }
                .buttonStyle(.plain)
                .padding(5)
                .position(x: cellSize.width-16, y: 16)
            }
        }
        .frame(width: cellSize.width, height: cellSize.height)
    }
    // 4角圆点位置
    private func cornerPosition(_ idx: Int, in size: CGSize) -> CGPoint {
        switch idx {
        case 0: return CGPoint(x: 0, y: 0)
        case 1: return CGPoint(x: size.width, y: 0)
        case 2: return CGPoint(x: 0, y: size.height)
        case 3: return CGPoint(x: size.width, y: size.height)
        default: return .zero
        }
    }
}

// 分割线覆盖层
struct SplitLineOverlay: View {
    let size: CGSize
    let color: Color
    let lineWidth: CGFloat
    var body: some View {
        ZStack {
            // 上
            Rectangle()
                .fill(color)
                .frame(width: size.width, height: lineWidth)
                .position(x: size.width/2, y: lineWidth/2)
            // 下
            Rectangle()
                .fill(color)
                .frame(width: size.width, height: lineWidth)
                .position(x: size.width/2, y: size.height-lineWidth/2)
            // 左
            Rectangle()
                .fill(color)
                .frame(width: lineWidth, height: size.height)
                .position(x: lineWidth/2, y: size.height/2)
            // 右
            Rectangle()
                .fill(color)
                .frame(width: lineWidth, height: size.height)
                .position(x: size.width-lineWidth/2, y: size.height/2)
        }
    }
}

struct InspectorView: View {
    var body: some View { PlaceholderView(title: "属性编辑区", color: Theme.secondaryBackgroundColor) }
}

struct AssetPreviewView: View {
    var body: some View { PlaceholderView(title: "单素材预览区", color: Theme.secondaryBackgroundColor) }
}

struct TrimmingView: View {
    var body: some View { PlaceholderView(title: "裁剪区", color: Theme.secondaryBackgroundColor) }
}

// 视频宫格子视图，跟随全局主控同步
struct GlobalSyncVideoPlayer: NSViewRepresentable {
    let url: URL
    @Binding var currentTime: Double
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    let player = AVPlayer()
    var observer: Any?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer = playerLayer
        view.wantsLayer = true
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.isMuted = isMuted
        player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        if isPlaying { player.play() } else { player.pause() }
        // 监听全局同步通知
        NotificationCenter.default.addObserver(forName: .canvasGlobalSync, object: nil, queue: .main) { note in
            if let info = note.userInfo as? [String: Any] {
                let t = info["currentTime"] as? Double ?? 0
                let playing = info["isPlaying"] as? Bool ?? false
                let muted = info["isMuted"] as? Bool ?? false
                player.isMuted = muted
                player.seek(to: CMTime(seconds: t, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                if playing { player.play() } else { player.pause() }
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if let playerLayer = nsView.layer as? AVPlayerLayer {
            playerLayer.player = player
        }
    }
}

extension Notification.Name {
    static let canvasGlobalSync = Notification.Name("canvasGlobalSync")
}

// 工具栏竖向布局，所有参数通过Binding传入
struct CanvasToolBarView: View {
    @Binding var rowCount: Int
    @Binding var colCount: Int
    @Binding var cellAspect: CGFloat
    @Binding var rowSpacing: CGFloat
    @Binding var colSpacing: CGFloat
    @Binding var canvasAspectRatio: CGFloat
    @State private var showAspectMenu: Bool = false
    let aspectOptions: [(String, CGFloat)] = [
        ("9:16", 9.0/16.0),
        ("16:9", 16.0/9.0),
        ("1:1", 1.0),
        ("4:3", 4.0/3.0),
        ("3:4", 3.0/4.0),
        ("2:1", 2.0/1.0)
    ]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("画布工具栏")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.primaryTextColor)
                Spacer()
            }
            .padding(12)
            .background(Theme.headerBackgroundColor)
            Divider().opacity(0.7)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    CanvasAspectRatioPicker(canvasAspectRatio: $canvasAspectRatio, showAspectMenu: $showAspectMenu, aspectOptions: aspectOptions)
                    CanvasRowCountStepper(rowCount: $rowCount)
                    CanvasColCountStepper(colCount: $colCount)
                    CanvasCellAspectPicker(cellAspect: $cellAspect)
                    CanvasRowSpacingStepper(rowSpacing: $rowSpacing)
                    CanvasColSpacingStepper(colSpacing: $colSpacing)
                }
                .padding(16)
            }
            Spacer()
        }
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct CanvasAspectRatioPicker: View {
    @Binding var canvasAspectRatio: CGFloat
    @Binding var showAspectMenu: Bool
    let aspectOptions: [(String, CGFloat)]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("画布宽高比")
                .font(.subheadline)
                .foregroundColor(.white)
            Button(action: { showAspectMenu.toggle() }) {
                HStack(spacing: 4) {
                    Text(aspectOptions.first(where: { $0.1 == canvasAspectRatio })?.0 ?? "自定义")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showAspectMenu, arrowEdge: .trailing) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(aspectOptions, id: \.0) { opt in
                        Button(action: {
                            canvasAspectRatio = opt.1
                            showAspectMenu = false
                        }) {
                            HStack {
                                Text(opt.0)
                                    .fontWeight(canvasAspectRatio == opt.1 ? .bold : .regular)
                                    .foregroundColor(canvasAspectRatio == opt.1 ? Theme.accentColor : .primary)
                                Spacer()
                                if canvasAspectRatio == opt.1 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.accentColor)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 120)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
}

struct CanvasRowCountStepper: View {
    @Binding var rowCount: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("行数")
                .foregroundColor(.white)
            Stepper(value: $rowCount, in: 1...12) {
                Text("\(rowCount)")
                    .foregroundColor(.white)
                    .frame(width: 24)
            }
            .frame(width: 100)
        }
    }
}

struct CanvasColCountStepper: View {
    @Binding var colCount: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("列数")
                .foregroundColor(.white)
            Stepper(value: $colCount, in: 1...12) {
                Text("\(colCount)")
                    .foregroundColor(.white)
                    .frame(width: 24)
            }
            .frame(width: 100)
        }
    }
}

struct CanvasCellAspectPicker: View {
    @Binding var cellAspect: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("单元格比例")
                .foregroundColor(.white)
            Picker("", selection: $cellAspect) {
                Text("1:1").tag(1.0)
                Text("4:3").tag(4.0/3.0)
                Text("16:9").tag(16.0/9.0)
                Text("3:4").tag(3.0/4.0)
                Text("9:16").tag(9.0/16.0)
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 90)
        }
    }
}

struct CanvasRowSpacingStepper: View {
    @Binding var rowSpacing: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("行间距")
                .foregroundColor(.white)
            Stepper(value: $rowSpacing, in: 0...40, step: 1) {
                Text("\(Int(rowSpacing))")
                    .foregroundColor(.white)
                    .frame(width: 28)
            }
            .frame(width: 100)
        }
    }
}

struct CanvasColSpacingStepper: View {
    @Binding var colSpacing: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("列间距")
                .foregroundColor(.white)
            Stepper(value: $colSpacing, in: 0...40, step: 1) {
                Text("\(Int(colSpacing))")
                    .foregroundColor(.white)
                    .frame(width: 28)
            }
            .frame(width: 100)
        }
    }
}

// 拖拽排序 DropDelegate
struct CanvasDropDelegate: DropDelegate {
    let targetAssetId: UUID
    @ObservedObject var appState: AppState
    @Binding var draggedAssetId: UUID?

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedAssetId = self.draggedAssetId,
              draggedAssetId != targetAssetId,
              let fromIndex = appState.canvasAssets.firstIndex(of: draggedAssetId),
              let toIndex = appState.canvasAssets.firstIndex(of: targetAssetId)
        else {
            return false
        }
        appState.canvasAssets.swapAt(fromIndex, toIndex)
        self.draggedAssetId = nil
        return true
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// 新增：宫格渲染子视图，解决类型推断超时
struct CanvasGridView: View {
    let rows: Int
    let cols: Int
    let cellW: CGFloat
    let cellH: CGFloat
    let actualColSpacing: CGFloat
    let rowSpacing: CGFloat
    let selectedCells: Set<Int>
    let appState: AppState
    let currentTime: Double
    let isPlaying: Bool
    let isMuted: Bool
    let removeAsset: (UUID) -> Void
    let handleCellTap: (Int) -> Void
    @Binding var draggedAssetId: UUID?
    @State private var selectedRow: Int? = nil
    @State private var selectedCol: Int? = nil
    @State private var hoveredRowInsertIndex: Int? = nil
    @State private var hoveredColInsertIndex: Int? = nil

    var body: some View {
        HStack(spacing: 0) {
            // 左侧：行按钮+加号
            VStack(spacing: 0) {
                ForEach(0..<rows) { rowIdx in
                    Button(action: {
                        selectedRow = (selectedRow == rowIdx ? nil : rowIdx)
                        selectedCol = nil
                    }) {
                        Rectangle()
                            .fill(selectedRow == rowIdx ? Color.blue.opacity(0.3) : Color.gray.opacity(0.15))
                            .frame(width: 18, height: cellH)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(selectedRow == rowIdx ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    // 在每两个按钮之间插入加号
                    if rowIdx < rows - 1 {
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 18, height: rowSpacing)
                                .onHover { hovering in
                                    hoveredRowInsertIndex = hovering ? (rowIdx + 1) : (hoveredRowInsertIndex == rowIdx + 1 ? nil : hoveredRowInsertIndex)
                                }
                            if hoveredRowInsertIndex == rowIdx + 1 {
                                InsertRowButton(isHovered: true, onHover: {}, onExit: {}, onTap: {
                                    // TODO: 插入行逻辑
                                })
                                .frame(width: 18, height: rowSpacing)
                            }
                        }
                    }
                }
            }
            .padding(.top, 18)
            // 右侧：列按钮+加号+宫格内容
            VStack(spacing: 0) {
                // 顶部：列按钮+加号
                HStack(spacing: 0) {
                    ForEach(0..<cols) { colIdx in
                        VStack(spacing: 0) {
                            Button(action: {
                                selectedCol = (selectedCol == colIdx ? nil : colIdx)
                                selectedRow = nil
                            }) {
                                Rectangle()
                                    .fill(selectedCol == colIdx ? Color.blue.opacity(0.3) : Color.gray.opacity(0.15))
                                    .frame(width: cellW, height: 18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(selectedCol == colIdx ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            // 在每两个按钮之间插入加号
                            if colIdx < cols - 1 {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: actualColSpacing, height: 18)
                                        .onHover { hovering in
                                            hoveredColInsertIndex = hovering ? (colIdx + 1) : (hoveredColInsertIndex == colIdx + 1 ? nil : hoveredColInsertIndex)
                                        }
                                    if hoveredColInsertIndex == colIdx + 1 {
                                        InsertColButton(isHovered: true, onHover: {}, onExit: {}, onTap: {
                                            // TODO: 插入列逻辑
                                        })
                                        .frame(width: actualColSpacing, height: 18)
                                    }
                                }
                            }
                        }
                    }
                }
                // 宫格内容
                ForEach(0..<rows) { row in
                    HStack(spacing: actualColSpacing) {
                        ForEach(0..<cols) { col in
                            let idx = row * cols + col
                            let isSelected = selectedCells.contains(idx)
                            if idx < appState.canvasAssets.count {
                                let assetId = appState.canvasAssets[idx]
                                CanvasAssetCell(
                                    assetId: assetId,
                                    cellSize: CGSize(width: cellW, height: cellH),
                                    isSelected: isSelected,
                                    showSplitLine: true,
                                    removeAction: { removeAsset(assetId) }
                                )
                                .onTapGesture { handleCellTap(idx) }
                                .onDrag {
                                    draggedAssetId = assetId
                                    return NSItemProvider(object: assetId.uuidString as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: CanvasDropDelegate(
                                    targetAssetId: assetId,
                                    appState: appState,
                                    draggedAssetId: $draggedAssetId
                                ))
                            } else {
                                CanvasAssetCell(
                                    assetId: nil,
                                    cellSize: CGSize(width: cellW, height: cellH),
                                    isSelected: isSelected,
                                    showSplitLine: true,
                                    removeAction: nil
                                )
                                .onTapGesture { handleCellTap(idx) }
                            }
                        }
                    }
                }
            }
        }
    }
}

// 插入行加号按钮视图
struct InsertRowButton: View {
    var isHovered: Bool
    var onHover: () -> Void
    var onExit: () -> Void
    var onTap: () -> Void
    var body: some View {
        ZStack {
            Rectangle().fill(Color.clear).frame(width: 18, height: 12)
                .onHover { hovering in
                    if hovering { onHover() } else { onExit() }
                }
            if isHovered {
                VStack(spacing: 0) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .frame(width: 20, height: 20)
                        .onTapGesture { onTap() }
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 18, height: 3)
                        .cornerRadius(1.5)
                }
            }
        }
    }
}

// 插入列加号按钮视图
struct InsertColButton: View {
    var isHovered: Bool
    var onHover: () -> Void
    var onExit: () -> Void
    var onTap: () -> Void
    var body: some View {
        ZStack {
            Rectangle().fill(Color.clear).frame(width: 12, height: 18)
                .onHover { hovering in
                    if hovering { onHover() } else { onExit() }
                }
            if isHovered {
                HStack(spacing: 0) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .frame(width: 20, height: 20)
                        .onTapGesture { onTap() }
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 3, height: 18)
                        .cornerRadius(1.5)
                }
            }
        }
    }
} 