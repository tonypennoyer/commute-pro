enum CommuteMode: String, CaseIterable, Identifiable {
    case bike = "bike"
    case run = "run"
    case subway = "subway"
    case bikeAndSubway = "Bike + Subway"
    
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .subway: return "🚇"
        case .run: return "🏃‍♀️"
        case .bike: return "🚴"
        case .bikeAndSubway: return ""
        }
    }
    
    var animationEmoji: String {
        switch self {
        case .subway: return "🚇"
        case .run: return "🏃‍♀️"
        case .bike: return "🚴"
        case .bikeAndSubway: return ""  // Start with bike
        }
    }
}
