import SwiftUI

struct QuotationStatusView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TechnicianDashboardView.TabItem = .jobs
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text("Quotation Status")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        
                        // APPROVED ITEMS
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("APPROVED ITEMS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Text("2 ITEMS")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(12)
                            }
                            
                            QuotationItemCard(icon: "slider.vertical.3", title: "Industrial Capacitor\n45uF", price: "LKR 4500.00", statusText: "APPROVED", isApproved: true)
                            QuotationItemCard(icon: "bolt.fill", title: "Heavy Duty Relay\nSwitch", price: "LKR 3200.00", statusText: "APPROVED", isApproved: true)
                        }
                        
                        // PENDING APPROVAL
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("PENDING APPROVAL")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Spacer()
                                Text("1 ITEM")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                            }
                            
                            QuotationItemCard(icon: "snowflake", title: "R-410A Coolant (2\nlbs)", price: "LKR 1000.00", statusText: "PENDING", isApproved: false)
                        }
                        
                        // Bottom Metrics + Action
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TOTAL VALUE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("LKR\n8,700")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ITEMS ORDERED")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.elevateTextGray)
                                    Text("03")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.elevateDarkGreen)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            }
                            
                            HStack(spacing: 16) {
                                Button(action: {}) {
                                    Text("CONFIRM")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.elevateDarkGreen)
                                        .cornerRadius(8)
                                }
                                
                                NavigationLink(destination: InventoryView()) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                        Text("ADD ITEMS")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.elevateDarkGreen)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 16)
                        
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
}

struct QuotationItemCard: View {
    var icon: String
    var title: String
    var price: String
    var statusText: String
    var isApproved: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.elevateDarkGreen)
                .frame(width: 48, height: 48)
                .background(Color.elevateLightGray)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                Text(price)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.elevateDarkGreen)
            }
            Spacer()
            
            Text(statusText)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isApproved ? Color.green.opacity(0.2) : Color.red.opacity(0.1))
                .foregroundColor(isApproved ? Color.elevateDarkGreen : .red)
                .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    QuotationStatusView()
}
