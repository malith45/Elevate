import SwiftUI
import UIKit

struct ManagerAccessibilityView: View {
    @Environment(\.managerTabRouter) private var router
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .profile
                    router.selectedTab = .profile
                })
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
                        
                        // AUDIO / NARRATION
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AUDIO NARRATION")
                                .scaledFont(size: 10)
                                .fontWeight(.bold)
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(title: "In-App Voice Over", desc: "Speak interactions and labels aloud", icon: "speaker.wave.3", isOn: $settings.isVoiceOver)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // VISION SUPPORT
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VISION SUPPORT")
                                .scaledFont(size: 10)
                                .fontWeight(.bold)
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(title: "High Contrast Mode", desc: "Enhance visibility of UI elements", icon: "circle.lefthalf.fill", isOn: $settings.isHighContrast)
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
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            
        }
        .navigationBarHidden(true)
        .speakOnAppear("Manager Accessibility Settings")
    }
}

#Preview {
    ManagerAccessibilityView()
}
