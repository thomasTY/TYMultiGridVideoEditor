import SwiftUI

struct EditorView: View {
    @ObservedObject private var appState = AppState.shared
    var currentDraftId: UUID?
    // 画布参数
    @State private var rowCount: Int = 5
    @State private var colCount: Int = 3
    @State private var cellAspect: CGFloat = 1.0
    @State private var rowSpacing: CGFloat = 0
    @State private var colSpacing: CGFloat = 0
    @State private var canvasAspectRatio: CGFloat = 9.0/16.0
    let canvasPadding: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let hSpacing: CGFloat = 10
            let vSpacing: CGFloat = 10
            let totalWidth = geometry.size.width - (4 * hSpacing)
            let totalHeight = geometry.size.height - (2 * vSpacing)
            let topHeight = totalHeight * (2/3.0) - (vSpacing / 2)
            let bottomHeight = totalHeight * (1/3.0) - (vSpacing / 2)
            let leftWidth = totalWidth * 0.3 - 150 // 素材区
            let canvasWidth = totalWidth * 0.4 // 画布区
            let attrWidth = totalWidth * 0.3 // 属性区
            let toolBarWidth: CGFloat = 150 // 工具栏
            let previewWidth = totalWidth * 0.7 // 单素材预览
            let trimWidth = totalWidth * 0.3 // 裁剪区

            VStack(spacing: vSpacing) {
                // 上半部分：主编辑区
                HStack(spacing: hSpacing) {
                    MediaListView()
                        .frame(width: leftWidth)
                    CanvasView(
                        rowCount: $rowCount,
                        colCount: $colCount,
                        cellAspect: $cellAspect,
                        rowSpacing: $rowSpacing,
                        colSpacing: $colSpacing,
                        canvasAspectRatio: $canvasAspectRatio,
                        canvasPadding: canvasPadding
                    )
                    .frame(width: canvasWidth)
                    CanvasToolBarView(
                        rowCount: $rowCount,
                        colCount: $colCount,
                        cellAspect: $cellAspect,
                        rowSpacing: $rowSpacing,
                        colSpacing: $colSpacing,
                        canvasAspectRatio: $canvasAspectRatio
                    )
                    .frame(width: toolBarWidth)
                    InspectorView()
                        .frame(width: attrWidth)
                }
                .frame(height: topHeight)
                // 下半部分：单素材预览+裁剪
                HStack(spacing: hSpacing) {
                    AssetPreviewView()
                        .frame(width: previewWidth)
                    TrimmingView()
                        .frame(width: trimWidth)
                }
                .frame(height: bottomHeight)
            }
            .padding(hSpacing)
        }
        .background(Theme.primaryBackgroundColor.ignoresSafeArea())
        .onAppear {
            print("[Log] EditorView appeared.")
        }
    }
} 