import SwiftUI

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let commute: Commute
    
    var sessions: [Session] {
        (commute.sessions as? Set<Session>)?.sorted { $0.date ?? Date() > $1.date ?? Date() } ?? []
    }
    
    var averageTime: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.duration }
        return total / Double(sessions.count)
    }
    
    var bestTime: TimeInterval {
        sessions.map { $0.duration }.min() ?? 0
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
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatView(title: "average", value: timeString(from: averageTime))
                    StatView(title: "commutes", value: "\(sessions.count)")
                    StatView(title: "best", value: timeString(from: bestTime))
                }
                .padding()
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Past Commutes Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Past Commutes")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(sessions, id: \.self) { session in
                            HStack {
                                Image(systemName: modeIcon(for: session.mode ?? "walk"))
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30)
                                
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
            }
            .padding()
        }
        .navigationTitle("Stats")
    }
    
    private func deleteSession(_ session: Session) {
        withAnimation {
            viewContext.delete(session)
            try? viewContext.save()
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func modeIcon(for mode: String) -> String {
        switch mode.lowercased() {
        case "walk": return "figure.walk"
        case "bike": return "bicycle"
        case "run": return "figure.run"
        case "subway": return "tram.fill"
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