import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    // Placeholder data for recent drafts
    @State private var drafts: [Draft] = [
        Draft(title: "6月10日"),
        Draft(title: "6月9日(1)"),
        Draft(title: "6月8日"),
        Draft(title: "6月7日(3)"),
        Draft(title: "6月6日"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // "开始创作" button
            Button(action: {
                appState.isEditing = true
                print("开始创作")
            }) {
                Text("开始创作")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 88)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 25)

            // "导入草稿" button
            Button(action: {
                // Action for importing draft
                print("导入草稿")
            }) {
                Text("导入草稿")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.primary)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 25)

            // Drafts list
            Text("历史草稿")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 40)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    ForEach(drafts) { draft in
                        Button(action: {
                            appState.isEditing = true
                            print("打开草稿: \(draft.title)")
                        }) {
                            DraftItemView(draft: draft)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .padding(.bottom, 25)
        }
        .background(Color(NSColor.windowBackgroundColor).edgesIgnoringSafeArea(.all))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
} 