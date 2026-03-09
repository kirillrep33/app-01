import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.82, blue: 0.90),
                    Color(red: 0.01, green: 0.25, blue: 0.60)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if UIImage(named: "Fish") != nil {
                    Image("Fish")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(opacity)
                } else {
                    Text("🐟")
                        .font(.system(size: 100))
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                Text("Fish Stock Finance")
                    .font(.custom("Unbounded-Regular", size: 28))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct RootViewWithSplash: View {
    @State private var showSplash = true
    let store: FishStockStore
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                AppRootView(store: store)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
