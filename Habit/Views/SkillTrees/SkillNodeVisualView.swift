import SwiftUI

struct SkillNodeVisualView: View {
    @ObservedObject var node: SkillNode
    let onTap: () -> Void
    @Environment(\.levelHeightMap) private var levelHeightMap
    
    var nodeTypeIcon: String {
        return node.nodeType.icon
    }
    
    private var displayedName: String {
        let name = node.name
        if name.count > 100 {
            let prefix = name.prefix(100)
            return String(prefix) + "…"
        }
        return name
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                // Clickable icon only
                Button(action: onTap) {
                    ZStack {
                        let dailyStatus = node.getDailyCompletionStatus()
                        Circle()
                            .fill(dailyStatus == .notCompleted ? Color.blue : Color.green)
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: nodeTypeIcon)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .anchorPreference(key: NodeCenterPreferenceKey.self, value: .center) { anchor in
                    [node.id: anchor]
                }
                .buttonStyle(PlainButtonStyle())
                .zIndex(1)
                
                // Non-clickable title below icon
                Text(displayedName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 100)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
        }
        .frame(minHeight: levelHeightMap[node.depth] ?? 0)
        // .background(
        //     RoundedRectangle(cornerRadius: 8)
        //         .fill(Color(.systemBackground))
        // )
        // .shadow(radius: 2)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: LevelHeightPreferenceKey.self, value: [node.depth: geo.size.height])
            }
        )
    }
}

#Preview {
    SkillNodeVisualView(node: SkillNode.example) {
        print("Node tapped")
    }
        .environmentObject(DataController())
} 
