import SwiftUI

struct HomeView: View {
    @Binding var smoothedBPM: Double
    @Binding var isPlaying: Bool
    @Binding var currentPlaybackSpeed: Double
    @Binding var isWatchConnected: Bool
    var watchName: String
    var baseBPM: Int
    var trackTitle: String
    var trackArtist: String
    var onPlayAction: () -> Void
    @State private var showConnectionAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.15, blue: 0.35), Color(red: 0.1, green: 0.1, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    HStack(spacing: 0) {
                        Text("Good morning ").font(.system(size: 30, weight: .light))
                        Text("Jacobo!").font(.system(size: 30, weight: .bold))
                    }.foregroundColor(.white)
                    Spacer()
                }.padding(.horizontal, 30).padding(.top, 20)
                
                VStack(spacing: 15) {
                    Button(action: {
                        if isWatchConnected && smoothedBPM > 0 { onPlayAction() }
                        else { showConnectionAlert = true }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50).fill(Color.white.opacity(0.15)).frame(height: 130)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 65)).foregroundColor(.white.opacity((isWatchConnected && smoothedBPM > 0) ? 0.7 : 0.3))
                        }
                    }.padding(.horizontal, 50)
                    .alert("Sincronización Incompleta", isPresented: $showConnectionAlert) { Button("Entendido", role: .cancel) { } } message: {
                        if !isWatchConnected { Text("Por favor, enlaza tu Apple Watch.") }
                        else { Text("El sensor óptico aún está calibrando tu ritmo cardíaco.") }
                    }
                    Text("Are you ready for the training?").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
                }.padding(.bottom, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Última sesión — ayer, 42 min", systemImage: "clock.arrow.circlepath").font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                            HStack(spacing: 15) {
                                SummaryBox(icon: "heart", color: .red, value: "148", unit: "bpm", label: "FC promedio")
                                SummaryBox(icon: "music.note", color: .cyan, value: "152", unit: "bpm", label: "BPM musical")
                            }
                            VStack(spacing: 8) {
                                GeometryReader { geo in
                                    HStack(spacing: 3) {
                                        RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.4)).frame(width: geo.size.width * 0.15)
                                        RoundedRectangle(cornerRadius: 2).fill(Color.green.opacity(0.6)).frame(width: geo.size.width * 0.15)
                                        RoundedRectangle(cornerRadius: 2).fill(Color.yellow).frame(width: geo.size.width * 0.35)
                                        RoundedRectangle(cornerRadius: 2).fill(Color.orange.opacity(0.6)).frame(width: geo.size.width * 0.20)
                                        RoundedRectangle(cornerRadius: 2).fill(Color.red.opacity(0.6)).frame(width: geo.size.width * 0.15)
                                    }
                                }.frame(height: 6)
                                HStack {
                                    Text("Zona 3 - aeróbica").font(.system(size: 12)).foregroundColor(.yellow)
                                    Spacer()
                                    Text("68% del tiempo").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }.padding(20).background(BlurView(style: .systemUltraThinMaterialDark)).cornerRadius(25)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Playlist activa", systemImage: "music.note.list").font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                            HStack(spacing: 15) {
                                ZStack { Circle().fill(Color.white.opacity(0.1)).frame(width: 50, height: 50); Image(systemName: "waveform").foregroundColor(.white.opacity(0.8)) }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trackTitle).font(.system(size: 16, weight: .bold)).foregroundColor(.white).lineLimit(1)
                                    Text("\(trackArtist) • Base: \(baseBPM) bpm").font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                                }
                                Spacer(); Text("API").font(.system(size: 12, weight: .bold)).padding(8).background(Color.white.opacity(0.1)).cornerRadius(8)
                            }
                        }.padding(20).background(BlurView(style: .systemUltraThinMaterialDark)).cornerRadius(25)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Wearable", systemImage: "applewatch").font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                            HStack {
                                Circle().fill(isWatchConnected ? Color.green : Color.red).frame(width: 10, height: 10)
                                Text(watchName).font(.system(size: 16, weight: .bold)).foregroundColor(isWatchConnected ? .white : .white.opacity(0.6))
                                Spacer(); Image(systemName: isWatchConnected ? "battery.75" : "battery.0").foregroundColor(isWatchConnected ? .yellow : .red.opacity(0.5))
                            }
                        }.padding(20).background(BlurView(style: .systemUltraThinMaterialDark)).cornerRadius(25)
                        Spacer().frame(height: 120)
                    }.padding(.horizontal, 25)
                }
            }
        }
    }
}

struct SummaryBox: View {
    let icon: String; let color: Color; let value: String; let unit: String; let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                Text(unit).font(.system(size: 12)).foregroundColor(.white.opacity(0.6)).padding(.bottom, 4)
            }
            Text(label).font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).background(Color.white.opacity(0.05)).cornerRadius(15)
    }
}

// 🔥 TAB BAR ACTUALIZADO CON ESPAÑOL 🔥
struct FloatingTabBar: View {
    @Binding var selectedTab: RUMTab
    var body: some View {
        HStack(spacing: 0) {
            TabItem(icon: "house", label: "HOME", isActive: selectedTab == .home)
                .onTapGesture { withAnimation { selectedTab = .home } }
            Spacer()
            TabItem(icon: "music.note.list", label: "MÚSICA", isActive: selectedTab == .musica)
                .onTapGesture { withAnimation { selectedTab = .musica } }
            Spacer()
            TabItem(icon: "clock.arrow.circlepath", label: "HISTORIAL", isActive: selectedTab == .history)
                .onTapGesture { withAnimation { selectedTab = .history } }
            Spacer()
            TabItem(icon: "gearshape", label: "AJUSTES", isActive: selectedTab == .settings)
                .onTapGesture { withAnimation { selectedTab = .settings } }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12)).clipShape(Capsule())
        .padding(.horizontal, 20).padding(.bottom, 25)
    }
}

struct TabItem: View {
    let icon: String; let label: String; var isActive: Bool
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 20))
            Text(label).font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(isActive ? .black : .white.opacity(0.5))
        .padding(.vertical, 10).padding(.horizontal, isActive ? 15 : 10)
        .background(isActive ? Color(red: 0.7, green: 0.5, blue: 1.0) : Color.clear).clipShape(Capsule())
        .contentShape(Rectangle())
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
