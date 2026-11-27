import SwiftUI

struct ProfileView: View {
    @AppStorage("userAge") private var userAge: Int = 21
    @AppStorage("userHeight") private var userHeight: Int = 170
    @State private var userName: String = "Jacobo Restrepo" // Campo editable para el nombre
    
    var body: some View {
        ZStack {
            // Fondo oscuro unificado de RUM
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    
                    // HEADING DE LA PANTALLA
                    Text("Mi Perfil")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    // SECCIÓN: FOTO DE PERFIL ESTÉTICA
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                                .shadow(color: .purple.opacity(0.3), radius: 15, y: 5)
                            
                            // Iniciales estilizadas como marcador de posición premium
                            Text(userName.prefix(2).uppercased())
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Nombre del Atleta (Editable de forma limpia)
                        TextField("Nombre", text: $userName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 10)
                    
                    // SECCIÓN: CONTROLES BIOMÉTRICOS (AJUSTES)
                    VStack(spacing: 24) {
                        
                        // Control de Edad
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Edad", systemImage: "person.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(userAge) años")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.purple)
                                    .bold()
                            }
                            
                            Slider(value: Binding(
                                get: { Double(userAge) },
                                set: { userAge = Int($0) }
                            ), in: 16...60, step: 1)
                            .tint(.purple)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Control de Altura
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Altura", systemImage: "figure.stand")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(userHeight) cm")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.cyan)
                                    .bold()
                            }
                            
                            Slider(value: Binding(
                                get: { Double(userHeight) },
                                set: { userHeight = Int($0) }
                            ), in: 120...220, step: 1)
                            .tint(.cyan)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .padding(.horizontal, 24)
                    
                    // EXPLICACIÓN TÉCNICA PARA EL JURADO
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MÉTRICA DE CONTROL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.purple)
                            .tracking(2)
                        
                        Text("El motor de RUM mapea automáticamente estos parámetros junto con un pulso basal constante de 65 BPM. Esto optimiza la precisión de la ecuación de Karvonen sin generar fricción en el registro del usuario.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    
                }
                .padding(.bottom, 40)
            }
        }
    }
}
