import SwiftUI

struct AppOnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    // Variables biométricas globales persistentes
    @AppStorage("userAge") private var userAge: Int = 21
    @AppStorage("userHeight") private var userHeight: Int = 170
    @AppStorage("restingHR") private var restingHR: Double = 60.0
    
    @State private var currentStep = 0
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            // Efecto de iluminación de fondo estilo Neón
            Circle().fill(Color.purple.opacity(0.15)).frame(width: 400).blur(radius: 80).offset(x: -150, y: -200)
            Circle().fill(Color.cyan.opacity(0.15)).frame(width: 400).blur(radius: 80).offset(x: 150, y: 200)

            VStack {
                TabView(selection: $currentStep) {
                    AppOnboardingContent(image: "waveform.path.ecg", title: "TU CORAZÓN,\nTU MÚSICA", description: "RUM sincroniza cada latido con el tempo de tu música favorita en tiempo real.", color: .cyan).tag(0)
                    AppOnboardingContent(image: "applewatch.radiowaves.left.and.right", title: "CONTROL\nBIOMÉTRICO", description: "Ajustamos la velocidad de las pistas mediante Time-Stretching para mantenerte en tu zona ideal.", color: .purple).tag(1)
                    AppOnboardingContent(image: "bolt.ring.closed", title: "RENDIMIENTO\nCIENTÍFICO", description: "Usamos la fórmula de Karvonen para personalizar tus zonas según tu edad y condición física.", color: .green).tag(2)
                    
                    // Cuestionario interactivo con el escáner biométrico integrado
                    BiometricQuestionnaire(age: $userAge, height: $userHeight, restingHR: $restingHR) {
                        withAnimation { hasCompletedOnboarding = true }
                    }.tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
        }
    }
}

struct AppOnboardingContent: View {
    let image: String; let title: String; let description: String; let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 2).frame(width: 200, height: 200).scaleEffect(isAnimating ? 1.2 : 1.0).opacity(isAnimating ? 0 : 1)
                Image(systemName: image).font(.system(size: 80)).foregroundColor(color).shadow(color: color.opacity(0.5), radius: 20)
            }
            .onAppear { withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) { isAnimating = true } }
            
            VStack(spacing: 20) {
                Text(title).font(.system(size: 36, weight: .black, design: .rounded)).multilineTextAlignment(.center).foregroundColor(.white)
                Text(description).font(.system(size: 18)).multilineTextAlignment(.center).foregroundColor(.gray).padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Cuestionario con Escáner de Pulso en Reposo
struct BiometricQuestionnaire: View {
    @ObservedObject var connectivity = ConnectivityManager.shared
    
    @Binding var age: Int
    @Binding var height: Int
    @Binding var restingHR: Double
    var onFinish: () -> Void
    
    // Estados internos para la animación del escáner técnico
    @State private var isAnalyzing = false
    @State private var progress: Double = 0.0
    @State private var countdown = 5
    @State private var collectedSamples: [Double] = []
    @State private var hasMeasured = false
    @State private var heartScale: CGFloat = 1.0
    
    // 🔥 Temporizador clásico corregido 🔥
    @State private var activeTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 25) {
            Text("CONFIGURACIÓN BIOMÉTRICA")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.cyan)
                .tracking(3)
            
            VStack(spacing: 20) {
                biometricRow(title: "Edad del Atleta", value: "\(age) años", icon: "person.fill", color: .purple) {
                    Stepper("", value: $age, in: 16...80).labelsHidden()
                }
                
                biometricRow(title: "Altura Estructural", value: "\(height) cm", icon: "figure.stand", color: .blue) {
                    Stepper("", value: $height, in: 120...220).labelsHidden()
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 20)
            
            // CARD DE ANÁLISIS DE PULSO EN REPOSO
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .stroke(isAnalyzing ? Color.red.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 60, height: 60)
                        
                        if isAnalyzing {
                            Circle()
                                .trim(from: 0, to: CGFloat(progress))
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(hasMeasured || isAnalyzing ? .red : .gray)
                            .scaleEffect(heartScale)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Frecuencia en Reposo")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if isAnalyzing {
                            Text("Analizando telemetría... \(countdown)s")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        } else if hasMeasured {
                            Text("Calibrado: \(Int(restingHR)) BPM")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .bold()
                        } else {
                            Text("Requiere lectura del Apple Watch")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding(15)
                .background(Color.white.opacity(0.03))
                .cornerRadius(20)
                
                // Botón de activación del escáner
                if !isAnalyzing {
                    Button(action: startPulseAnalysis) {
                        Label(hasMeasured ? "Volver a Medir" : "Escanear Pulso Basal", systemImage: "waveform.path.ecg")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(isAnalyzing ? Color.red.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 20)
            
            // BOTÓN DE ACCESO PRINCIPAL
            Button(action: onFinish) {
                Text("COMENZAR ENTRENAMIENTO")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: hasMeasured ? [.cyan, .purple] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: hasMeasured ? .cyan.opacity(0.3) : .clear, radius: 10, y: 5)
            }
            .disabled(!hasMeasured)
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    func startPulseAnalysis() {
        isAnalyzing = true
        progress = 0.0
        countdown = 5
        collectedSamples.removeAll()
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            heartScale = 1.2
        }
        
        // Asignamos el temporizador clásico
        activeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if countdown > 0 {
                countdown -= 1
                withAnimation(.linear(duration: 1.0)) {
                    progress += 0.2
                }
                
                let currentWatchBPM = connectivity.heartRateReceived
                if currentWatchBPM > 0 {
                    collectedSamples.append(currentWatchBPM)
                }
            } else {
                t.invalidate()
                finishPulseAnalysis()
            }
        }
    }
    
    func finishPulseAnalysis() {
        stopTimer()
        withAnimation(.spring()) {
            heartScale = 1.0
            isAnalyzing = false
            hasMeasured = true
            
            if !collectedSamples.isEmpty {
                restingHR = collectedSamples.reduce(0, +) / Double(collectedSamples.count)
            } else {
                restingHR = connectivity.heartRateReceived > 0 ? connectivity.heartRateReceived : 65.0
            }
        }
    }
    
    func stopTimer() {
        activeTimer?.invalidate()
        activeTimer = nil
    }
    
    func biometricRow<Content: View>(title: String, value: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).font(.title3).frame(width: 35)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            }
            Spacer()
            content()
        }
    }
}
