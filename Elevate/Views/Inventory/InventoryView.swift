import SwiftUI

struct InventoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""
    @State private var selectedTab: TechnicianDashboardView.TabItem = .jobs
    
    // Using simple state dictionaries for increment counters for layout demonstration.
    @State private var electricalQuantities: [String: Int] = ["Relay": 1, "Contactor": 0, "Limit": 2]
    @State private var mechanicalQuantities: [String: Int] = ["Valve": 0]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.elevateTextGray)
                    TextField("Search", text: $searchText)
                        .font(.system(size: 16))
                }
                .padding()
                .background(Color.elevateLightGray.opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // ELECTRICAL COMPONENTS
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("ELECTRICAL COMPONENTS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Text("15 ITEMS AVAILABLE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                            }
                            
                            InventoryItemCard(
                                icon: "bolt.fill",
                                title: "Relay Switch 24V",
                                desc: "OMRON Industrial",
                                price: "LKR 4,250",
                                quantity: binding(for: "Relay", in: $electricalQuantities)
                            )
                            InventoryItemCard(
                                icon: "bolt.batteryblock.fill",
                                title: "Contactor 3-Pole",
                                desc: "Schneider LC1D",
                                price: "LKR 18,400",
                                quantity: binding(for: "Contactor", in: $electricalQuantities)
                            )
                            InventoryItemCard(
                                icon: "slider.vertical.3",
                                title: "Limit Switch",
                                desc: "Roller Lever Type",
                                price: "LKR 3,150",
                                quantity: binding(for: "Limit", in: $electricalQuantities)
                            )
                        }
                        
                        // MECHANICAL PARTS
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("MECHANICAL PARTS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Text("12 ITEMS AVAILABLE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                            }
                            
                            InventoryItemCard(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Hydraulic Valve",
                                desc: "High Pressure 1/2\"",
                                price: "LKR 6,800",
                                quantity: binding(for: "Valve", in: $mechanicalQuantities)
                            )
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.jobs))
        }
        .navigationBarHidden(true)
    }
    
    private func binding(for key: String, in dict: Binding<[String: Int]>) -> Binding<Int> {
        Binding<Int>(
            get: { dict.wrappedValue[key] ?? 0 },
            set: { dict.wrappedValue[key] = $0 }
        )
    }
}

struct InventoryItemCard: View {
    var icon: String
    var title: String
    var desc: String
    var price: String
    @Binding var quantity: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .frame(width: 60, height: 60)
                .background(Color.elevateLightGray.opacity(0.5))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.elevateDarkGreen)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Stepper
            HStack(spacing: 0) {
                Button(action: {
                    if quantity > 0 { quantity -= 1 }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                }
                
                Text("\(quantity)")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 24)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    quantity += 1
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.elevateDarkGreen)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.elevateLightGray, lineWidth: 1))
            .cornerRadius(6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    InventoryView()
}
