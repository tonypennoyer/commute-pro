import SwiftUI
import Lottie

struct LottieView: View {
    let animationName: String
    let loopMode: LottieLoopMode
    let contentMode: ContentMode
    
    init(
        animationName: String,
        loopMode: LottieLoopMode = .loop,
        contentMode: ContentMode = .scaleAspectFit
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.contentMode = contentMode
    }
    
    var body: some View {
        LottieViewRepresentable(
            animationName: animationName,
            loopMode: loopMode,
            contentMode: contentMode
        )
    }
}

struct LottieViewRepresentable: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let contentMode: ContentMode
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView()
        
        if let animation = LottieAnimation.named(animationName) {
            animationView.animation = animation
            animationView.contentMode = contentMode == .scaleAspectFit ? .scaleAspectFit : .scaleAspectFill
            animationView.loopMode = loopMode
            
            animationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animationView)
            
            NSLayoutConstraint.activate([
                animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
                animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
            
            animationView.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#if os(macOS)
struct LottieViewRepresentable: NSViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let contentMode: ContentMode
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        let animationView = LottieAnimationView()
        
        if let animation = LottieAnimation.named(animationName) {
            animationView.animation = animation
            animationView.contentMode = contentMode == .scaleAspectFit ? .scaleAspectFit : .scaleAspectFill
            animationView.loopMode = loopMode
            
            animationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animationView)
            
            NSLayoutConstraint.activate([
                animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
                animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
            
            animationView.play()
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

#Preview {
    LottieView(animationName: "loading")
} 