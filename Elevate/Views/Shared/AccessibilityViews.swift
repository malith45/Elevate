import SwiftUI

struct TechnicianAccessibilityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        AccessibilityView(title: "Technician Accessibility") {
            dismiss()
        }
    }
}

struct ManagerAccessibilityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        AccessibilityView(title: "Manager Accessibility", isManager: true) {
            dismiss()
        }
    }
}

struct AccessibilityView: View {
    let title: String
    var isManager: Bool = false
    let onBack: () -> Void
    
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                BackHeaderNav(isManager: isManager, onBack: onBack)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .scaledFont(size: 32, weight: .bold, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Optimize Elevate for your specific visual and interaction needs.")
                                .scaledFont(size: 15, weight: .medium)
                                .foregroundColor(settings.secondaryText)
                                .lineLimit(2)
                        }
                        .padding(.top, 24)
                        
                        // VISUAL PREFERENCES CARD
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: "VISUAL", icon: "eye.fill")
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(
                                    title: "High Contrast Mode",
                                    desc: "Sharper colors and defined borders",
                                    icon: "circle.lefthalf.filled",
                                    isOn: $settings.isHighContrast
                                )
                                Divider().padding(.leading, 70)
                                
                                // Text Size Section inline
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(settings.isHighContrast ? Color.white.opacity(0.2) : Color.elevateDarkGreen.opacity(0.1))
                                                .frame(width: 38, height: 38)
                                            Image(systemName: "textformat.size")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(settings.isHighContrast ? .white : .elevateDarkGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Text Scaling")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(settings.primaryText)
                                            Text("Adjust system-wide font size")
                                                .font(.system(size: 11))
                                                .foregroundColor(settings.secondaryText)
                                        }
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Text("A").scaledFont(size: 12)
                                        Slider(value: $settings.textSize, in: 0...1)
                                            .tint(settings.accentColor)
                                        Text("A").scaledFont(size: 20, weight: .bold)
                                    }
                                    .foregroundColor(settings.primaryText)
                                    .padding(.top, 4)
                                }
                                .padding(16)
                            }
                            .background(settings.surfaceColor)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        }
                        
                        // INTERACTION PREFERENCES CARD
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: "INTERACTION", icon: "hand.tap.fill")
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(
                                    title: "VoiceOver",
                                    desc: "Voice feedback for all app actions",
                                    icon: "person.wave.2.fill",
                                    isOn: $settings.isVoiceOver
                                )
                                Divider().padding(.leading, 70)
                                AccessToggleRow(
                                    title: "Haptic Feedback",
                                    desc: "Physical vibrations for confirmations",
                                    icon: "sensor.tag.radiowaves.forward.fill",
                                    isOn: $settings.hapticFeedback
                                )
                                Divider().padding(.leading, 70)
                                AccessToggleRow(
                                    title: "Sound Effects",
                                    desc: "Audible alerts for notifications",
                                    icon: "speaker.wave.2.fill",
                                    isOn: $settings.soundEffects
                                )
                            }
                            .background(settings.surfaceColor)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        }
                        
                        // INFO BOX
                        HStack(spacing: 16) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(settings.accentColor)
                            Text("These settings are saved to your profile and will sync across your devices.")
                                .scaledFont(size: 12, weight: .medium)
                                .foregroundColor(settings.secondaryText)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(settings.accentColor.opacity(0.05))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100) // Extra padding for bottom tab bar clearance
                }
            }
        }
        .navigationBarHidden(true)
        .speakOnAppear("Accessibility Settings")
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .scaledFont(size: 11, weight: .black)
        }
        .foregroundColor(settings.secondaryText)
        .tracking(1.2)
        .padding(.horizontal, 4)
    }
}
