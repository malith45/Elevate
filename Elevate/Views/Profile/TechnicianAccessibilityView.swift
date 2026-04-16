import SwiftUI
import UIKit

struct TechnicianAccessibilityView: View {
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var showSettingsPrompt = false
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                BackHeaderNav()
                    .background(Color.white)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Accessibility")
                                .scaledFont(size: 32)
                                .fontWeight(.black)
                                .fontDesign(.rounded)
                            Text("Customize your experience to fit your specific needs and preferences.")
                                .scaledFont(size: 14)
                                .foregroundColor(.elevateTextGray)
                                .lineSpacing(4)
                        }
                        .padding(.top, 16)
                        
                        // VISION SUPPORT
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VISION SUPPORT")
                                .scaledFont(size: 10)
                                .fontWeight(.bold)
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(title: "High Contrast Mode", desc: "Enhance visibility of UI elements", icon: "circle.lefthalf.fill", isOn: $settings.isHighContrast)
                                Divider().padding(.leading, 64)
                                AccessToggleRow(title: "VoiceOver Compatibility", desc: "Optimized layout for screen readers", icon: "person.wave.2.fill", isOn: Binding(
                                    get: { settings.isVoiceOver },
                                    set: { newValue in
                                        settings.isVoiceOver = newValue
                                        if newValue {
                                            showSettingsPrompt = true
                                        }
                                        let message = newValue
                                            ? "VoiceOver compatibility enabled. App layout is now optimised for screen readers."
                                            : "VoiceOver compatibility disabled."
                                        UIAccessibility.post(notification: .announcement, argument: message)
                                        HapticManager.shared.playSelection()
                                    }
                                ))
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // TYPOGRAPHY
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TYPOGRAPHY")
                                .scaledFont(size: 10)
                                .fontWeight(.bold)
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 24) {
                                HStack {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.elevateDarkGreen)
                                        .frame(width: 40, height: 40)
                                        .background(Color.elevateLightGray)
                                        .cornerRadius(8)
                                    Text("Text Size Adjustment")
                                        .scaledFont(size: 14)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("DEFAULT")
                                        .scaledFont(size: 10)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.elevateLightGray.opacity(0.8))
                                        .foregroundColor(.elevateDarkGreen)
                                        .cornerRadius(12)
                                }
                                
                                HStack {
                                    Text("A").scaledFont(size: 12).fontWeight(.bold).foregroundColor(.gray)
                                    Slider(value: $settings.textSize, in: 0...1)
                                        .accentColor(.elevateDarkGreen)
                                    Text("A").scaledFont(size: 20).fontWeight(.bold).foregroundColor(.gray)
                                }
                                
                                Text("\"The Precise Monolith aesthetic combines Swiss editorial design with modern glassmorphism.\"")
                                    .scaledFont(size: 14)
                                    .lineSpacing(6)
                                    .italic()
                                    .padding(20)
                                    .background(Color.elevateLightGray.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // INTERACTION
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INTERACTION")
                                .scaledFont(size: 10)
                                .fontWeight(.bold)
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(title: "Haptic Feedback", desc: "Vibration for interface interactions", icon: "hand.tap", isOn: $settings.hapticFeedback)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            
        }
        .navigationBarHidden(true)
        .alert("Enable iOS VoiceOver", isPresented: $showSettingsPrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("VoiceOver is a system-wide feature. Would you like to open your device Settings to turn it on? (Go to Settings > Accessibility > VoiceOver)")
        }
    }
}

struct AccessToggleRow: View {
    var title: String
    var desc: String
    var icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.elevateDarkGreen)
                .frame(width: 40, height: 40)
                .background(Color.elevateLightGray.opacity(0.5))
                .cornerRadius(8)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .scaledFont(size: 14)
                    .fontWeight(.bold)
                Text(desc)
                    .scaledFont(size: 12)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    HapticManager.shared.playSelection()
                }
            ))
            .tint(.elevateDarkGreen)
            .labelsHidden()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(desc)
    }
}

#Preview {
    TechnicianAccessibilityView()
}
