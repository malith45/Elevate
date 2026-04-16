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

    private let roleOptions = ["TECHNICIAN", "MANAGER"]

    init(member: User, onSave: @escaping (MemberEditorDraft) -> Void) {
        self.member = member
        self.onSave = onSave
        _displayName = State(initialValue: member.displayName.isEmpty ? member.username : member.displayName)
        _role = State(initialValue: member.role.isEmpty ? "TECHNICIAN" : member.role.uppercased())
        _email = State(initialValue: member.email ?? "")
        _phone = State(initialValue: member.phone ?? "")
    }

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundColor(.elevateTextGray)
                        .accessibilityLabel("Cancel editing member")

                    Spacer()

                    Text("Edit Member")
                        .scaledFont(size: 16, weight: .bold)

                    Spacer()

                    Button("Save") { saveAndDismiss() }
                        .scaledFont(size: 15, weight: .bold)
                        .foregroundColor(.elevateDarkGreen)
                        .accessibilityLabel("Save member changes")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(Divider(), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Avatar + name preview
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.elevateDarkGreen.opacity(0.12))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            Text(displayName.isEmpty ? member.username : displayName)
                                .scaledFont(size: 18, weight: .bold)
                                .foregroundColor(.black)
                                .accessibilityLabel("Member name preview: \(displayName.isEmpty ? member.username : displayName)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                        // PROFILE SECTION
                        sectionCard(title: "PROFILE", icon: "person.text.rectangle") {
                            VStack(spacing: 14) {
                                editorField(
                                    label: "FULL NAME",
                                    placeholder: "Display name",
                                    icon: "person",
                                    text: $displayName,
                                    keyboard: .default
                                )

                                Divider()

                                // Role Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ROLE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)

                                    HStack(spacing: 10) {
                                        ForEach(roleOptions, id: \.self) { option in
                                            roleChip(option)
                                        }
                                    }
                                }
                            }
                        }

                        // CONTACT SECTION
                        sectionCard(title: "CONTACT", icon: "phone.badge.checkmark") {
                            VStack(spacing: 14) {
                                editorField(
                                    label: "EMAIL",
                                    placeholder: "member@company.com",
                                    icon: "envelope",
                                    text: $email,
                                    keyboard: .emailAddress
                                )

                                Divider()

                                editorField(
                                    label: "PHONE",
                                    placeholder: "+1 (555) 000-0000",
                                    icon: "phone",
                                    text: $phone,
                                    keyboard: .phonePad
                                )
                            }
                        }

                        // Member ID (read-only)
                        HStack {
                            Image(systemName: "tag.circle")
                                .foregroundColor(.elevateTextGray)
                                .font(.system(size: 14))
                            Text("Member ID: \(String(member.id.prefix(8)).uppercased())")
                                .scaledFont(size: 12)
                                .foregroundColor(.elevateTextGray)
                        }
                        .padding(.bottom, 40)
                        .accessibilityLabel("Member ID \(String(member.id.prefix(8)))")

                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    // MARK: - Sub-views

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateDarkGreen)
                Text(title)
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(.elevateTextGray)
            }
            content()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }

    private func editorField(label: String, placeholder: String, icon: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateTextGray)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.elevateTextGray)
                    .frame(width: 18)
                TextField(placeholder, text: text)
                    .scaledFont(size: 15)
                    .keyboardType(keyboard)
                    .autocapitalization(.none)
                    .accessibilityLabel(label)
            }
        }
    }

    private func roleChip(_ option: String) -> some View {
        let isSelected = role == option
        return Button(action: { role = option }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .bold))
                Text(option.capitalized)
                    .scaledFont(size: 13, weight: .semibold)
            }
            .foregroundColor(isSelected ? .white : .elevateDarkGreen)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.elevateDarkGreen : Color.elevateDarkGreen.opacity(0.08))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Role: \(option.capitalized)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func saveAndDismiss() {
        let draft = MemberEditorDraft(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(draft)
        dismiss()
    }
}
