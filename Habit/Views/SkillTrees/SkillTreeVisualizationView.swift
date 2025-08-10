import SwiftUI

struct SkillTreeVisualizationView: View {
    @ObservedObject var skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    
    // Debug state
    @State private var showDebugMode = false
    @State private var showLayoutGuides = false
    @State private var levelHeights: [Int: CGFloat] = [:]
    
    var rootNode: SkillNode? {
        skillTree.nodes.filter { $0.isRootNode }.sorted { $0.order < $1.order }.first
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Tree Structure")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Debug controls
            HStack {
                Button(showDebugMode ? "Hide Debug" : "Show Debug") {
                    showDebugMode.toggle()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(showDebugMode ? Color.orange : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(4)
                
                Button(showLayoutGuides ? "Hide Guides" : "Show Guides") {
                    showLayoutGuides.toggle()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(showLayoutGuides ? Color.purple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(4)
                
                Spacer()
            }
            
            // Single root node tree visualization
            if let root = rootNode {
                NestedNodeView(node: root, onNodeTap: onNodeTap, onNodeLongPress: onNodeTap)
                    .environment(\.levelHeightMap, levelHeights)
                    .onPreferenceChange(LevelHeightPreferenceKey.self) { heights in
                        levelHeights = heights
                    }
                    .overlay(
                        // Layout guides overlay
                        Group {
                            if showLayoutGuides {
                                GeometryReader { geometry in
                                    Path { path in
                                        // Center line
                                        path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                                        path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                                        
                                        // Horizontal guides
                                        for i in 1...5 {
                                            let y = geometry.size.height * CGFloat(i) / 6
                                            path.move(to: CGPoint(x: 0, y: y))
                                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                        }
                                    }
                                    .stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                }
                            }
                        }
                    )
            } else {
                Text("No root node found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical)
        .background(
            // Debug background
            Group {
                if showDebugMode {
                    Color.yellow.opacity(0.1)
                }
            }
        )
    }
}

#Preview {
    SkillTreeVisualizationView(skillTree: SkillTree.example) { _ in }
        .environmentObject(DataController())
} 