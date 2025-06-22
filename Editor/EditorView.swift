import SwiftUI

struct EditorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                // Top section (2/3 height)
                HStack(spacing: 10) {
                    MediaListView()
                        .frame(width: geometry.size.width * 0.3 - (20/3))
                    CanvasView()
                        .frame(width: geometry.size.width * 0.4 - (20/3))
                    InspectorView()
                        .frame(width: geometry.size.width * 0.3 - (20/3))
                }
                .frame(height: geometry.size.height * (2/3.0) - 15)

                // Bottom section (1/3 height)
                HStack(spacing: 10) {
                    AssetPreviewView()
                        .frame(width: (geometry.size.width - 30) * (2/3.0))
                     TrimmingView()
                        .frame(width: (geometry.size.width - 30) * (1/3.0))
                }
                .frame(height: geometry.size.height * (1/3.0) - 15)
            }
            .padding(10)
        }
        .background(Color(NSColor.underPageBackgroundColor).edgesIgnoringSafeArea(.all))
        .overlay(alignment: .topLeading) {
             Button(action: {
                appState.isEditing = false
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding(10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(5)
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView()
            .environmentObject(AppState())
    }
} 