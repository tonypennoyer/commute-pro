import SwiftUI

struct NewCommuteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var mode = CommuteMode.walk
    
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
                
                Section(header: Text("Transportation")) {
                    Picker("Transportation Mode", selection: $mode) {
                        ForEach(CommuteMode.allCases) { option in
                            Label("\(option.rawValue.capitalized)", systemImage: modeIcon(for: option.rawValue))
                                .tag(option)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.inline)
                    #endif
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
    }
    
    private func saveCommute() {
        let newCommute = Commute(context: viewContext)
        newCommute.name = name
        newCommute.mode = mode.rawValue
        try? viewContext.save()
        dismiss()
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
