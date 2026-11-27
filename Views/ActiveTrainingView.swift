import SwiftUI

struct ActiveTrainingView: View {
    @Binding var smoothedBPM: Double
    @Binding var isPlaying: Bool
    @Binding var selectedTargetZone: Int
    
    var avgBPM: Int
    var formattedTime: String
    var targetBPM: Int
    
    var baseBPM: Int
    var trackTitle: String
    var trackArtist: String
    
    var currentPlaybackSpeed: Double
    var engineMessage: String
    var suggestedTitle: String?
    
    var onTogglePlay: () -> Void
    var onEndWorkout: () -> Void
    var onAcceptSuggestion: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.45), Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Entrenamiento Activo")
                    .font(.system(size: 20, weight: .light)).foregroundColor(.white).padding(.top, 10)
                
                // 🔥 ANILLO DE BPM REDISEÑADO 🔥
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 25).frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(smoothedBPM / 200.0, 1.0)))
                        .stroke(zoneColor(for: selectedTargetZone), style: StrokeStyle(lineWidth: 25, lineCap: .round))
                        .frame(width: 160, height: 160).rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: smoothedBPM)
                    
                    VStack(spacing: 0) {
                        Text("\(Int(smoothedBPM))")
                            .font(.system(size: 48, weight: .bold)).foregroundColor(.white).contentTransition(.numericText())
                        Text("bpm FC").font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                        
                        Text("Objetivo: \(targetBPM)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(zoneColor(for: selectedTargetZone))
                            .padding(.top, 10)
                        
                        if smoothedBPM > 0 {
                            let diff = Int(smoothedBPM) - targetBPM
                            Text(abs(diff) <= 5 ? "¡EN ZONA!" : (diff < 0 ? "¡ACELERA!" : "¡FRENA!"))
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(abs(diff) <= 5 ? .green : .orange)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.vertical, 10)
                
                // Botones de Zonas
                HStack(spacing: 8) {
                    ZoneButton(title: "Z1\nrec.", color: Color(red: 0.4, green: 0.5, blue: 0.7), isSelected: selectedTargetZone == 1) { selectedTargetZone = 1 }
                    ZoneButton(title: "Z2\nbase", color: Color(red: 0.5, green: 0.7, blue: 0.4), isSelected: selectedTargetZone == 2) { selectedTargetZone = 2 }
                    ZoneButton(title: "Z3\naerób.", color: Color(red: 0.8, green: 0.7, blue: 0.2), isSelected: selectedTargetZone == 3) { selectedTargetZone = 3 }
                    ZoneButton(title: "Z4\numbral", color: Color(red: 0.8, green: 0.5, blue: 0.3), isSelected: selectedTargetZone == 4) { selectedTargetZone = 4 }
                    ZoneButton(title: "Z5\nmáx.", color: Color(red: 0.9, green: 0.3, blue: 0.3), isSelected: selectedTargetZone == 5) { selectedTargetZone = 5 }
                }
                .padding(.horizontal, 20)
                
                // Controles Principales
                HStack(spacing: 15) {
                    Button(action: onTogglePlay) {
                        HStack {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            Text(isPlaying ? "Pausa" : "Reanudar")
                        }
                        .font(.system(size: 20, weight: .bold)).frame(maxWidth: .infinity, minHeight: 70)
                        .background(Color(red: 0.2, green: 0.1, blue: 0.4)).foregroundColor(.white).cornerRadius(15)
                    }
                    Button(action: onEndWorkout) {
                        HStack { Text("Terminar"); Image(systemName: "flag.checkered") }
                        .font(.system(size: 20, weight: .bold)).frame(maxWidth: .infinity, minHeight: 70)
                        .background(Color(red: 0.7, green: 0.3, blue: 0.3)).foregroundColor(.white).cornerRadius(15)
                    }
                }
                .padding(.horizontal, 20)
                
                // Grid de Estadísticas
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    MetricCard(title: "Tiempo de sesión", value: formattedTime, icon: "timer")
                    MetricCard(title: "FC promedio", value: "\(avgBPM)", icon: "heart")
                    MetricCard(title: "RUM Status", value: engineMessage, icon: "cpu")
                    MetricCard(title: "Pitch Audio", value: String(format: "%.2fx", currentPlaybackSpeed), icon: "waveform")
                }
                .padding(.horizontal, 20)
                
                // Banner de Sugerencia Inteligente
                if let suggestion = suggestedTitle {
                    Button(action: onAcceptSuggestion) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                            VStack(alignment: .leading) {
                                Text("Música muy desfasada").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                Text("Saltar a: \(suggestion)").font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "forward.end.fill").foregroundColor(.white)
                        }
                        .padding(12).background(Color.yellow.opacity(0.2)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.5), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Reproductor Mini
                HStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)).frame(width: 40, height: 40)
                        .overlay(Image(systemName: "music.note").foregroundColor(.white.opacity(0.6)))
                    VStack(alignment: .leading) {
                        Text(trackTitle).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                        Text(trackArtist).font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                    }
                    Spacer()
                    Text("\(baseBPM) bpm").font(.system(size: 12, weight: .bold))
                        .padding(6).background(Color.white.opacity(0.1)).cornerRadius(6).foregroundColor(.white)
                }
                .padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    func zoneColor(for zone: Int) -> Color {
        switch zone {
        case 1: return Color(red: 0.4, green: 0.5, blue: 0.7); case 2: return Color(red: 0.5, green: 0.7, blue: 0.4); case 3: return Color(red: 0.8, green: 0.7, blue: 0.2); case 4: return Color(red: 0.8, green: 0.5, blue: 0.3); case 5: return Color(red: 0.9, green: 0.3, blue: 0.3); default: return .gray
        }
    }
}

struct ZoneButton: View {
    var title: String; var color: Color; var isSelected: Bool; var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .bold)).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 50).background(isSelected ? color : color.opacity(0.3))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7)).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .clear : color.opacity(0.5), lineWidth: 1))
        }
    }
}

struct MetricCard: View {
    var title: String; var value: String; var icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 20, weight: .medium)).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.5)
            HStack(spacing: 4) { Image(systemName: icon); Text(title) }
                .font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color.white.opacity(0.08)).cornerRadius(12)
    }
}
