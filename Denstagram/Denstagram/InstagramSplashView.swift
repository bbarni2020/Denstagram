import SwiftUI

struct InstagramSplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.51, green: 0.29, blue: 0.92),
                                    Color(red: 0.98, green: 0.35, blue: 0.42),
                                    Color(red: 0.95, green: 0.51, blue: 0.19),
                                    Color(red: 0.98, green: 0.64, blue: 0.17)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 7
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.51, green: 0.29, blue: 0.92),
                                    Color(red: 0.98, green: 0.35, blue: 0.42),
                                    Color(red: 0.95, green: 0.51, blue: 0.19),
                                    Color(red: 0.98, green: 0.64, blue: 0.17)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 7)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .offset(x: 20, y: -20)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("from")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .opacity(opacity)
                    
                    HStack(spacing: 0) {
                        Image(systemName: "infinity")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Balogh Barnabás")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .opacity(opacity)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                showContent = true
            }
        }
    }
}

#Preview {
    InstagramSplashView()
}
