import Foundation
import HealthKit
import Combine

class HeartRateManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    @Published var currentHeartRate: Double = 0.0
    
    override init() {
        super.init()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // 🔥 Para que no se duerma, NECESITAMOS pedir permiso de Workout además del corazón 🔥
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.startWorkoutSession()
                }
            } else if let error = error {
                print("Error de HealthKit: \(error.localizedDescription)")
            }
        }
    }
    
    // ==========================================
    // 🔥 EL PASE VIP PARA QUE NO SE CONGELE 🔥
    // ==========================================
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
        } catch {
            print("Error creando la sesión: \(error.localizedDescription)")
            return
        }
        
        workoutSession?.delegate = self
        workoutBuilder?.delegate = self
        workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        
        // Esto enciende las luces verdes permanentemente y evita la suspensión
        workoutSession?.startActivity(with: Date())
        workoutBuilder?.beginCollection(withStart: Date()) { success, error in
            if success {
                print("Telemetría en tiempo real iniciada.")
            }
        }
    }
    
    // ==========================================
    // LECTURA DE LATIDOS (1 VEZ POR SEGUNDO)
    // ==========================================
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue else { continue }
            
            if let statistics = workoutBuilder.statistics(for: quantityType),
               let heartRate = statistics.mostRecentQuantity() {
                
                let value = heartRate.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                
                // 🔥 1. DISPARO AL IPHONE DESDE EL HILO DE FONDO 🔥
                // Al estar afuera, el Bluetooth sigue disparando latidos aunque la pantalla se oscurezca
                ConnectivityManager.shared.sendHeartRate(value)
                
                // 🔥 2. ACTUALIZAMOS LA UI DEL RELOJ 🔥
                // Esto solo actualiza el número visual, si la pantalla duerme, esto se pausa, ¡pero el paso 1 sigue vivo!
                DispatchQueue.main.async {
                    self.currentHeartRate = value
                }
            }
        }
    }
    
    // Protocolos obligatorios de HealthKit (se dejan vacíos)
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}
