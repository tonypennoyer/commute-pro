import SwiftUI

struct CommuteListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var errorHandler = ErrorHandlingViewModel()
    @State private var isEditing = false
    @State private var commuteToDelete: Commute?

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
                .onDelete(perform: confirmDelete)
            }
            .navigationTitle("Commutes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewCommute = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isEditing.toggle() }) {
                        Text(isEditing ? "Done" : "Edit")
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .confirmationDialog(
                "Are you sure you want to delete this commute?",
                isPresented: Binding(
                    get: { commuteToDelete != nil },
                    set: { if !$0 { commuteToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let commute = commuteToDelete {
                        deleteCommute(commute)
                    }
                    commuteToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    commuteToDelete = nil
                }
            } message: {
                Text("This will delete all associated sessions and cannot be undone.")
            }
            
            NavigationView {
                NewCommuteView()
            }
        }
        .handleErrors(errorHandler)
    }
    
    private func confirmDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            commuteToDelete = commutes[index]
        }
    }
    
    private func deleteCommute(_ commute: Commute) {
        withAnimation {
            viewContext.delete(commute)
            do {
                try viewContext.save()
            } catch {
                errorHandler.handle(error)
            }
        }
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
}

