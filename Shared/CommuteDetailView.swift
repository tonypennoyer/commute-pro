import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct CommuteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var commute: Commute

    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

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
                }
                .padding(.vertical)
                
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
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
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

        let session = Session(context: viewContext)
        session.id = UUID()
        session.date = Date()
        session.duration = duration
        session.commute = commute

        try? viewContext.save()
        elapsedTime = 0
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
