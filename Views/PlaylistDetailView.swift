import SwiftUI
import AVFoundation

struct PlaylistDetailView: View {
    var zoneName: String
    var title: String
    var color: Color
    var tracks: [CloudTrack] // Recibe las canciones filtradas de la zona
    
    // Motor de audio independiente para la vista previa del álbum
    @State private var localPlayer: AVAudioPlayer?
    @State private var playingTrackID: String? = nil
    @State private var isLocalPlaying = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Cabecera del Álbum
                VStack(spacing: 15) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(LinearGradient(colors: [color.opacity(0.5), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: isLocalPlaying ? "waveform" : "music.note")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.8))
                                .animation(.smooth, value: isLocalPlaying)
                        )
                        .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(zoneName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                        .tracking(1)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Lista de Canciones Funcional
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tracks) { track in
                            Button(action: {
                                reproducirPistaLocal(track: track)
                            }) {
                                HStack(spacing: 15) {
                                    // Indicador de BPM base de la canción
                                    Text("\(track.baseBPM)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(color)
                                        .frame(width: 35)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(playingTrackID == track.id ? color : .white)
                                        Text(track.artist)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    // Estado dinámico: Cargando, Reproduciendo o Pausado
                                    if isLoading && playingTrackID == track.id {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: (playingTrackID == track.id && isLocalPlaying) ? "pause.fill" : "play.fill")
                                            .foregroundColor(playingTrackID == track.id ? color : .white.opacity(0.5))
                                            .font(.system(size: 16))
                                    }
                                }
                                .padding()
                                .background(playingTrackID == track.id ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(color)
        .onDisappear {
            // Apaga el reproductor si el usuario sale del álbum para evitar fugas de memoria
            localPlayer?.stop()
            isLocalPlaying = false
        }
    }
    
    // Gestión del flujo de audio
    func reproducirPistaLocal(track: CloudTrack) {
        if playingTrackID == track.id {
            if isLocalPlaying {
                localPlayer?.pause()
                isLocalPlaying = false
            } else {
                localPlayer?.play()
                isLocalPlaying = true
            }
            return
        }
        
        localPlayer?.stop()
        playingTrackID = track.id
        isLoading = true
        isLocalPlaying = false
        
        guard let url = URL(string: track.audioURL) else { return }
        
        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                let audioData = try Data(contentsOf: tempURL)
                let newPlayer = try AVAudioPlayer(data: audioData)
                newPlayer.prepareToPlay()
                
                await MainActor.run {
                    self.localPlayer = newPlayer
                    self.localPlayer?.play()
                    self.isLoading = false
                    self.isLocalPlaying = true
                }
            } catch {
                print("Error de audio local: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}
