import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        let height = result.last.map { $0.minY + $0.height } ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for row in rows {
            // Center the row
            let rowWidth = row.maxX
            let rowXOffset = (bounds.width - rowWidth) / 2
            
            for index in 0..<row.indices.count {
                guard index < row.xOffsets.count,
                      index < row.sizes.count,
                      row.indices[index] < subviews.count else {
                    continue
                }
                
                let xPos = row.xOffsets[index] + rowXOffset
                let subviewIndex = row.indices[index]
                subviews[subviewIndex].place(
                    at: CGPoint(x: xPos, y: row.minY),
                    proposal: ProposedViewSize(row.sizes[index])
                )
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var yOffset: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            // Check if adding this item would exceed the row width
            let wouldExceedWidth = currentRow.maxX + spacing + size.width > maxWidth
            
            // Start a new row if current row is not empty and would exceed width
            if !currentRow.isEmpty && wouldExceedWidth {
                currentRow.minY = yOffset
                rows.append(currentRow)
                yOffset += currentRow.height + spacing
                currentRow = Row()
            }
            
            // Add item to current row
            let xOffset = currentRow.isEmpty ? 0 : currentRow.maxX + spacing
            currentRow.add(index: index, size: size, xOffset: xOffset)
        }
        
        // Add the last row if it's not empty
        if !currentRow.isEmpty {
            currentRow.minY = yOffset
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var indices: [Int] = []
        var sizes: [CGSize] = []
        var xOffsets: [CGFloat] = []
        var minY: CGFloat = 0
        
        var height: CGFloat {
            sizes.map(\.height).max() ?? 0
        }
        
        var maxX: CGFloat {
            guard let lastOffset = xOffsets.last,
                  let lastSize = sizes.last else { return 0 }
            return lastOffset + lastSize.width
        }
        
        var isEmpty: Bool {
            indices.isEmpty
        }
        
        mutating func add(index: Int, size: CGSize, xOffset: CGFloat) {
            indices.append(index)
            sizes.append(size)
            xOffsets.append(xOffset)
        }
    }
} 