import SwiftUI
import Foundation

struct SkillNodeVisualView: View {
    @ObservedObject var node: SkillNode
    let onTap: () -> Void
    let onValidate: () -> Void
    @Environment(\.levelHeightMap) private var levelHeightMap
    
    var nodeTypeIcon: String {
        return node.nodeType.icon
    }
    
    // Normalize the name to avoid hidden newlines / irregular whitespace causing inconsistent wrapping
    private var normalizedName: String {
        var s = node.name
        s = s.replacingOccurrences(of: "\r\n", with: " ")
        s = s.replacingOccurrences(of: "\n", with: " ")
        s = s.replacingOccurrences(of: "\r", with: " ")
        s = s.replacingOccurrences(of: "\t", with: " ")
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking space
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedName: String {
        let name = normalizedName
        if name.count > 100 {
            let prefix = name.prefix(100)
            return String(prefix) + "…"
        }
        return name
    }
    
    // Depth-based title font size: deeper levels render smaller labels
    private var titleFontSize: CGFloat {
        let base: CGFloat = 12 // approximate Caption size
        return max(10, base - CGFloat(node.depth))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                // Icon with gestures: tap validates, long press opens menu
                ZStack {
                    let dailyStatus = node.getDailyCompletionStatus()
                    Circle()
                        .fill(dailyStatus == .notCompleted ? Color.blue : Color.green)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: nodeTypeIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .contentShape(Circle())
                .onTapGesture { onValidate() }
                .onLongPressGesture { onTap() }
                .anchorPreference(key: NodeCenterPreferenceKey.self, value: .center) { anchor in
                    [node.id: anchor]
                }
                .zIndex(1)
                
                // Non-clickable title below icon
                Text(displayedName)
                    .font(.system(size: titleFontSize))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 100)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            // Prevent compression narrower than the icon + horizontal padding (30 + 16)
            .frame(minWidth: 46, alignment: .center)
        }
        // No forced minHeight; let nodes size naturally to their content to avoid extra vertical space
        // .background(
        //     RoundedRectangle(cornerRadius: 8)
        //         .fill(Color(.systemBackground))
        // )
        // .shadow(radius: 2)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .background(
            GeometryReader { geo in
                // Report the content height for this depth, but do not force any view to grow.
                // Parents will use this to align child rows at the same top.
                Color.clear.preference(key: LevelHeightPreferenceKey.self, value: [node.depth: geo.size.height])
            }
        )
    }
}

#Preview {
    SkillNodeVisualView(node: SkillNode.example) {
        print("Node tapped")
    } onValidate: {
        print("Node validated")
    }
        .environmentObject(DataController())
} 
