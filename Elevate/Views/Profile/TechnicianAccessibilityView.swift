import SwiftUI

struct TechnicianAccessibilityView: View {
    @State private var isHighContrast = true
    @State private var isVoiceOver = false
    @State private var textSize: Double = 0.5
    @State private var hapticFeedback = true
    
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
                                .font(.system(size: 32, weight: .black, design: .rounded))
                            Text("Customize your experience to fit your specific needs and preferences.")
                                .font(.system(size: 14))
                                .foregroundColor(.elevateTextGray)
                                .lineSpacing(4)
                        }
                        .padding(.top, 16)
                        
                        // VISION SUPPORT
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VISION SUPPORT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(title: "High Contrast Mode", desc: "Enhance visibility of UI elements", icon: "circle.lefthalf.fill", isOn: $isHighContrast)
                                Divider().padding(.leading, 64)
                                AccessToggleRow(title: "VoiceOver Compatibility", desc: "Optimized layout for screen readers", icon: "person.wave.2.fill", isOn: $isVoiceOver)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // TYPOGRAPHY
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TYPOGRAPHY")
                                .font(.system(size: 10, weight: .bold))
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
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Text("DEFAULT")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.elevateLightGray.opacity(0.8))
                                        .foregroundColor(.elevateDarkGreen)
                                        .cornerRadius(12)
                                }
                                
                                HStack {
                                    Text("A").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                                    Slider(value: $textSize, in: 0...1)
                                        .accentColor(.elevateDarkGreen)
                                    Text("A").font(.system(size: 20, weight: .bold)).foregroundColor(.gray)
                                }
                                
                                Text("\"The Precise Monolith aesthetic combines Swiss editorial design with modern glassmorphism.\"")
                                    .font(.system(size: 14))
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
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
                            VStack(spacing: 0) {
                                AccessToggleRow(title: "Haptic Feedback", desc: "Vibration for interface interactions", icon: "hand.tap", isOn: $hapticFeedback)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.profile))
        }
        .navigationBarHidden(true)
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.elevateDarkGreen)
                .labelsHidden()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    TechnicianAccessibilityView()
}
