import SwiftUI

struct ZoneSelectionView: View {
    @Binding var selectedZone: Int
    var onStartWorkout: () -> Void
    var onDismiss: () -> Void
    
    let zones = [
        WorkoutZone(id: 1, name: "Z1", label: "Recuperación", desc: "Trote muy suave o caminata", color: Color(red: 0.4, green: 0.5, blue: 0.7), icon: "figure.walk"),
        WorkoutZone(id: 2, name: "Z2", label: "Base Aeróbica", desc: "Ritmo cómodo, charla fácil", color: Color(red: 0.5, green: 0.7, blue: 0.4), icon: "figure.run"),
        WorkoutZone(id: 3, name: "Z3", label: "Aeróbico Alto", desc: "Quema de grasa y resistencia", color: Color(red: 0.8, green: 0.7, blue: 0.2), icon: "flame.fill"),
        WorkoutZone(id: 4, name: "Z4", label: "Umbral", desc: "Esfuerzo intenso, paso rápido", color: Color(red: 0.8, green: 0.5, blue: 0.3), icon: "bolt.fill"),
        WorkoutZone(id: 5, name: "Z5", label: "Máxima", desc: "Esprint y potencia anaeróbica", color: Color(red: 0.9, green: 0.3, blue: 0.3), icon: "exclamationmark.triangle.fill")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title).foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("¿En qué zona")
                        .font(.system(size: 32, weight: .light)).foregroundColor(.white)
                    Text("entrenarás hoy?")
                        .font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(zones) { zone in
                            ZoneCard(zone: zone, isSelected: selectedZone == zone.id)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedZone = zone.id
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Botón de Inicio
                Button(action: onStartWorkout) {
                    Text("PREPARAR RUM")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 65)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
            }
        }
    }
}

// Estructura de Datos para las zonas
struct WorkoutZone: Identifiable {
    let id: Int
    let name: String
    let label: String
    let desc: String
    let color: Color
    let icon: String
}

// Tarjeta de diseño para cada zona
struct ZoneCard: View {
    let zone: WorkoutZone
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(zone.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: zone.icon)
                    .foregroundColor(zone.color)
                    .font(.system(size: 20, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.label)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(zone.desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(zone.name)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(zone.color)
        }
        .padding()
        .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(isSelected ? zone.color : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}
