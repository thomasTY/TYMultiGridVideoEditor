import SwiftUI
import AppKit

struct DraftSheetState: Identifiable, Equatable {
    let id: UUID
    var title: String
}

struct NSTextFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    var onCommit: (() -> Void)? = nil

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: text)
        textField.isBordered = true
        textField.isEditable = true
        textField.isBezeled = true
        textField.drawsBackground = true
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.commit)
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NSTextFieldWrapper
        init(_ parent: NSTextFieldWrapper) { self.parent = parent }
        func controlTextDidChange(_ obj: Notification) {
            if let tf = obj.object as? NSTextField {
                parent.text = tf.stringValue
            }
        }
        @objc func commit() {
            parent.onCommit?()
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isRenaming = false
    @State private var renamingDraftId: UUID? = nil
    @State private var newTitle: String = ""

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // "开始创作" button
                Button(action: {
                    let draft = appState.createDraft()
                    appState.isEditing = true
                    // TODO: 进入新建草稿的二级编辑界面（后续实现）
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
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowedFileTypes = ["json"]
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.title = "导入草稿"
                    if panel.runModal() == .OK, let url = panel.url {
                        if let draft = appState.importDraftFromJSON(url: url) {
                            appState.isEditing = true
                            // TODO: 进入导入草稿的二级编辑界面（后续实现）
                        }
                    }
                }) {
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
                        ForEach(appState.drafts) { draft in
                            DraftItemView(
                                draft: draft,
                                onRename: {
                                    renamingDraftId = draft.id
                                    newTitle = draft.title
                                    isRenaming = true
                                },
                                onDuplicate: { appState.duplicateDraft(id: draft.id) },
                                onDelete: { appState.deleteDraft(id: draft.id) }
                            )
                            .onTapGesture {
                                appState.currentEditingDraftId = draft.id
                                appState.isEditing = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 25)
            }
            // 纯 SwiftUI 自定义弹窗
            if isRenaming {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .onTapGesture { isRenaming = false }
                VStack(spacing: 20) {
                    Text("重命名草稿").font(.headline)
                    TextField("新名称", text: $newTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 240)
                        .padding(.top, 8)
                    HStack {
                        Button("取消") { isRenaming = false }
                        Button("确定") {
                            if let id = renamingDraftId {
                                isRenaming = false
                                DispatchQueue.main.async {
                                    appState.renameDraft(id: id, newTitle: newTitle)
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(width: 300)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 10)
                .zIndex(1)
            }
        }
        .onAppear {
            print("[Log] WelcomeView appeared.")
        }
    }
}

struct RenamePanelView: View {
    @Binding var newTitle: String
    var onCancel: () -> Void
    var onConfirm: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("重命名草稿").font(.headline)
            TextField("新名称", text: $newTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 240)
            HStack {
                Button("取消") { onCancel() }
                Button("确定") { onConfirm() }
            }
        }
        .padding()
        .frame(width: 300)
    }
} 