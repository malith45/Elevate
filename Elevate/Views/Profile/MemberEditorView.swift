import SwiftUI
import PhotosUI

struct MemberEditorDraft {
    var displayName: String
    var role: String
    var email: String
    var phone: String
    var password: String?
    var profileImage: UIImage?
}

struct MemberEditorView: View {
    let member: User
    var onSave: (MemberEditorDraft) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    
    @State private var displayName: String
    @State private var role: String
    @State private var email: String
    @State private var phone: String
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Validation Errors
    @State private var emailError: String?
    @State private var phoneError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showingDeleteConfirm = false

    private let roleOptions = ["TECHNICIAN", "MANAGER"]
    
    private var currentUserRole: String {
        appSession.currentUser?.role.uppercased() ?? ""
    }
    
    private var targetRole: String {
        member.role.uppercased()
    }
    
    private var canEditPassword: Bool {
        if currentUserRole == "OWNER" { return true }
        if currentUserRole == "MANAGER" && targetRole == "TECHNICIAN" { return true }
        return false
    }

    init(member: User, onSave: @escaping (MemberEditorDraft) -> Void, onDelete: (() -> Void)? = nil) {
        self.member = member
        self.onSave = onSave
        self.onDelete = onDelete
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
                        .scaledFont(size: 15, weight: .semibold)
                        .foregroundColor(.elevateTextGray)

                    Spacer()

                    Text("Edit Profile")
                        .scaledFont(size: 17, weight: .bold, design: .rounded)

                    Spacer()

                    Button("Save") {
                        if validate() {
                            saveAndDismiss()
                        }
                    }
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(.elevateDarkGreen)
                    .opacity(member.role == "OWNER" && currentUserRole != "OWNER" ? 0.5 : 1.0)
                    .disabled(member.role == "OWNER" && currentUserRole != "OWNER")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Avatar Section
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    ProfilePhotoView(userId: member.id, size: 100)
                                }
                                
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.elevateDarkGreen)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                }
                                .offset(x: 2, y: 2)
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            selectedImage = uiImage
                                        }
                                    }
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text(displayName.isEmpty ? member.username : displayName)
                                    .scaledFont(size: 18, weight: .bold)
                                Text(member.username.uppercased())
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                    .tracking(1)
                            }
                        }
                        .padding(.top, 24)

                        // ROLE PICKER (Card Style)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCOUNT ROLE")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                                .padding(.leading, 4)

                            HStack(spacing: 12) {
                                ForEach(roleOptions, id: \.self) { option in
                                    roleCard(option)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .disabled(member.role == "OWNER")

                        // INFORMATION SECTION
                        VStack(alignment: .leading, spacing: 20) {
                            Text("PERSONAL INFORMATION")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                                .padding(.leading, 4)

                            VStack(spacing: 16) {
                                CustomTextField(title: "DISPLAY NAME", placeholder: "Full name", iconName: "person", text: $displayName)
                                
                                CustomTextField(title: "EMAIL ADDRESS", placeholder: "email@example.com", iconName: "envelope", text: $email, errorMessage: emailError)
                                    .keyboardType(.emailAddress)
                                
                                CustomTextField(title: "PHONE NUMBER", placeholder: "077 123 4567", iconName: "phone", text: $phone, errorMessage: phoneError)
                                    .keyboardType(.phonePad)
                            }
                        }
                        .padding(.horizontal, 20)

                        // PASSWORD SECTION (Conditional)
                        if canEditPassword {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("SECURITY")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                    .padding(.leading, 4)

                                VStack(spacing: 16) {
                                    SecureCustomTextField(title: "RESET PASSWORD", placeholder: "Enter new password", iconName: "lock", text: $password, errorMessage: passwordError)
                                    
                                    SecureCustomTextField(title: "CONFIRM PASSWORD", placeholder: "Re-enter password", iconName: "lock.fill", text: $confirmPassword, errorMessage: confirmPasswordError)
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if currentUserRole == "MANAGER" && targetRole == "MANAGER" {
                            // Informative note for Managers editing other Managers
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.orange)
                                Text("Password management is restricted for other Managers.")
                                    .scaledFont(size: 11, weight: .medium)
                                    .foregroundColor(.elevateTextGray)
                            }
                            .padding(.horizontal, 24)
                        }

                        // DELETE SECTION
                        if onDelete != nil && member.role != "OWNER" {
                            Button(action: {
                                showingDeleteConfirm = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Remove Member")
                                }
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .alert("Remove Member", isPresented: $showingDeleteConfirm) {
                                Button("Cancel", role: .cancel) { }
                                Button("Remove", role: .destructive) {
                                    onDelete?()
                                    dismiss()
                                }
                            } message: {
                                Text("Are you sure you want to remove \(displayName) from the organization? This cannot be undone.")
                            }
                        }

                        // Bottom Spacer
                        Spacer().frame(height: 100)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private func roleCard(_ option: String) -> some View {
        let isSelected = role.uppercased() == option.uppercased()
        return Button(action: { role = option }) {
            HStack(spacing: 8) {
                Image(systemName: option.uppercased() == "MANAGER" ? "person.badge.shield.fill" : "hammer.fill")
                    .font(.system(size: 14))
                Text(option.capitalized)
                    .scaledFont(size: 13, weight: .bold)
            }
            .foregroundColor(isSelected ? .white : .elevateDarkGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isSelected ? Color.elevateDarkGreen : Color.white)
            .cornerRadius(12)
            .shadow(color: isSelected ? Color.elevateDarkGreen.opacity(0.2) : Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.elevateLightGray.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func validate() -> Bool {
        var isValid = true
        emailError = nil
        phoneError = nil
        passwordError = nil
        confirmPasswordError = nil
        
        if !email.isEmpty && !isValidEmail(email) {
            emailError = "Invalid email format"
            isValid = false
        }
        
        if !phone.isEmpty && !isValidPhone(phone) {
            phoneError = "Invalid phone format"
            isValid = false
        }
        
        if !password.isEmpty {
            if password.count < 8 {
                passwordError = "Minimum 8 characters"
                isValid = false
            }
            if password != confirmPassword {
                confirmPasswordError = "Passwords do not match"
                isValid = false
            }
        }
        
        return isValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let regex = "^[\\d\\s\\+\\-\\(\\)]*$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }

    private func saveAndDismiss() {
        let draft = MemberEditorDraft(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password.isEmpty ? nil : password,
            profileImage: selectedImage
        )
        onSave(draft)
        dismiss()
    }
}
