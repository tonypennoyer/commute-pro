import SwiftUI

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

    var body: some View {
        VStack(spacing: 16) {
            Text(commute.name ?? "")
                .font(.title)

            Text("Mode: \(commute.mode ?? "")")
                .foregroundColor(.gray)

            Text(timeString(from: elapsedTime))
                .font(.largeTitle)

            Button(isRunning ? "Stop" : "Start") {
                isRunning ? stopTimer() : startTimer()
            }
            .font(.headline)

            Divider()

            Text("Average Time: \(timeString(from: averageTime))")
                .font(.subheadline)

            List {
                ForEach(sessions, id: \.self) { session in
                    VStack(alignment: .leading) {
                        Text("Time: \(timeString(from: session.duration))")
                        if let date = session.date {
                            Text("Date: \(dateFormatter.string(from: date))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
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

    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }
}
