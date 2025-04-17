import SwiftUI

struct CommuteListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Commute.name, ascending: true)],
        animation: .default)
    private var commutes: FetchedResults<Commute>

    @State private var showingNewCommute = false

    var body: some View {
        NavigationView {
            List {
                ForEach(commutes, id: \.self) { commute in
                    NavigationLink(destination: CommuteDetailView(commute: commute)) {
                        HStack(spacing: 16) {
                            Image(systemName: modeIcon(for: commute.mode ?? ""))
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(commute.name ?? "Unnamed Commute")
                                    .font(.headline)
                                Text(commute.mode?.capitalized ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteCommutes)
            }
            .navigationTitle("My Commutes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewCommute = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewCommute) {
                NavigationView {
                    NewCommuteView()
                }
            }
        }
    }
    
    private func deleteCommutes(offsets: IndexSet) {
        withAnimation {
            offsets.map { commutes[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
    
    private func modeIcon(for mode: String) -> String {
        switch mode.lowercased() {
        case "walk": return "figure.walk"
        case "bike": return "bicycle"
        case "car": return "car"
        case "subway": return "tram"
        case "bus": return "bus"
        default: return "figure.walk"
        }
    }
}
