enum CommuteMode: String, CaseIterable, Identifiable {
    case subway, walk, run, bike, drive
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .subway: return "🚇"
        case .walk: return "🚶‍♂️"
        case .run: return "🏃‍♀️"
        case .bike: return "🚴"
        case .drive: return "🚗"
        }
    }
}
