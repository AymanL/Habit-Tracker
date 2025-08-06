import SwiftUI

struct HierarchicalNodeView: View {
    @ObservedObject var node: SkillNode
    let onTap: (SkillNode) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Node with indentation based on depth
            HStack(spacing: 0) {
                // Indentation
                ForEach(0..<node.depth, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 20, height: 1)
                        .padding(.leading, 8)
                }
                
                // Node content
                SkillNodeVisualView(node: node) {
                    onTap(node)
                }
                .padding(.leading, node.depth > 0 ? 8 : 0)
                
                Spacer()
            }
            
            // Children (if any)
            if node.hasChildren {
                VStack(spacing: 0) {
                    ForEach(Array(node.childNodes.sorted(by: { $0.order < $1.order })), id: \.id) { childNode in
                        HierarchicalNodeView(node: childNode, onTap: onTap)
                    }
                }
            }
        }
    }
}

#Preview {
    HierarchicalNodeView(node: SkillNode.example) { _ in }
        .environmentObject(DataController())
} 