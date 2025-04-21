import SwiftUI

struct NewCommuteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var errorHandler = ErrorHandlingViewModel()
    
    @State private var name = ""
    
    private var capitalizedNameBinding: Binding<String> {
        Binding(
            get: { name },
            set: { newValue in
                name = newValue.split(separator: " ")
                    .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                    .joined(separator: " ")
            }
        )
    }
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Commute Details")) {
                    TextField("Name", text: capitalizedNameBinding)
                }
            }
            #if os(macOS)
            .listStyle(.inset)
            #else
            .listStyle(.insetGrouped)
            #endif
            .padding()
        }
        .navigationTitle("New Commute")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    saveCommute()
                }
                .disabled(name.isEmpty)
            }
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 200)
        #endif
        .handleErrors(errorHandler)
    }
    
    private func saveCommute() {
        let newCommute = Commute(context: viewContext)
        newCommute.name = name
        newCommute.mode = CommuteMode.subway.rawValue // Default to subway mode
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorHandler.handle(error)
        }
    }
}
