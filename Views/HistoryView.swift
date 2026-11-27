import SwiftUI

// 1. Modelo de datos Codable para permitir persistencia real
struct WorkoutSession: Identifiable, Codable {
    var id = UUID()
    let title: String
    let date: String
    let duration: String
    let distance: Double
    let zone: Int
}

struct HistoryView: View {
    @State private var savedSessions: [WorkoutSession] = []
    @State private var selectedFilter = "Todo"
    let filters = ["Todo", "Z3", "Z4", "Z5"]
    
    // 2. CÁLCULO TOTAL DE KILÓMETROS DINÁMICOS
    var totalKilometers: Double {
        savedSessions.reduce(0) { $0 + $1.distance }
    }
    
    // Filtro dinámico en base a la zona seleccionada
    var filteredSessions: [WorkoutSession] {
        if selectedFilter == "Todo" {
            return savedSessions
        } else {
            let zoneNumber = Int(selectedFilter.replacingOccurrences(of: "Z", with: "")) ?? 3
            return savedSessions.filter { $0.zone == zoneNumber }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.45), Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("HISTORIAL")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "bell")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
                // Filtros de Zona
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(selectedFilter == filter ? Color(red: 0.4, green: 0.3, blue: 1.0) : Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                }
                
                // Lista de Sesiones Reales
                ScrollView {
                    VStack(spacing: 15) {
                        if filteredSessions.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "figure.run")
                                    .font(.largeTitle)
                                    .foregroundColor(.white.opacity(0.3))
                                Text("No hay entrenamientos registrados")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(filteredSessions) { session in
                                HistoryCard(session: session)
                            }
                        }
                        
                        // 3. TARJETA DE RESUMEN MENSUAL TOTALIZADA REAL
                        VStack(alignment: .leading, spacing: 15) {
                            Text("RESUMEN ACUMULADO").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5)).tracking(1)
                            
                            HStack(alignment: .bottom) {
                                Text(String(format: "%.1f", totalKilometers))
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                Text("km").font(.system(size: 20)).foregroundColor(.white.opacity(0.7)).padding(.bottom, 8)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(savedSessions.count) Sesiones").font(.system(size: 12)).foregroundColor(.white)
                                    Text("Motor RUM Activo").font(.system(size: 11, weight: .bold)).foregroundColor(.green)
                                }
                            }
                        }
                        .padding(25)
                        .background(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .cornerRadius(25)
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 25)
                }
            }
        }
        // 🔥 Carga los datos reales del almacenamiento cada vez que abres la pantalla 🔥
        .onAppear {
            savedSessions = HistoryStore.loadSessions()
        }
    }
}

struct HistoryCard: View {
    let session: WorkoutSession
    
    // Asigna el color dinámicamente según la zona metabólica
    var zoneColor: Color {
        switch session.zone {
        case 1: return Color(red: 0.4, green: 0.5, blue: 0.7)
        case 2: return Color(red: 0.5, green: 0.7, blue: 0.4)
        case 3: return Color(red: 0.8, green: 0.7, blue: 0.2)
        case 4: return Color(red: 0.8, green: 0.5, blue: 0.3)
        default: return Color(red: 0.9, green: 0.3, blue: 0.3)
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 3).frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: 1.0)
                    .stroke(zoneColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                Text("Z\(session.zone)").font(.system(size: 12, weight: .bold)).foregroundColor(zoneColor)
            }
            
            // 🔥 AQUÍ ESTABA EL ERROR: Cambiado 'customAlignment' por 'alignment' 🔥
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.4))
                Text(session.title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                
                HStack(spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("TIEMPO").font(.system(size: 8)).foregroundColor(.white.opacity(0.4))
                        Text(session.duration).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading) {
                        Text("DISTANCIA").font(.system(size: 8)).foregroundColor(.white.opacity(0.4))
                        Text(String(format: "%.2f km", session.distance)).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(20)
    }
}

// 🔥 MOTOR DE PERSISTENCIA EN LOCAL STORAGE (UserDefaults) 🔥
class HistoryStore {
    static func loadSessions() -> [WorkoutSession] {
        guard let data = UserDefaults.standard.data(forKey: "rum_persisted_sessions"),
              let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) else {
            return []
        }
        return decoded
    }
    
    static func saveSession(_ session: WorkoutSession) {
        var current = loadSessions()
        current.insert(session, at: 0) // Agrega el más reciente al inicio de la lista
        if let encoded = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(encoded, forKey: "rum_persisted_sessions")
        }
    }
}
