import Foundation
import WatchConnectivity
import Combine

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    
    // MARK: - Variables de Estado
    @Published var heartRateReceived: Double = 0.0
    @Published var isWatchConnected: Bool = false
    @Published var watchName: String = "Buscando..."
    @Published var currentZoneName: String = "ESPERANDO IPHONE..."
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    

    func sendHeartRate(_ heartRate: Double) {
        let payload: [String: Any] = ["heartRate": heartRate]
        
        
        WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] _ in
            // Fallback en background si falla la entrega inmediata
            self?.updateContext(payload)
        }
    }
    
    func sendMusicCommand(_ command: String) {
        let payload: [String: Any] = ["musicCommand": command]
        
        WCSession.default.sendMessage(payload, replyHandler: nil) { error in
            print("Error enviando comando de música: \(error.localizedDescription)")
        }
    }
    
    // ==========================================
    // MARK: - 2. MÉTODOS DE ENVÍO (iPhone -> Apple Watch)
    // ==========================================
    
    func sendZoneToWatch(zoneName: String) {
        let payload: [String: Any] = ["targetZoneName": zoneName]
        
        // 🔥 FUERZA BRUTA DE REGRESO
        WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] _ in
            self?.updateContext(payload)
        }
    }
    
    private func updateContext(_ context: [String: Any]) {
        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            print("Error actualizando ApplicationContext: \(error.localizedDescription)")
        }
    }
    
    // ==========================================
    // MARK: - 3. PROCESAMIENTO DE MENSAJES
    // ==========================================
    
    private func processIncomingDictionary(_ dict: [String: Any]) {
        DispatchQueue.main.async {
            if let hr = dict["heartRate"] as? Double {
                self.heartRateReceived = hr
                self.isWatchConnected = true
            }
            
            if let command = dict["musicCommand"] as? String {
                NotificationCenter.default.post(name: NSNotification.Name("RUM_\(command)"), object: nil)
            }
            
            if let zone = dict["targetZoneName"] as? String {
                self.currentZoneName = zone
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processIncomingDictionary(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        processIncomingDictionary(applicationContext)
    }
    
    // ==========================================
    // MARK: - 4. GESTIÓN DE CONEXIÓN Y CICLO DE VIDA
    // ==========================================
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if activationState == .activated {
                #if os(iOS)
                if session.isPaired && session.isWatchAppInstalled {
                    self.isWatchConnected = true
                    self.watchName = "Apple Watch Enlazado"
                } else {
                    self.isWatchConnected = false
                    self.watchName = "Requiere App en Reloj"
                }
                #else
                self.isWatchConnected = true
                self.watchName = "iPhone Enlazado"
                #endif
            } else {
                self.isWatchConnected = false
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            #if os(iOS)
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
            #else
            self.isWatchConnected = session.isReachable
            #endif
        }
    }
    
    // Métodos obligatorios exclusivos para iOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactiva la sesión automáticamente si el usuario cambia de Apple Watch
        WCSession.default.activate()
    }
    #endif
}
