import SwiftUI

public struct StatView: View {
    public let title: String
    public let value: String
    public let subtitle: String?
    
    public init(title: String, value: String, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity)
    }
} 