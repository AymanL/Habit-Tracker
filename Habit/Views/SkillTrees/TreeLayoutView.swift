import SwiftUI

// MARK: - Tree Layout Components

struct TreeLayoutView: View {
    @ObservedObject var skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    
    var rootNode: SkillNode? {
        skillTree.nodes.filter { $0.isRootNode }.sorted { $0.order < $1.order }.first
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if let root = rootNode {
                // Root level - centered horizontally
                CenteredHStack {
                    NodeView(node: root, onNodeTap: onNodeTap)
                }
                
                // Child levels below
                if root.hasChildren {
                    ChildLevelView(parent: root, onNodeTap: onNodeTap)
                }
            } else {
                Text("No root node found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
    }
}

struct CenteredHStack<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Spacer()
            content
            Spacer()
        }
    }
}

struct ChildLevelView: View {
    @ObservedObject var parent: SkillNode
    let onNodeTap: (SkillNode) -> Void
    
    @State private var parentFrame: CGRect = .zero
    @State private var childrenFrames: [UUID: CGRect] = [:]
    
    var sortedChildren: [SkillNode] {
        Array(parent.childNodes).sorted(by: { $0.order < $1.order })
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Horizontal row of children - each centered under its parent
            HStack(spacing: 24) {
                ForEach(sortedChildren, id: \.id) { child in
                    VStack(spacing: 0) {
                        // Vertical connection line from parent to this child
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 2, height: 24)
                        
                        // Child node
                        NodeView(node: child, onNodeTap: onNodeTap)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            childrenFrames[child.id] = geometry.frame(in: .global)
                                        }
                                        .onChange(of: geometry.frame(in: .global)) { newFrame in
                                            childrenFrames[child.id] = newFrame
                                        }
                                }
                            )
                    }
                }
            }
            .overlay(
                // Horizontal connection line
                GeometryReader { geometry in
                    if !sortedChildren.isEmpty {
                        Path { path in
                            let firstChild = sortedChildren.first!
                            let lastChild = sortedChildren.last!
                            
                            if let firstFrame = childrenFrames[firstChild.id],
                               let lastFrame = childrenFrames[lastChild.id] {
                                let startX = firstFrame.midX - geometry.frame(in: .global).minX
                                let endX = lastFrame.midX - geometry.frame(in: .global).minX
                                let centerY = geometry.size.height / 2
                                
                                path.move(to: CGPoint(x: startX, y: centerY))
                                path.addLine(to: CGPoint(x: endX, y: centerY))
                            }
                        }
                        .stroke(Color.gray.opacity(0.6), lineWidth: 2)
                    }
                }
            )
            
            // Recursive child levels
            ForEach(sortedChildren, id: \.id) { child in
                if child.hasChildren {
                    ChildLevelView(parent: child, onNodeTap: onNodeTap)
                }
            }
        }
    }
}

struct NodeView: View {
    @ObservedObject var node: SkillNode
    let onNodeTap: (SkillNode) -> Void
    
    @State private var nodeFrame: CGRect = .zero
    
    var body: some View {
        SkillNodeVisualView(node: node) {
            onNodeTap(node)
        } onValidate: {
            if node.canBeCompleted {
                node.complete()
            } else if node.nodeType == .habitLinked {
                node.completeForToday()
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        nodeFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        nodeFrame = newFrame
                    }
            }
        )
        .overlay(
            // Debug info
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Level: \(node.depth)")
                            .font(.caption2)
                            .padding(2)
                            .background(Color.purple.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(2)
                        
                        Text("Children: \(node.childNodes.count)")
                            .font(.caption2)
                            .padding(2)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(2)
                    }
                }
                Spacer()
            }
            .padding(4)
        )
    }
}

#Preview {
    TreeLayoutView(skillTree: SkillTree.example) { _ in }
        .environmentObject(DataController())
} 