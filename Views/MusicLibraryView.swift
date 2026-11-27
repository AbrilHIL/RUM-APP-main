import SwiftUI

struct MusicLibraryView: View {
    var loadedTracks: [CloudTrack] // Recibe la telemetría del archivo principal
    
    // 🔥 RESPALDO LOCAL FIJO PARA EVITAR EFECTOS DE CACHÉ CORRUPTO 🔥
    let cancionesDeRespaldo: [CloudTrack] = [
        CloudTrack(id: "z1_001", title: "Ambient Chill & Flow", artist: "RUM Open Source", baseBPM: 100, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
        CloudTrack(id: "z1_002", title: "Breeze Recovery", artist: "RUM Open Source", baseBPM: 102, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"),
        CloudTrack(id: "z2_001", title: "Steady State Beats", artist: "DJ Base", baseBPM: 124, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"),
        CloudTrack(id: "z2_002", title: "Endurance Groove", artist: "DJ Base", baseBPM: 126, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"),
        CloudTrack(id: "z3_001", title: "High Intensity Drive", artist: "RUM Synth", baseBPM: 140, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3"),
        CloudTrack(id: "z3_002", title: "Tempo Push", artist: "RUM Synth", baseBPM: 142, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3"),
        CloudTrack(id: "z4_001", title: "Power Surge Anthems", artist: "DJ Volt", baseBPM: 160, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3"), // 🔥 ERROR CORREGIDO AQUÍ 🔥
        CloudTrack(id: "z4_002", title: "Threshold Breaker", artist: "DJ Volt", baseBPM: 162, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3"),
        CloudTrack(id: "z5_001", title: "Max Effort Peak", artist: "RUM Hardcore", baseBPM: 171, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3"),
        CloudTrack(id: "z5_002", title: "Sprint Finish", artist: "RUM Hardcore", baseBPM: 173, audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3")
    ]
    
    // Función inteligente de distribución semántica
    func tracks(for zone: Int) -> [CloudTrack] {
        // Si la nube viene vacía o incompleta por problemas del servidor, tomamos el respaldo local
        let fuenteDeDatos = loadedTracks.count >= 10 ? loadedTracks : cancionesDeRespaldo
        
        switch zone {
        case 1: return fuenteDeDatos.filter { $0.baseBPM < 112 }
        case 2: return fuenteDeDatos.filter { $0.baseBPM >= 112 && $0.baseBPM < 132 }
        case 3: return fuenteDeDatos.filter { $0.baseBPM >= 132 && $0.baseBPM < 150 }
        case 4: return fuenteDeDatos.filter { $0.baseBPM >= 150 && $0.baseBPM < 165 }
        default: return fuenteDeDatos.filter { $0.baseBPM >= 165 } // Zona 5
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mi Biblioteca RUM")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Sincroniza tu ritmo cardíaco con tus beats favoritos de código abierto.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Bloques de Playlists por Zona Conectados
                        VStack(spacing: 20) {
                            NavigationLink(destination: PlaylistDetailView(zoneName: "ZONA 1: RECUPERACIÓN", title: "Ambient Chill & Flow", color: .blue, tracks: tracks(for: 1))) {
                                ZonePlaylistCard(zoneName: "ZONA 1: RECUPERACIÓN", title: "Ambient Chill & Flow", tracks: "\(tracks(for: 1).count) Canciones", color: .blue)
                            }
                            
                            NavigationLink(destination: PlaylistDetailView(zoneName: "ZONA 2: AERÓBICA", title: "Steady State Beats", color: .green, tracks: tracks(for: 2))) {
                                ZonePlaylistCard(zoneName: "ZONA 2: AERÓBICA", title: "Steady State Beats", tracks: "\(tracks(for: 2).count) Canciones", color: .green)
                            }
                            
                            NavigationLink(destination: PlaylistDetailView(zoneName: "ZONA 3: UMBRAL", title: "High Intensity Drive", color: .orange, tracks: tracks(for: 3))) {
                                ZonePlaylistCard(zoneName: "ZONA 3: UMBRAL", title: "High Intensity Drive", tracks: "\(tracks(for: 3).count) Canciones", color: .orange)
                            }
                            
                            NavigationLink(destination: PlaylistDetailView(zoneName: "ZONA 4: ESFUERZO MÁXIMO", title: "Power Surge Anthems", color: .red, tracks: tracks(for: 4))) {
                                ZonePlaylistCard(zoneName: "ZONA 4: ESFUERZO MÁXIMO", title: "Power Surge Anthems", tracks: "\(tracks(for: 4).count) Canciones", color: .red)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 130)
                    }
                }
            }
        }
    }
}

// Tarjeta de la Playlist (Estructura gráfica unificada)
struct ZonePlaylistCard: View {
    var zoneName: String; var title: String; var tracks: String; var color: Color
    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(color).frame(width: 4)
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(zoneName).font(.system(size: 10, weight: .bold)).foregroundColor(color).tracking(1)
                    Spacer()
                    Image(systemName: "chart.bar.fill").foregroundColor(color).font(.system(size: 12))
                }
                Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                HStack(spacing: 15) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [color.opacity(0.4), Color.black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .overlay(Image(systemName: "waveform").foregroundColor(.white.opacity(0.8)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tracks).font(.system(size: 12)).foregroundColor(.white)
                        HStack(spacing: 4) { Image(systemName: "music.note"); Text("RUM Open Source") }.font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                    }
                }
                Text("Ver Playlist")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.white.opacity(0.1)).cornerRadius(10)
            }.padding(15).background(Color(red: 0.14, green: 0.14, blue: 0.16))
        }.cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}
