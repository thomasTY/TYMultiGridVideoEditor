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

    var body: some View {
        VStack(spacing: 0) {
            if appState.canvasAssets.isEmpty {
                PlaceholderView(title: isTargeted ? "拖拽到此处！" : "画布区", color: Theme.playerBackgroundColor)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                        ForEach(appState.canvasAssets, id: \.self) { assetId in
                            CanvasAssetCell(
                                assetId: assetId,
                                currentTime: currentTime,
                                isPlaying: isPlaying,
                                isMuted: isMuted,
                                removeAction: { removeAsset(assetId) }
                            )
                        }
                    }
                    .padding(10)
                }
                // 全局控制条
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
            }
        }
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
}

struct CanvasAssetCell: View {
    let assetId: UUID
    let currentTime: Double
    let isPlaying: Bool
    let isMuted: Bool
    let removeAction: () -> Void
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        let asset = appState.mediaAssets.first { $0.id == assetId }
        ZStack(alignment: .topTrailing) {
            if let asset = asset {
                if asset.url == nil {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(Text("无效素材").foregroundColor(.gray).font(.caption))
                        .aspectRatio(4/3, contentMode: .fit)
                        .cornerRadius(6)
                } else if asset.type == .image {
                    if currentTime <= 5, let img = asset.thumbnail {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(4/3, contentMode: .fit)
                            .cornerRadius(6)
                    } else if currentTime <= 5 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(4/3, contentMode: .fit)
                            .cornerRadius(6)
                    }
                } else if asset.type == .video, let url = asset.url {
                    GlobalSyncVideoPlayer(
                        url: url,
                        currentTime: .constant(currentTime),
                        isPlaying: .constant(isPlaying),
                        isMuted: .constant(isMuted)
                    )
                    .aspectRatio(4/3, contentMode: .fit)
                    .cornerRadius(6)
                }
            }
            Button(action: removeAction) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Theme.accentColor)
            }
            .buttonStyle(.plain)
            .padding(5)
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