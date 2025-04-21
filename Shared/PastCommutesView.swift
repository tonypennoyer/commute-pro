import SwiftUI
import CoreData

struct PastCommutesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var errorHandler = ErrorHandlingViewModel()
    let commute: Commute
    
    @State private var showingManualEntry = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    @State private var selectedDate = Date()
    
    // Force view to update when sessions change
    @FetchRequest var sessions: FetchedResults<Session>
    
    init(commute: Commute) {
        self.commute = commute
        // Create a fetch request for this commute's sessions
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "commute == %@", commute)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Session.date, ascending: false)]
        _sessions = FetchRequest(fetchRequest: request)
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
                    HStack {
                        Text("Past Commutes")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showingManualEntry = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                    
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
        .handleErrors(errorHandler)
        .sheet(isPresented: $showingManualEntry) {
            NavigationView {
                Form {
                    Section(header: Text("Time")) {
                        HStack {
                            Picker("Hours", selection: $selectedHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Picker("Minutes", selection: $selectedMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Picker("Seconds", selection: $selectedSeconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)s").tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        .padding(.vertical)
                    }
                    
                    Section(header: Text("Date")) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                    }
                }
                .navigationTitle("Add Manual Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingManualEntry = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addManualEntry()
                        }
                    }
                }
            }
            #if os(macOS)
            .frame(minWidth: 300, minHeight: 400)
            #endif
        }
    }
    
    private func deleteSession(_ session: Session) {
        withAnimation {
            viewContext.delete(session)
            do {
                try viewContext.save()
            } catch {
                errorHandler.handle(error)
            }
        }
    }
    
    private func addManualEntry() {
        let duration = TimeInterval(selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds)
        let session = Session(context: viewContext)
        session.id = UUID()
        session.date = selectedDate
        session.duration = duration
        session.mode = commute.mode
        session.commute = commute
        
        do {
            try viewContext.save()
            showingManualEntry = false
            selectedHours = 0
            selectedMinutes = 0
            selectedSeconds = 0
        } catch {
            errorHandler.handle(error)
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
        case "bike + subway": return "bicycle"
        default: return "figure.walk"
        }
    }
    
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }
} 