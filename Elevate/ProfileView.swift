import SwiftUI

struct ProfileView: View {
    @State private var faceIDEnabled = true
    
    // Extracted Colors based on Theme and Screenshot
    let primaryText = Color(red: 248/255, green: 250/255, blue: 252/255) // #F8FAFC
    let secBgColor = Color(red: 30/255, green: 41/255, blue: 59/255) // #1E293B
    let secTextColor = Color(red: 203/255, green: 213/255, blue: 245/255) // #CBD5F5
    let dangerColor = Color(red: 220/255, green: 38/255, blue: 38/255) // #DC2626
    let borderColor = Color.white.opacity(0.1) // Subtle borders for cards and dividers

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Profile")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(primaryText)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Profile Info Header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(secBgColor)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text("JD")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(primaryText)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("John Doe")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(primaryText)
                            Text("Lead Technician")
                                .font(.subheadline)
                                .foregroundColor(secTextColor)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        StatCard(icon: "checkmark.circle", iconColor: Color(red: 16/255, green: 185/255, blue: 129/255), value: "142", title: "Jobs", secBgColor: secBgColor, primaryText: primaryText, secTextColor: secTextColor, borderColor: borderColor)
                        StatCard(icon: "star", iconColor: Color(red: 245/255, green: 158/255, blue: 11/255), value: "4.9", title: "Rating", secBgColor: secBgColor, primaryText: primaryText, secTextColor: secTextColor, borderColor: borderColor)
                        StatCard(icon: "clock", iconColor: Color(red: 59/255, green: 130/255, blue: 246/255), value: "1240", title: "Hours", secBgColor: secBgColor, primaryText: primaryText, secTextColor: secTextColor, borderColor: borderColor)
                    }
                    .padding(.horizontal, 24)
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(secTextColor)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            ProfileButtonRow(icon: "person", title: "Personal Information", primaryText: primaryText)
                            Divider().background(borderColor).padding(.leading, 50)
                            ProfileButtonRow(icon: "gearshape", title: "Preferences", primaryText: primaryText)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 16).fill(secBgColor).opacity(0.4))
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // App Settings Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("App Settings")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(secTextColor)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            ProfileButtonRow(icon: "bell", title: "Notifications", primaryText: primaryText)
                            
                            Divider().background(borderColor).padding(.leading, 50)
                            
                            // Face ID Login Toggle Row
                            HStack(spacing: 16) {
                                Image(systemName: "shield")
                                    .font(.system(size: 20))
                                    .frame(width: 24)
                                    .foregroundColor(primaryText)
                                
                                Text("Face ID Login")
                                    .font(.subheadline)
                                    .foregroundColor(primaryText)
                                
                                Spacer()
                                
                                Toggle("", isOn: $faceIDEnabled)
                                    .labelsHidden()
                                    .tint(Color(red: 16/255, green: 185/255, blue: 129/255))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            
                            Divider().background(borderColor).padding(.leading, 50)
                            
                            ProfileButtonRow(icon: "cylinder.split.1x2", title: "Offline Data", subtitle: "Last synced 10m ago", primaryText: primaryText, secTextColor: secTextColor)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 16).fill(secBgColor).opacity(0.4))
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // Sign Out Button
                    Button(action: {
                        // Sign out logic
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Sign Out")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(dangerColor))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                }
                .padding(.bottom, 120) // Provide breathing room above bottom nav
            }
        }
    }
}

// Reusable Helper Views for Profile
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let title: String
    let secBgColor: Color
    let primaryText: Color
    let secTextColor: Color
    let borderColor: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(secTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 16).fill(secBgColor).opacity(0.4))
        )
    }
}

struct ProfileButtonRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let primaryText: Color
    var secTextColor: Color? = nil

    var body: some View {
        Button(action: {
            // Row action binding placeholder
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 24)
                    .foregroundColor(primaryText)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(primaryText)
                    if let subtitle = subtitle, let secText = secTextColor {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(secText)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText.opacity(0.5)) // Faded chevron arrow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    ZStack {
        Color(red: 15/255, green: 23/255, blue: 42/255).ignoresSafeArea()
        ProfileView()
    }
}
