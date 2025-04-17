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
                        HStack {
                            Text(commute.name ?? "Unnamed Commute")
                                .font(.headline)
                            Spacer()
                            Text(commute.mode ?? "")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("My Commutes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewCommute = true }) {
                        Label("Add Commute", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewCommute) {
                NewCommuteView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}
