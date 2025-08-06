import SwiftUI

struct SkillNodeVisualView: View {
    @ObservedObject var node: SkillNode
    let onTap: () -> Void
    
    var nodeTypeIcon: String {
        return node.nodeType.icon
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Node icon
                ZStack {
                    let dailyStatus = node.getDailyCompletionStatus()
                    Circle()
                        .fill(dailyStatus == .notCompleted ? Color.blue : Color.green)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: nodeTypeIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // Node title
                Text(node.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 100)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SkillNodeVisualView(node: SkillNode.example) {
        print("Node tapped")
    }
        .environmentObject(DataController())
} 