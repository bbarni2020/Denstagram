import SwiftUI

struct InstagramLoadingView: View {
    @State private var rotation: Double = 0
    @State private var trimEnd: CGFloat = 0.7
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            ZStack {
                Circle()
                    .trim(from: 0, to: trimEnd)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.51, green: 0.29, blue: 0.92),
                                Color(red: 0.98, green: 0.35, blue: 0.42),
                                Color(red: 0.95, green: 0.51, blue: 0.19),
                                Color(red: 0.98, green: 0.64, blue: 0.17),
                                Color(red: 0.51, green: 0.29, blue: 0.92)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: Color(red: 0.98, green: 0.35, blue: 0.42).opacity(0.3), radius: 4, x: 0, y: 0)
            }
            .onAppear {
                isAnimating = true
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
                
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    trimEnd = 0.2
                }
            }
            .onDisappear {
                isAnimating = false
            }
        }
    }
}

#Preview {
    InstagramLoadingView()
}
