import SwiftUI

struct NewCommuteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var errorHandler = ErrorHandlingViewModel()
    
    @State private var name = ""
    @State private var mode = CommuteMode.subway
    
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
                    Menu {
                        Picker("Transportation Mode", selection: $mode) {
                            ForEach(CommuteMode.allCases) { option in
                                Label {
                                    Text(option.rawValue.capitalized)
                                } icon: {
                                    Image(systemName: modeIcon(for: option.rawValue))
                                }
                                .tag(option)
                            }
                        }
                    } label: {
                        HStack {
                            Label {
                                Text(mode.rawValue.capitalized)
                            } icon: {
                                Image(systemName: modeIcon(for: mode.rawValue))
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
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
        newCommute.mode = mode.rawValue
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorHandler.handle(error)
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
