import SwiftUI

struct SessionSummaryView: View {
    var durationStr: String
    var targetZone: Int
    
    // 🔥 VARIABLES DINÁMICAS RECIBIDAS DESDE EL MOTOR 🔥
    var avgBPM: Int
    var maxBPM: Int
    var syncScore: Int
    var distance: Double
    var calories: Int
    var zonePercentages: [Int] // Arreglo con los % de las 5 zonas
    
    var onGoHome: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.45), Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // 1. HEADER
                        VStack(spacing: 10) {
                            Image(systemName: "trophy.fill").font(.system(size: 40)).foregroundColor(.green).padding(.top, 20)
                            Text("Sesión completada").font(.system(size: 28, weight: .light)).foregroundColor(.white)
                            Text("Hoy · \(durationStr)").font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                        }
                        
                        // 2. SYNC SCORE
                        HStack(spacing: 20) {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.1), lineWidth: 15).frame(width: 100, height: 100)
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(syncScore) / 100.0)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeOut(duration: 1.5), value: syncScore)
                                
                                VStack(spacing: -2) {
                                    Text("\(syncScore)").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                                    Text("sync score").font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            // El texto ahora te dice exactamente tu % en la zona que elegiste
                            Text("Excelente sincronización FC-música. Pasaste el **\(syncScore)%** del tiempo dentro de tu zona objetivo **Z\(targetZone)**.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // 3. MÉTRICAS REALES
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Métricas del entrenamiento", systemImage: "heart").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.7)).padding(.horizontal, 5)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                SummaryCard(title: "Distancia total", value: String(format: "%.2f km", distance))
                                SummaryCard(title: "FC máxima", value: "\(maxBPM) bpm")
                                SummaryCard(title: "FC promedio", value: "\(avgBPM) bpm")
                                SummaryCard(title: "calorías est.", value: "\(calories) kcal")
                            }
                        }
                        .padding(20).background(Color.white.opacity(0.05)).cornerRadius(25).padding(.horizontal, 20)
                        
                        // 4. TIEMPO POR ZONA (Barra Dinámica)
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Tiempo por zona", systemImage: "target").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.7))
                            
                            GeometryReader { geo in
                                HStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.4, green: 0.5, blue: 0.7)).frame(width: max(0, (geo.size.width * CGFloat(zonePercentages[0]) / 100) - 4))
                                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.5, green: 0.7, blue: 0.4)).frame(width: max(0, (geo.size.width * CGFloat(zonePercentages[1]) / 100) - 4))
                                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.8, green: 0.7, blue: 0.2)).frame(width: max(0, (geo.size.width * CGFloat(zonePercentages[2]) / 100) - 4))
                                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.8, green: 0.5, blue: 0.3)).frame(width: max(0, (geo.size.width * CGFloat(zonePercentages[3]) / 100) - 4))
                                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.9, green: 0.3, blue: 0.3)).frame(width: max(0, (geo.size.width * CGFloat(zonePercentages[4]) / 100) - 4))
                                }
                            }
                            .frame(height: 8)
                            
                            HStack {
                                LegendItem(color: Color(red: 0.4, green: 0.5, blue: 0.7), text: "Z1 \(zonePercentages[0])%")
                                Spacer()
                                LegendItem(color: Color(red: 0.5, green: 0.7, blue: 0.4), text: "Z2 \(zonePercentages[1])%")
                                Spacer()
                                LegendItem(color: Color(red: 0.8, green: 0.7, blue: 0.2), text: "Z3 \(zonePercentages[2])%")
                                Spacer()
                                LegendItem(color: Color(red: 0.8, green: 0.5, blue: 0.3), text: "Z4 \(zonePercentages[3])%")
                                Spacer()
                                LegendItem(color: Color(red: 0.9, green: 0.3, blue: 0.3), text: "Z5 \(zonePercentages[4])%")
                            }
                        }
                        .padding(20).background(Color.white.opacity(0.05)).cornerRadius(25).padding(.horizontal, 20)
                        
                        Spacer().frame(height: 40)
                    }
                }
                
                // 5. BOTONES DE ACCIÓN
                HStack(spacing: 15) {
                    Button(action: {}) {
                        HStack { Image(systemName: "square.and.arrow.up"); Text("Compartir") }
                        .font(.system(size: 18, weight: .bold)).frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    Button(action: onGoHome) {
                        HStack { Image(systemName: "house.fill"); Text("Inicio") }
                        .font(.system(size: 18, weight: .bold)).frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color(red: 0.4, green: 0.3, blue: 1.0)).foregroundColor(.white).cornerRadius(15)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 30).padding(.top, 10).background(Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea())
            }
        }
    }
}

struct SummaryCard: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 24, weight: .medium)).foregroundColor(.white)
            Text(title).font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(15).background(Color.white.opacity(0.08)).cornerRadius(15)
    }
}

struct LegendItem: View {
    let color: Color; let text: String
    var body: some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 8, height: 8); Text(text).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.7)) }
    }
}
