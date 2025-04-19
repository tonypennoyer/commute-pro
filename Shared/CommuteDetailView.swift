import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
import AVFAudio
#endif
import AVFoundation
import CoreData

struct CommuteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var commute: Commute

    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingPRCelebration = false
    @State private var showingFasterCelebration = false
    @State private var showingStats = false
    @State private var statMessage = ""
    @State private var celebrationOffset: CGFloat = UIScreen.main.bounds.width
    @State private var selectedMode: CommuteMode = .subway
    @State private var selectedModes: Set<CommuteMode> = []
    @State private var showingSubmitButton = false

    var sessions: [Session] {
        (commute.sessions as? Set<Session>)?.sorted { $0.date ?? Date() > $1.date ?? Date() } ?? []
    }

    var averageTime: TimeInterval {
        let previousSessions = (commute.sessions as? Set<Session>)?.filter {
            ($0.duration > 0) && ($0.date ?? Date() < Date())
        } ?? []
        
        guard !previousSessions.isEmpty else { return 0 }
        let total = previousSessions.reduce(0) { $0 + $1.duration }
        return total / Double(previousSessions.count)
    }

    private var backgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor).opacity(0.5)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header Section
            VStack(spacing: 8) {
                Text(commute.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Timer Section
            VStack(spacing: 24) {
                Spacer()
                
                ZStack(alignment: .center) {
                    if isRunning && selectedMode == .bike {
                        VideoPlayerView(videoName: "bike_animation", videoExtension: "mp4", videoGravity: .resizeAspectFill)
                            .frame(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width) / 3.57)
                            .offset(y: -160)
                            .transition(.opacity)
                    }
                    
                    VStack(spacing: 24) {
                        Text(timeString(from: elapsedTime))
                            .font(.system(size: 84, weight: .medium, design: .monospaced))
                            .monospacedDigit()
                            .padding(.top, isRunning && selectedMode == .bike ? 40 : 0)
                        
                        HStack(spacing: 20) {
                            if showingSubmitButton {
                                // Reset Button
                                Button(action: resetTimer) {
                                    Text("Reset")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 44)
                                        .background(Color.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                // Submit Button
                                Button(action: submitTime) {
                                    Text("Submit")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 44)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            } else if !isRunning {
                                // Start Button
                                Button(action: startTimer) {
                                    Text("Start")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 44)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            } else {
                                // Done Button
                                Button(action: stopTimer) {
                                    Text("Done")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 44)
                                        .background(Color.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Mode Selection Section
            VStack(spacing: 8) {
                Text("Commute")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Picker("Transportation Mode", selection: $selectedMode) {
                    ForEach(CommuteMode.allCases) { mode in
                        Label {
                            Text(mode.rawValue.capitalized)
                        } icon: {
                            Image(systemName: modeIcon(for: mode.rawValue))
                        }
                        .tag(mode)
                    }
                }
                .disabled(isRunning || showingSubmitButton)
                .pickerStyle(.menu)
            }
            .padding(.bottom, 24)
        }
        .padding()
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: PastCommutesView(commute: commute)) {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
        #endif
        .overlay {
            if showingPRCelebration {
                VStack(spacing: 4) {
                    Text("niiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiice")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.green)
                        .offset(x: celebrationOffset)
                        .transition(.opacity)
                        .lineLimit(1)
                        .fixedSize()
                    
                    Spacer()
                    
                    Text("PR")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    Text("WoW")
                        .font(.system(size: 72, weight: .black))
                        .foregroundColor(.black)
                        .padding(.top, 4)
                }
                .padding(.top, 100)
            } else if showingFasterCelebration {
                Text("faster than average niiiiiiiiiiiiiiiice")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.green)
                    .offset(x: celebrationOffset)
                    .transition(.opacity)
                    .lineLimit(1)
                    .fixedSize()
            } else if showingStats {
                Text(statMessage)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(statMessage.contains("faster") ? .green : .red)
                    .transition(.opacity)
                    .padding(.top, 200)
            }
        }
    }

    func startTimer() {
        startTime = Date()
        isRunning = true
        showingSubmitButton = false
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
        showingSubmitButton = true
    }
    
    func resetTimer() {
        elapsedTime = 0
        startTime = nil
        showingSubmitButton = false
    }
    
    func submitTime() {
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        
        // Don't save if duration is less than 3 seconds
        if duration < 3 {
            print("⏱️ Timer stopped too quickly (less than 3 seconds), ignoring...")
            resetTimer()
            return
        }
        
        print("⏱️ Timer stopped with duration: \(timeString(from: duration))")

        let session = Session(context: viewContext)
        session.id = UUID()
        session.date = Date()
        session.duration = duration
        session.mode = selectedMode.rawValue
        session.commute = commute

        // Check if this is a PR
        let isPRTime = isPR(duration, forMode: selectedMode.rawValue)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showingPRCelebration = false
                }
                celebrationOffset = UIScreen.main.bounds.width
            }
        }

        try? viewContext.save()
        resetTimer()
    }

    func isPR(_ duration: TimeInterval, forMode mode: String) -> Bool {
        // Don't count zero durations
        if duration < 1 {
            return false
        }
        
        // Get all previous sessions for this commute
        let previousSessions = (commute.sessions as? Set<Session>)?.filter { 
            // Filter out sessions with 0 duration and future dates
            ($0.duration > 0) && 
            ($0.date ?? Date() < Date())
        } ?? []
        
        print("📊 Previous sessions count: \(previousSessions.count)")
        print("📊 Current duration: \(timeString(from: duration))")
        if !previousSessions.isEmpty {
            let bestTime = previousSessions.map { $0.duration }.min() ?? Double.infinity
            print("📊 Best previous time: \(timeString(from: bestTime))")
            print("📊 All previous times:")
            previousSessions.forEach { session in
                print("   - \(timeString(from: session.duration)) (\(session.mode ?? "unknown"))")
            }
            
            // A new PR is when the current duration is LESS than or EQUAL TO the best time
            let isPR = duration <= bestTime
            print("🎯 Current time (\(timeString(from: duration))) <= Best time (\(timeString(from: bestTime)))? \(isPR)")
            return isPR
        }
        
        // If this is the first valid session for this commute, it's automatically a PR
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

    private func modeIcon(for mode: String) -> String {
        switch mode.lowercased() {
        case "bike":
            return "bicycle"
        case "run":
            return "figure.run"
        case "subway":
            return "tram.fill"
        case "bike + subway":
            return "bicycle"  // Using bike icon for combined mode
        default:
            return "questionmark.circle"
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

    private func toggleMode(_ mode: CommuteMode) {
        if selectedModes.contains(mode) {
            selectedModes.remove(mode)
        } else {
            selectedModes.insert(mode)
        }
    }
}
