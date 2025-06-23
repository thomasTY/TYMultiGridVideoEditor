import SwiftUI

struct EditorView: View {
    @ObservedObject private var appState = AppState.shared
    var currentDraftId: UUID?

    var body: some View {
        GeometryReader { geometry in
            let hSpacing: CGFloat = 10
            let vSpacing: CGFloat = 10
            
            let totalWidth = geometry.size.width - (2 * hSpacing)
            let totalHeight = geometry.size.height - (2 * vSpacing)
            
            let topHeight = totalHeight * (2/3.0) - (vSpacing / 2)
            let bottomHeight = totalHeight * (1/3.0) - (vSpacing / 2)

            VStack(spacing: vSpacing) {
                // Top section: 3/10, 4/10, 3/10
                let topContentWidth = totalWidth - (2 * hSpacing)
                HStack(spacing: hSpacing) {
                    MediaListView().frame(width: topContentWidth * 0.3)
                    CanvasView().frame(width: topContentWidth * 0.4)
                    InspectorView().frame(width: topContentWidth * 0.3)
                }
                .frame(height: topHeight)

                // Bottom section: 7/10, 3/10
                let bottomContentWidth = totalWidth - hSpacing
                HStack(spacing: hSpacing) {
                    AssetPreviewView().frame(width: bottomContentWidth * 0.7)
                    TrimmingView().frame(width: bottomContentWidth * 0.3)
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