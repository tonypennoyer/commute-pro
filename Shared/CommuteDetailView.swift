import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
import AVFAudio
#endif
import AVFoundation

struct CommuteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var commute: Commute

    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingPRCelebration = false
    @State private var celebrationOffset: CGFloat = UIScreen.main.bounds.width

    var sessions: [Session] {
        (commute.sessions as? Set<Session>)?.sorted { $0.date ?? Date() > $1.date ?? Date() } ?? []
    }

    var averageTime: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.duration }
        return total / Double(sessions.count)
    }

    private var backgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor).opacity(0.5)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 8) {
                    Text(commute.name ?? "")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Label(commute.mode ?? "", systemImage: modeIcon(for: commute.mode ?? ""))
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Timer Section
                VStack(spacing: 16) {
                    Text(timeString(from: elapsedTime))
                        .font(.system(size: 64, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                    
                    Button(action: { isRunning ? stopTimer() : startTimer() }) {
                        Text(isRunning ? "Stop" : "Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(isRunning ? Color.red : Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Add clear button for testing
                    Button(action: clearAllSessions) {
                        Text("Clear All Times (Testing)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical)
                .overlay {
                    if showingPRCelebration {
                        VStack {
                            Text("niiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiice")
                                .font(.system(size: 48, weight: .black))
                                .foregroundColor(.black)
                                .shadow(color: .white, radius: 2)
                                .offset(x: celebrationOffset)
                                .transition(.opacity)
                                .lineLimit(1)
                                .fixedSize()
                            
                            Spacer()
                            
                            Text("WoW")
                                .font(.system(size: 72, weight: .black))
                                .foregroundColor(.black)
                                .shadow(color: .white, radius: 2)
                                .padding(.bottom, 120)
                        }
                    }
                }
                
                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack {
                        StatView(title: "Average Time", value: timeString(from: averageTime))
                        Divider()
                        StatView(title: "Total Trips", value: "\(sessions.count)")
                    }
                }
                .padding()
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // History Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ForEach(sessions, id: \.self) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(timeString(from: session.duration))
                                    .font(.headline)
                                if let date = session.date {
                                    Text(dateFormatter.string(from: date))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button(action: {
                                deleteSession(session)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    func startTimer() {
        startTime = Date()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        
        // Don't save if duration is 0
        if duration < 1 {
            print("⏱️ Timer stopped too quickly, ignoring...")
            elapsedTime = 0
            return
        }
        
        print("⏱️ Timer stopped with duration: \(timeString(from: duration))")

        let session = Session(context: viewContext)
        session.id = UUID()
        session.date = Date()
        session.duration = duration
        session.commute = commute

        // Check if this is a PR
        let isPRTime = isPR(duration)
        print("🏆 Is this a PR? \(isPRTime)")
        
        if isPRTime {
            print("🎉 Starting PR celebration!")
            playAirhorn()
            withAnimation {
                showingPRCelebration = true
            }
            
            // Animate the text scrolling across the screen
            withAnimation(.linear(duration: 3)) {
                celebrationOffset = -UIScreen.main.bounds.width * 1.5
            }
            
            // Reset and hide after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingPRCelebration = false
                }
                celebrationOffset = UIScreen.main.bounds.width
            }
        }

        try? viewContext.save()
        elapsedTime = 0
    }

    func isPR(_ duration: TimeInterval) -> Bool {
        // Don't count zero durations
        if duration < 1 {
            return false
        }
        
        // Get all previous sessions for this commute
        let previousSessions = (commute.sessions as? Set<Session>)?.filter { 
            // Filter out sessions with 0 duration and future dates
            ($0.duration > 0) && ($0.date ?? Date() < Date())
        } ?? []
        
        print("📊 Previous sessions count: \(previousSessions.count)")
        print("📊 Current duration: \(timeString(from: duration))")
        if !previousSessions.isEmpty {
            let bestTime = previousSessions.map { $0.duration }.min() ?? Double.infinity
            print("📊 Best previous time: \(timeString(from: bestTime))")
            print("📊 All previous times:")
            previousSessions.forEach { session in
                print("   - \(timeString(from: session.duration))")
            }
            
            // A new PR is when the current duration is LESS than or EQUAL TO the best time
            let isPR = duration <= bestTime
            print("🎯 Current time (\(timeString(from: duration))) <= Best time (\(timeString(from: bestTime)))? \(isPR)")
            return isPR
        }
        
        // If this is the first valid session, it's automatically a PR
        print("🎯 First session - automatic PR!")
        return true
    }
    
    func playAirhorn() {
        #if !os(macOS)
        // Configure audio session for iOS
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif

        guard let soundURL = Bundle.main.url(forResource: "airhorn", withExtension: "mp3") else {
            print("❌ Sound file not found in bundle")
            // Debug print bundle contents
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("📦 Bundle contents: \(contents)")
                } catch {
                    print("Failed to list bundle contents: \(error)")
                }
            }
            return
        }
        
        print("✅ Found sound file at: \(soundURL)")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            print("🎵 Starting playback...")
            audioPlayer?.play()
        } catch {
            print("❌ Could not play sound: \(error)")
        }
    }

    func deleteSession(_ session: Session) {
        withAnimation {
            viewContext.delete(session)
            try? viewContext.save()
        }
    }

    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func modeIcon(for mode: String) -> String {
        switch mode.lowercased() {
        case "walk": return "figure.walk"
        case "bike": return "bicycle"
        case "car": return "car"
        case "subway": return "tram"
        case "bus": return "bus"
        default: return "figure.walk"
        }
    }

    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }

    // Add a function to clear all sessions (for testing)
    func clearAllSessions() {
        let allSessions = commute.sessions as? Set<Session> ?? []
        for session in allSessions {
            viewContext.delete(session)
        }
        try? viewContext.save()
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}
