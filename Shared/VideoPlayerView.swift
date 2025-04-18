import SwiftUI
import AVKit

class VideoPlayerObserver: NSObject {
    var player: AVPlayer?
    var onReady: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func observe(player: AVPlayer, onReady: @escaping () -> Void) {
        self.player = player
        self.onReady = onReady
        player.currentItem?.addObserver(
            self,
            forKeyPath: "status",
            options: [.new],
            context: nil
        )
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                if item.status == .readyToPlay {
                    onReady?()
                }
            }
        }
    }
    
    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
    }
}

struct VideoPlayerView: View {
    let videoName: String
    let videoExtension: String
    let loopMode: Bool
    let videoGravity: AVLayerVideoGravity
    
    @State private var player: AVPlayer?
    @State private var isReady = false
    @State private var observer = VideoPlayerObserver()
    
    init(
        videoName: String,
        videoExtension: String = "mp4",
        loopMode: Bool = true,
        videoGravity: AVLayerVideoGravity = .resizeAspect
    ) {
        self.videoName = videoName
        self.videoExtension = videoExtension
        self.loopMode = loopMode
        self.videoGravity = videoGravity
    }
    
    var body: some View {
        VideoPlayer(player: player)
            .background(Color.white)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
    
    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            print("Could not find video: \(videoName).\(videoExtension)")
            return
        }
        
        let player = AVPlayer(url: url)
        
        // Set up observer
        observer.observe(player: player) {
            isReady = true
        }
        
        if loopMode {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
        }
        
        self.player = player
        player.play()
    }
}

#if os(macOS)
struct VideoPlayer: NSViewRepresentable {
    let player: AVPlayer?
    let videoGravity: AVLayerVideoGravity
    
    init(player: AVPlayer?, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        self.player = player
        self.videoGravity = videoGravity
    }
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = videoGravity
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
        nsView.videoGravity = videoGravity
    }
}
#else
struct VideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer?
    let videoGravity: AVLayerVideoGravity
    
    init(player: AVPlayer?, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        self.player = player
        self.videoGravity = videoGravity
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = videoGravity
        controller.view.backgroundColor = .white
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.videoGravity = videoGravity
    }
}
#endif

#Preview {
    VideoPlayerView(videoName: "hell yeeeeeeah")
        .frame(width: 200, height: 200)
} 