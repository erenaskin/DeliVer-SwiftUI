import SwiftUI

// MARK: - Service Model
struct Service: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let imageName: String
    let gradient: [Color]
}

// MARK: - HomeView
struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Demo services
    let services: [Service] = [
        Service(title: "DeliVerMarket", subtitle: "2.000+ ürün", imageName: "cart.fill", gradient: [.purple, .blue]),
        Service(title: "DeliVer", subtitle: "5.000+ ürün", imageName: "bag.fill", gradient: [.orange, .pink]),
        Service(title: "DeliVerWater", subtitle: "Sular", imageName: "drop.fill", gradient: [.blue, .teal]),
        Service(title: "DeliVerFood", subtitle: "Restoranlar", imageName: "fork.knife.circle.fill", gradient: [.yellow, .orange]),
        Service(title: "DeliVerPet", subtitle: "Evcil & Mahalli", imageName: "pawprint.fill", gradient: [.green, .blue]),
        Service(title: "DeliVerTaxi", subtitle: "Taksi çağır", imageName: "car.fill", gradient: [.yellow, .orange]),
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Address Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ev")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Esenyalı, 119. Sokak, No:5")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Promo Banner
                    ZStack {
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .cornerRadius(16)
                        VStack(spacing: 8) {
                            Text("Toplam 450 TL İndirim!")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("Her siparişte kazan")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding()
                    }
                    .frame(height: 120)
                    .padding(.horizontal)
                    
                    // MARK: - Services Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(services) { service in
                            ServiceCard(service: service)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("getir")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Service Card
struct ServiceCard: View {
    let service: Service
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                LinearGradient(colors: service.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(16)
                    .frame(height: 80)
                Image(systemName: service.imageName)
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
            Text(service.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if let subtitle = service.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .preferredColorScheme(.light)
            HomeView()
                .preferredColorScheme(.dark)
        }
    }
}
