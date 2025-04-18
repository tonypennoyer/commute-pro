import Foundation

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