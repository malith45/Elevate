import SwiftUI

struct MemberEditorDraft {
    var displayName: String
    var role: String
    var email: String
    var phone: String
}

struct MemberEditorView: View {
    let member: User
    var onSave: (MemberEditorDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var role: String
    @State private var email: String
    @State private var phone: String

    init(member: User, onSave: @escaping (MemberEditorDraft) -> Void) {
        self.member = member
        self.onSave = onSave
        _displayName = State(initialValue: member.displayName)
        _role = State(initialValue: member.role.isEmpty ? "TECHNICIAN" : member.role)
        _email = State(initialValue: member.email ?? "")
        _phone = State(initialValue: member.phone ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("PROFILE")) {
                    TextField("Display name", text: $displayName)
                    TextField("Role", text: $role)
                }
                Section(header: Text("CONTACT")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let draft = MemberEditorDraft(
                            displayName: displayName,
                            role: role,
                            email: email,
                            phone: phone
                        )
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}
