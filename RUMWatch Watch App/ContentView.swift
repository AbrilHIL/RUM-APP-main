import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var heartRateManager = HeartRateManager()
    @ObservedObject var connectivity = ConnectivityManager.shared // Usa el manager global
    @State private var isTraining = false
    @State private var currentSlide = 0

    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.25), .black]), center: .center, startRadius: 5, endRadius: 120).ignoresSafeArea()

            if !isTraining {
                TabView(selection: $currentSlide) {
                    OnboardingView(step: "1/3", titleText: "PULSO\nREAL", subText: "RUM lee tus latidos desde tu muñeca.", iconName: "waveform.path.ecg", iconColor: .cyan).tag(0)
                    OnboardingView(step: "2/3", titleText: "SALUD\nACTIVA", subText: "Acepta los permisos de Apple HealthKit.", iconName: "heart.text.square.fill", iconColor: .red).tag(1)
                    OnboardingView(
                        step: "3/3", titleText: "¡A LA\nRUMBA!", subText: "Enlaza con tu iPhone y arranca el motor.",
                        iconView: AnyView(
                            Button(action: {
                                withAnimation(.spring()) {
                                    isTraining = true
                                    heartRateManager.requestAuthorization()
                                }
                            }) {
                                ZStack {
                                    // 🔥 Reducido de 75 a 50 para liberar espacio vertical 🔥
                                    Circle()
                                        .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                            }.buttonStyle(PlainButtonStyle())
                        )
                    ).tag(2)
                }
                .tabViewStyle(PageTabViewStyle())
            } else {
                ActiveTrainingWatchView(heartRateManager: heartRateManager, connectivity: connectivity, isTraining: $isTraining)
            }
        }
    }
}

struct ActiveTrainingWatchView: View {
    @ObservedObject var heartRateManager: HeartRateManager
    @ObservedObject var connectivity: ConnectivityManager
    @Binding var isTraining: Bool
    
    @State private var pulse = 1.0
    @State private var isPlaying = true

    var body: some View {
        VStack(spacing: 2) {
            // 1. ZONA OBJETIVO (Recibida del iPhone)
            Text(connectivity.currentZoneName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
                .padding(.top, 5)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            // 2. FRECUENCIA CARDÍACA
            HStack(alignment: .top, spacing: 2) {
                Text("\(Int(heartRateManager.currentHeartRate))")
                    .font(.system(size: 55, weight: .black, design: .rounded)).foregroundColor(.white).minimumScaleFactor(0.5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "heart.fill").foregroundColor(.red).font(.system(size: 20)).scaleEffect(pulse)
                        .onAppear { withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { pulse = 1.2 } }
                    Text("BPM").font(.system(size: 12, weight: .bold)).foregroundColor(.cyan)
                }
                .padding(.top, 8)
            }

            Spacer()
            
            // 3. CONTROLES PARA MANDAR AL IPHONE
            HStack(spacing: 12) {
                // Detener
                Button(action: {
                    connectivity.sendMusicCommand("stop")
                    withAnimation(.easeOut) { isTraining = false }
                }) { Image(systemName: "xmark").font(.system(size: 16, weight: .black)).foregroundColor(.white) }
                .frame(width: 40, height: 40).background(Color.red.opacity(0.8)).clipShape(Circle()).buttonStyle(PlainButtonStyle())
                
                // Play / Pause
                Button(action: {
                    isPlaying.toggle()
                    connectivity.sendMusicCommand("playPause")
                }) { Image(systemName: isPlaying ? "pause.fill" : "play.fill").font(.system(size: 18, weight: .black)).foregroundColor(.white) }
                .frame(width: 50, height: 50).background(Color.purple).clipShape(Circle()).buttonStyle(PlainButtonStyle())
                
                // Pasar Canción
                Button(action: {
                    connectivity.sendMusicCommand("nextTrack")
                }) { Image(systemName: "forward.end.fill").font(.system(size: 16, weight: .black)).foregroundColor(.black) }
                .frame(width: 40, height: 40).background(Color.cyan).clipShape(Circle()).buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 5)
        }
        .padding(.horizontal)
        .onAppear { heartRateManager.requestAuthorization() }
    }
}

struct OnboardingView: View {
    var step: String; var titleText: String; var subText: String
    var iconName: String? = nil; var iconColor: Color = .cyan; var iconView: AnyView? = nil
    
    var body: some View {
        VStack(spacing: 2) {
            Text("RUM WATCH")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.purple)
                .tracking(2)
            
            Spacer(minLength: 1)
            
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.system(size: 38))
                    .foregroundColor(iconColor)
                    .shadow(color: iconColor.opacity(0.4), radius: 8)
            } else if let customView = iconView {
                customView
            }
            
            Spacer(minLength: 1)
            
            Text(titleText)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            
            Text(subText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true) // Fuerza el crecimiento vertical sin truncar
                .padding(.horizontal, 2)
            
            Text(step)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.purple)
                .padding(.top, 1)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }
}
