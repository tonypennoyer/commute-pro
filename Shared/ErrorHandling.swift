import SwiftUI
import CoreData

class ErrorHandlingViewModel: ObservableObject {
    @Published var error: CoreDataError?
    @Published var showError = false
    
    func handle(_ error: Error) {
        if let coreDataError = error as? CoreDataError {
            self.error = coreDataError
        } else {
            self.error = .savingError(error)
        }
        self.showError = true
    }
}

struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandlingViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showError) {
                Button("OK", role: .cancel) {
                    errorHandler.showError = false
                }
            } message: {
                if let error = errorHandler.error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func handleErrors(_ errorHandler: ErrorHandlingViewModel) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler))
    }
} 