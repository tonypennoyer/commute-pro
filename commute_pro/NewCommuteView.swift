import SwiftUI

struct NewCommuteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var mode = CommuteMode.walk

    var body: some View {
        NavigationView {
            Form {
                TextField("Commute Name", text: $name)
                Picker("Mode", selection: $mode) {
                    ForEach(CommuteMode.allCases) { option in
                        Text("\(option.emoji) \(option.rawValue.capitalized)")
                            .tag(option)
                    }
                }
            }
            .navigationTitle("New Commute")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCommute = Commute(context: viewContext)
                        newCommute.name = name
                        newCommute.mode = mode.rawValue
                        try? viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
