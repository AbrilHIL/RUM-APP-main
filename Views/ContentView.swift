import SwiftUI
import AVFoundation
import Combine

// ==========================================
// 🔥 MODELOS 🔥
// ==========================================
struct CloudTrack: Identifiable, Decodable {
    let id: String
    let title: String
    let artist: String
    let baseBPM: Int
    let audioURL: String
}

enum RUMTab {
    case home, musica, history, settings
}

// ==========================================
// 🔥 1. EL ENRUTADOR PRINCIPAL (EL PORTERO) 🔥
// ==========================================
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainAppView()
            } else {
                AppOnboardingView()
            }
        }
        .onAppear {
            // 🔥 MODO DEFENSA DE TESIS 🔥
            // Fuerzas a que la app muestre el Onboarding siempre que se abra desde cero.
            hasCompletedOnboarding = false
        }
    }
}

// ==========================================
// 🔥 2. LA APLICACIÓN PRINCIPAL (TU CÓDIGO REAL) 🔥
// ==========================================
struct MainAppView: View {
    @ObservedObject var connectivity = ConnectivityManager.shared
    
    // Variables extraídas del Onboarding
    @AppStorage("userAge") private var userAge: Int = 21
    @AppStorage("restingHR") private var restingHR: Double = 60.0
    
    @State private var selectedTab: RUMTab = .home
    @State private var isWorkoutActive = false
    @State private var showZoneSelection = false
    @State private var showCountdown = false
    @State private var countdownValue = 3
    @State private var showSummary = false
    
    @State private var heartRateHistory: [Double] = []
    @State private var selectedTargetZone = 3
    @State private var workoutTimeSeconds: Int = 0
    let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let miPropiaAPI = "https://gist.githubusercontent.com/Yeicob99/b9bb476a49217ce3da24fb6cae8e1a37/raw/gistfile1.txt"
    
    @State private var loadedTracks: [CloudTrack] = []
    @State private var currentTrackIndex = 0
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentPlaybackSpeed: Double = 1.0
    @State private var smoothedBPM: Double = 0.0
    
    // 🔥 ESTADO DE CONCURRENCIA PARA EL AUDIO 🔥
    @State private var currentDownloadTask: Task<Void, Never>? = nil
    
    @State private var finalMaxBPM: Int = 0
    @State private var finalAvgBPM: Int = 0
    @State private var finalSyncScore: Int = 0
    @State private var finalCalories: Int = 0
    @State private var finalDistance: Double = 0.0
    @State private var finalZonePercentages: [Int] = [0,0,0,0,0]
    
    // 🔥 EL VERDADERO ALGORITMO DE KARVONEN 🔥
    var targetMusicBPM: Int {
        let fcMax = 220.0 - Double(userAge)
        let fcReserva = fcMax - restingHR // restingHR viene del escáner del Onboarding
        
        let intensidad: Double
        switch selectedTargetZone {
        case 1: intensidad = 0.30 // Z1: ~105 BPM
        case 2: intensidad = 0.40 // Z2: ~118 BPM
        case 3: intensidad = 0.50 // Z3: ~132 BPM
        case 4: intensidad = 0.60 // Z4: ~145 BPM
        default: intensidad = 0.75 // Z5: ~165 BPM
        }
        
        let latidoObjetivo = (fcReserva * intensidad) + restingHR
        return Int(latidoObjetivo)
    }
    
    // 🔥 MOTOR MATEMÁTICO BASADO EN LATIDOS REALES 🔥
    var RUMAlgorithmEngine: (status: String, recommendedTrack: CloudTrack?, targetSpeed: Double) {
        if smoothedBPM == 0 { return ("Buscando Pulso...", nil, 1.0) }
        if loadedTracks.isEmpty { return ("Sin Nube", nil, 1.0) }
        
        let idealBPM = Double(targetMusicBPM)
        let currentBPM = smoothedBPM
        
        let lowerBound = idealBPM - 5; let upperBound = idealBPM + 5
        var recommendation: CloudTrack? = nil; var message = "¡EN ZONA!"; var calculatedSpeed: Double = 1.0
        
        // CÁLCULO DEL PITCH (P-CONTROLLER)
        if currentBPM < lowerBound {
            message = "¡ACELERA!"; let deficit = lowerBound - currentBPM; calculatedSpeed = 1.0 + min(0.25, (deficit / 20.0) * 0.25)
        } else if currentBPM > upperBound {
            message = "¡FRENA!"; let exceso = currentBPM - upperBound; calculatedSpeed = 1.0 - min(0.25, (exceso / 20.0) * 0.25)
        }
        
        // CÁLCULO DE SUGERENCIAS
        let desfaseAbsoluto = abs(currentBPM - idealBPM)
        if desfaseAbsoluto > 15 {
            var minDiff = Double.greatestFiniteMagnitude
            for track in loadedTracks {
                let diff = abs(Double(track.baseBPM) - currentBPM)
                if diff < minDiff && track.id != loadedTracks[currentTrackIndex].id {
                    minDiff = diff
                    recommendation = track
                }
            }
        }
        
        return (message, recommendation, calculatedSpeed)
    }

    var body: some View {
        ZStack {
            mainContentView
            floatingPanels
        }
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            if loadedTracks.isEmpty { Task { await fetchCloudPlaylist() } }
        }
        .onReceive(sessionTimer) { _ in
            if isWorkoutActive && isPlaying { workoutTimeSeconds += 1 }
        }
        
        // 🔥 ESCUCHADOR ABSOLUTO DEL APPLE WATCH (REPARADO PARA TIEMPO REAL) 🔥
        .onReceive(connectivity.$heartRateReceived) { newRawBPM in
            if newRawBPM > 0 {
                withAnimation(.snappy(duration: 0.3)) { smoothedBPM = newRawBPM }
                if isWorkoutActive {
                    // Solo guardamos en el historial si cambió, para no saturar la RAM
                    if heartRateHistory.last != newRawBPM {
                        heartRateHistory.append(newRawBPM)
                    }
                    
                    // Pero la velocidad del audio SIEMPRE se recalcula para mantener el flujo
                    actualizarVelocidadAudio()
                }
            }
        }
        
        .onChange(of: selectedTargetZone) { _, newZone in
            let zoneNames = ["RECUPERACIÓN", "AERÓBICA", "UMBRAL", "ESFUERZO MÁXIMO", "RUM EXTREMO"]
            let name = zoneNames[max(0, min(newZone - 1, 4))]
            connectivity.sendZoneToWatch(zoneName: "ZONA \(newZone): \(name)")
            actualizarVelocidadAudio()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RUM_nextTrack"))) { _ in
            if !loadedTracks.isEmpty {
                currentTrackIndex = (currentTrackIndex + 1) % loadedTracks.count
                iniciarDescargaSegura()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RUM_playPause"))) { _ in toggleAudio() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RUM_stop"))) { _ in
            if isWorkoutActive {
                if isPlaying { toggleAudio() }
                calcularMetricasFinales()
                withAnimation { isWorkoutActive = false; showSummary = true }
            }
        }
    }
    
    func actualizarVelocidadAudio() {
        if isWorkoutActive && !loadedTracks.isEmpty && audioPlayer != nil {
            let newSpeed = RUMAlgorithmEngine.targetSpeed
            if abs(currentPlaybackSpeed - newSpeed) > 0.01 {
                currentPlaybackSpeed = newSpeed
                audioPlayer?.rate = Float(newSpeed)
            }
        }
    }
    
    @ViewBuilder
    var mainContentView: some View {
        if showSummary {
            SessionSummaryView(
                durationStr: String(format: "%02d:%02d", workoutTimeSeconds / 60, workoutTimeSeconds % 60),
                targetZone: selectedTargetZone, avgBPM: finalAvgBPM, maxBPM: finalMaxBPM, syncScore: finalSyncScore,
                distance: finalDistance, calories: finalCalories, zonePercentages: finalZonePercentages,
                onGoHome: { heartRateHistory.removeAll(); workoutTimeSeconds = 0; withAnimation { showSummary = false; selectedTab = .home } }
            )
        } else if isWorkoutActive {
            ActiveTrainingView(
                smoothedBPM: $smoothedBPM, isPlaying: $isPlaying, selectedTargetZone: $selectedTargetZone,
                avgBPM: heartRateHistory.isEmpty ? 0 : Int(heartRateHistory.reduce(0, +) / Double(heartRateHistory.count)),
                formattedTime: String(format: "%02d:%02d", workoutTimeSeconds / 60, workoutTimeSeconds % 60),
                targetBPM: targetMusicBPM, baseBPM: loadedTracks.isEmpty ? 0 : loadedTracks[currentTrackIndex].baseBPM,
                trackTitle: loadedTracks.isEmpty ? "Cargando..." : loadedTracks[currentTrackIndex].title,
                trackArtist: loadedTracks.isEmpty ? "Conectando..." : loadedTracks[currentTrackIndex].artist,
                currentPlaybackSpeed: currentPlaybackSpeed, engineMessage: RUMAlgorithmEngine.status,
                suggestedTitle: RUMAlgorithmEngine.recommendedTrack?.title,
                onTogglePlay: { toggleAudio() },
                onEndWorkout: { if isPlaying { toggleAudio() }; calcularMetricasFinales(); withAnimation { isWorkoutActive = false; showSummary = true } },
                onAcceptSuggestion: {
                    if let suggested = RUMAlgorithmEngine.recommendedTrack, let newIndex = loadedTracks.firstIndex(where: { $0.id == suggested.id }) {
                        currentTrackIndex = newIndex
                        iniciarDescargaSegura()
                    }
                }
            )
        } else {
            homeOrProfileView
        }
    }
    
    @ViewBuilder
    var homeOrProfileView: some View {
        VStack(spacing: 0) {
            Group {
                if selectedTab == .home {
                    HomeView(
                        smoothedBPM: $smoothedBPM, isPlaying: $isPlaying, currentPlaybackSpeed: $currentPlaybackSpeed,
                        isWatchConnected: $connectivity.isWatchConnected, watchName: connectivity.watchName,
                        baseBPM: loadedTracks.isEmpty ? 0 : loadedTracks[currentTrackIndex].baseBPM,
                        trackTitle: loadedTracks.isEmpty ? "Cargando..." : loadedTracks[currentTrackIndex].title,
                        trackArtist: loadedTracks.isEmpty ? "Conectando..." : loadedTracks[currentTrackIndex].artist,
                        onPlayAction: { showZoneSelection = true }
                    )
                } else if selectedTab == .musica { MusicLibraryView(loadedTracks: loadedTracks)
                } else if selectedTab == .history { HistoryView()
                } else if selectedTab == .settings { ProfileView() }
            }
            FloatingTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    var floatingPanels: some View {
        if showZoneSelection {
            ZoneSelectionView(selectedZone: $selectedTargetZone) { showZoneSelection = false; startCountdownFlow() } onDismiss: { showZoneSelection = false }
            .transition(.move(edge: .bottom)).zIndex(2)
        }
        if showCountdown {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                VStack {
                    Text(countdownValue > 0 ? "\(countdownValue)" : "¡GO!").font(.system(size: 140, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("Sincronizando telemetría biométrica...").font(.system(size: 14)).foregroundColor(.white.opacity(0.5)).padding(.top, 20)
                }
            }.zIndex(3)
        }
    }
    
    func calcularMetricasFinales() {
        guard !heartRateHistory.isEmpty else { return }
        finalMaxBPM = Int(heartRateHistory.max() ?? 0)
        finalAvgBPM = Int(heartRateHistory.reduce(0, +) / Double(heartRateHistory.count))
        let timeInMinutes = Double(workoutTimeSeconds) / 60.0
        let burned = ((21.0 * 0.2017) - (170.0 * 0.09036) + (Double(finalAvgBPM) * 0.6309) - 55.0969) * timeInMinutes / 4.184
        finalCalories = max(0, Int(burned))
        finalDistance = (Double(workoutTimeSeconds) / 3600.0) * 8.5
        var counts = [0, 0, 0, 0, 0]
        for bpm in heartRateHistory {
            if bpm < 112 { counts[0] += 1 } else if bpm < 132 { counts[1] += 1 } else if bpm < 150 { counts[2] += 1 } else if bpm < 165 { counts[3] += 1 } else { counts[4] += 1 }
        }
        let totalRecords = Double(heartRateHistory.count)
        finalZonePercentages = counts.map { Int((Double($0) / totalRecords) * 100) }
        let targetIndex = selectedTargetZone - 1
        if targetIndex >= 0 && targetIndex < 5 { finalSyncScore = finalZonePercentages[targetIndex] }
        let formatter = DateFormatter(); formatter.dateFormat = "d MMM, hh:mm a"
        let currentTimestamp = formatter.string(from: Date()).uppercased()
        let newSession = WorkoutSession(title: "Entrenamiento Ritmo RUM", date: currentTimestamp, duration: String(format: "%02d:%02d min", workoutTimeSeconds / 60, workoutTimeSeconds % 60), distance: finalDistance, zone: selectedTargetZone)
        HistoryStore.saveSession(newSession)
    }
    
    func startCountdownFlow() {
        withAnimation { showCountdown = true; countdownValue = 3 }
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                withAnimation(.spring()) { countdownValue -= 1 }
            } else {
                timer.invalidate()
                
                if !loadedTracks.isEmpty {
                    let ideal = targetMusicBPM
                    var closestIndex = 0
                    var minDiff = Int.max
                    for (i, track) in loadedTracks.enumerated() {
                        let diff = abs(track.baseBPM - ideal)
                        if diff < minDiff { minDiff = diff; closestIndex = i }
                    }
                    currentTrackIndex = closestIndex
                }
                
                withAnimation { showCountdown = false; isWorkoutActive = true }
                
                let zoneNames = ["RECUPERACIÓN", "AERÓBICA", "UMBRAL", "ESFUERZO MÁXIMO", "RUM EXTREMO"]
                let name = zoneNames[max(0, min(selectedTargetZone - 1, 4))]
                connectivity.sendZoneToWatch(zoneName: "ZONA \(selectedTargetZone): \(name)")
                
                if !isPlaying {
                    iniciarDescargaSegura()
                } else {
                    actualizarVelocidadAudio()
                }
            }
        }
    }
    
    func fetchCloudPlaylist() async {
        guard let url = URL(string: miPropiaAPI) else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let fetchedTracks = try JSONDecoder().decode([CloudTrack].self, from: data)
            await MainActor.run { self.loadedTracks = fetchedTracks }
        } catch { print("Error API") }
    }
    
    // ==========================================
    // 🔥 FUNCIONES DE AUDIO SEGURAS 🔥
    // ==========================================
    
    func toggleAudio() {
        guard !loadedTracks.isEmpty else { return }
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            if audioPlayer == nil {
                iniciarDescargaSegura()
            } else {
                audioPlayer?.play()
                isPlaying = true
            }
        }
    }
    
    func iniciarDescargaSegura() {
        // 1. Cancelamos cualquier tarea vieja para evitar choques
        currentDownloadTask?.cancel()
        
        // 2. Apagamos y vaciamos el reproductor de inmediato
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        
        // 3. Iniciamos la nueva descarga de forma segura
        currentDownloadTask = Task {
            await descargarYReproducir()
        }
    }
    
    func descargarYReproducir() async {
        guard !loadedTracks.isEmpty else { return }
        let track = loadedTracks[currentTrackIndex]
        guard let url = URL(string: track.audioURL) else { return }
        
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Si el usuario tocó "siguiente" mientras descargaba, matamos esta ejecución
            if Task.isCancelled { return }
            
            let audioData = try Data(contentsOf: tempURL)
            let newPlayer = try AVAudioPlayer(data: audioData)
            newPlayer.enableRate = true
            newPlayer.prepareToPlay()
            
            await MainActor.run {
                // Última validación por seguridad
                self.audioPlayer?.stop()
                self.audioPlayer = newPlayer
                self.audioPlayer?.rate = Float(self.currentPlaybackSpeed)
                self.audioPlayer?.play()
                self.isPlaying = true
            }
        } catch {
            print("Error audio: \(error.localizedDescription)")
        }
    }
}
