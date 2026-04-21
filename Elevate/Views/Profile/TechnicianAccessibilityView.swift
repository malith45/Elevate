import SwiftUI
import UIKit

struct TechnicianAccessibilityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            (settings.isHighContrast ? Color.black : Color.elevateLightGray.opacity(0.3)).ignoresSafeArea()
            
            VStack(spacing: 0) {
                BackHeaderNav(onBack: {
                    dismiss()
                })
                .background(settings.isHighContrast ? Color.black : Color.white)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Accessibility")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(settings.isHighContrast ? .white : .black)
                            
                            Text("Customize your experience to fit your specific needs and preferences.")
                                .font(.system(size: 15))
                                .foregroundColor(settings.isHighContrast ? .white : .elevateTextGray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 24) {
                            // AUDIO / NARRATION
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("AUDIO NARRATION")
                                AccessibleCard {
                                    AccessToggleRow(
                                        title: "In-App Voice Over",
                                        desc: "Speak interactions and labels aloud",
                                        icon: "speaker.wave.3",
                                        isOn: $settings.isVoiceOver
                                    )
                                    .padding(-20)
                                }
                            }
                            
                            // VISION SUPPORT
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("VISION SUPPORT")
                                AccessibleCard {
                                    AccessToggleRow(
                                        title: "High Contrast Mode",
                                        desc: "Enhance visibility of UI elements",
                                        icon: "circle.lefthalf.fill",
                                        isOn: $settings.isHighContrast
                                    )
                                    .padding(-20)
                                }
                            }
                            
                            // TYPOGRAPHY
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("TYPOGRAPHY")
                                
                                AccessibleCard {
                                    VStack(spacing: 24) {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(settings.isHighContrast ? Color.white.opacity(0.2) : Color.elevateDarkGreen.opacity(0.1))
                                                    .frame(width: 38, height: 38)
                                                Image(systemName: "textformat")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(settings.isHighContrast ? .white : .elevateDarkGreen)
                                            }
                                            
                                            Text("Text Size Adjustment")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(settings.isHighContrast ? .white : .black)
                                            
                                            Spacer()
                                            
                                            Text("DEFAULT")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(settings.isHighContrast ? Color.white.opacity(0.2) : Color.elevateDarkGreen.opacity(0.1))
                                                .foregroundColor(settings.isHighContrast ? .white : .elevateDarkGreen)
                                                .cornerRadius(8)
                                        }
                                        
                                        HStack(spacing: 16) {
                                            Text("A").font(.system(size: 12, weight: .bold)).foregroundColor(settings.isHighContrast ? .white : .gray)
                                            Slider(value: $settings.textSize, in: 0...1)
                                                .tint(settings.isHighContrast ? .white : .elevateDarkGreen)
                                            Text("A").font(.system(size: 20, weight: .bold)).foregroundColor(settings.isHighContrast ? .white : .gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("PREVIEW")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(settings.isHighContrast ? .white : .gray)
                                                .tracking(1)
                                            
                                            Text("\"The Precise Monolith aesthetic combines Swiss editorial design with modern glassmorphism.\"")
                                                .font(.system(size: settings.getScaledFontSize(14), weight: .medium, design: .serif))
                                                .italic()
                                                .lineSpacing(6)
                                                .foregroundColor(settings.isHighContrast ? .white : .elevateDarkGreen)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(20)
                                                .background(settings.isHighContrast ? Color.white.opacity(0.1) : Color.elevateDarkGreen.opacity(0.05))
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                            
                            // INTERACTION
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("INTERACTION")
                                AccessibleCard {
                                    AccessToggleRow(
                                        title: "Haptic Feedback",
                                        desc: "Vibration for interface interactions",
                                        icon: "hand.tap",
                                        isOn: $settings.hapticFeedback
                                    )
                                    .padding(-20)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationBarHidden(true)
        .speakOnAppear("Accessibility Settings")
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.elevateTextGray)
            .tracking(1.2)
            .padding(.horizontal, 4)
    }
}

#Preview {
    TechnicianAccessibilityView()
}
