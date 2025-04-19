import SwiftUI
import CoreData

// MARK: - Error Types
enum CoreDataError: LocalizedError {
    case loadingError(Error)
    case savingError(Error)
    case validationError(String)
    
    var errorDescription: String? {
        switch self {
        case .loadingError(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .savingError(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}

// MARK: - View Model
@MainActor
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

// MARK: - View Modifier
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

// MARK: - View Extension
extension View {
    func handleErrors(_ errorHandler: ErrorHandlingViewModel) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler))
    }
} 