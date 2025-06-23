import SwiftUI

struct WelcomeView: View {
    @ObservedObject private var appState = AppState.shared
    
    @State private var drafts: [Draft] = [
        Draft(title: "6月10日"),
        Draft(title: "6月9日(1)"),
        Draft(title: "6月8日"),
        Draft(title: "6月7日(3)"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // "开始创作" button
            Button(action: {
                print("[Log] '开始创作' button clicked.")
                appState.isEditing = true
            }) {
                Text("开始创作")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .background(Theme.creationGradient)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 25)

            // "导入草稿" button
            Button(action: { print("导入草稿") }) {
                Text("导入草稿")
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.secondaryBackgroundColor)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 25)

            Text("历史草稿")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 30)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 25) {
                    ForEach(drafts) { draft in
                        Button(action: {
                            print("[Log] Draft '\(draft.title)' clicked.")
                            appState.isEditing = true
                        }) {
                            DraftItemView(draft: draft)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 25)
        }
        .onAppear {
            print("[Log] WelcomeView appeared.")
        }
    }
} 