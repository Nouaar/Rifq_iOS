import SwiftUI
import Combine

// MARK: - Splash

struct SplashView: View {
    @EnvironmentObject private var session: SessionManager
    // Navigation
    @State private var goNext = false

    // Animations
    @State private var pawWave = false       // micro rebond des pattes
    @State private var titleScale: CGFloat = 0.92
    @State private var titleOpacity: CGFloat = 0
    @State private var subtitleOpacity: CGFloat = 0
    @State private var dotsIndex: Int = 0

    // Timer des points (rythme comme dans la vidéo)
    private let dotsTimer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    // Durées (tweak si besoin)
    private let appearDelay: Double = 0.10
    private let totalDuration: Double = 2.10

    var body: some View {
        ZStack {
            // Fond orange plein
            Color.vetCanyon.ignoresSafeArea()

            VStack(spacing: 26) {
                // Pattes en diagonale, micro rebond continu (stagger)
                ZStack {
                    Paw(angle: -18, baseX: -12, baseY: -8, wave: pawWave, delay: 0.00)
                    Paw(angle:  18, baseX:  24, baseY:  18, wave: pawWave, delay: 0.12)
                }
                .padding(.top, -8)

                // Titre "vet.tn" (scale + fade)
                Text("vet.tn")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .tracking(0.4)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)
                    .animation(.spring(response: 0.60, dampingFraction: 0.82).delay(appearDelay), value: titleScale)
                    .animation(.easeOut(duration: 0.35).delay(appearDelay), value: titleOpacity)

                // Sous-titre (fade)
                Text("PET HEALTHCARE")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.top, -6)
                    .opacity(subtitleOpacity)
                    .animation(.easeOut(duration: 0.30).delay(appearDelay + 0.16), value: subtitleOpacity)

                // 3 points en séquence
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(i == dotsIndex ? .white : .white.opacity(0.45))
                            .scaleEffect(i == dotsIndex ? 1.15 : 1.0)
                            .animation(.easeOut(duration: 0.18), value: dotsIndex)
                    }
                }
                .padding(.top, 10)
            }
        }
        .statusBarHidden(true)
        .onReceive(dotsTimer) { _ in
            dotsIndex = (dotsIndex + 1) % 3
        }
        .onAppear {
            // Lancement identique à la vidéo
            pawWave = true
            titleScale = 1.0
            titleOpacity = 1.0
            subtitleOpacity = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                goNext = true
            }
        }
        .fullScreenCover(isPresented: $goNext) {
            // Decide destination based on authentication state
            if session.isAuthenticated {
                MainTabView()
                    .statusBarHidden(false)
            } else {
                LoginView()
                    .statusBarHidden(false)
            }
        }
    }
}

// MARK: - Sous-vue : patte avec micro-rebond

private struct Paw: View {
    let angle: Double
    let baseX: CGFloat
    let baseY: CGFloat
    let wave: Bool
    let delay: Double

    var body: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 58))
            .foregroundStyle(.black.opacity(0.75))
            .rotationEffect(.degrees(-18))
            .offset(x: baseX, y: baseY)
            .offset(y: wave ? -3.5 : 3.5) 
            .animation(
                .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: wave
            )
    }
}


// MARK: - Preview

#Preview("Splash – vet.tn") {
    SplashView()
        .environmentObject(SessionManager())
}
