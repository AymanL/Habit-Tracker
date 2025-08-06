import SwiftUI

struct NestedNodeView: View {
    @ObservedObject var node: SkillNode
    let onNodeTap: (SkillNode) -> Void
    
    // Debug state
    @State private var showDebugInfo = false
    @State private var nodeFrame: CGRect = .zero
    
    var body: some View {
        VStack() {
            // Current node
            SkillNodeVisualView(node: node) {
                onNodeTap(node)
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
//            .overlay(
//                // Debug overlay - shows node info on long press
//                Group {
//                    if showDebugInfo {
//                        VStack() {
//                            Text("Node: \(node.name)")
//                                .font(.caption)
//                                .padding(4)
//                                .background(Color.black.opacity(0.8))
//                                .foregroundColor(.white)
//                                .cornerRadius(4)
//                            
//                            Text("Size: \(Int(nodeFrame.width))×\(Int(nodeFrame.height))")
//                                .font(.caption2)
//                                .padding(2)
//                                .background(Color.green.opacity(0.8))
//                                .foregroundColor(.white)
//                                .cornerRadius(2)
//                        }
//                        .position(x: 80, y: 30)
//                    }
//                }
//            )
            .onLongPressGesture {
                showDebugInfo.toggle()
            }
            
            // Children (if any) - evenly distributed around parent
            if node.hasChildren {
                let sortedChildren = Array(node.childNodes).sorted(by: { $0.order < $1.order })
                
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(sortedChildren, id: \.id) { childNode in
                            NestedNodeView(node: childNode, onNodeTap: onNodeTap)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
                    .frame(
                        // minWidth: max(
                        //     UIScreen.main.bounds.width,
                        //     CGFloat(sortedChildren.count) * 100 + CGFloat(sortedChildren.count - 1) * 10 // Reasonable minimum space for nodes
                        // ),
                        alignment: sortedChildren.count == 1 ? .center : .leading
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .border(Color.red, width: 2)
        .background(Color.blue.opacity(0.1)) // Debug background
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        print("📐 Node '\(node.name)' bounding box: \(Int(geometry.frame(in: .global).width))×\(Int(geometry.frame(in: .global).height))")
                    }
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        print("📐 Node '\(node.name)' bounding box updated: \(Int(newFrame.width))×\(Int(newFrame.height))")
                    }
            }
        )
        // .overlay(
        //     // Debug info overlay
        //     VStack {
        //         HStack {
        //             Spacer()
        //             VStack(alignment: .trailing, spacing: 2) {
        //                 Text("Children: \(node.childNodes.count)")
        //                     .font(.caption2)
        //                     .padding(2)
        //                     .background(Color.orange.opacity(0.8))
        //                     .foregroundColor(.white)
        //                     .cornerRadius(2)
                        
        //                 Text("Depth: \(node.depth)")
        //                     .font(.caption2)
        //                     .padding(2)
        //                     .background(Color.purple.opacity(0.8))
        //                     .foregroundColor(.white)
        //                     .cornerRadius(2)
        //             }
        //         }
                
        //         Spacer()
                
        //         // Bounding box dimensions
        //         HStack {
        //             Spacer()
        //             VStack(alignment: .trailing, spacing: 2) {
        //                 Text("📐 Bounding Box")
        //                     .font(.caption2)
        //                     .padding(2)
        //                     .background(Color.red.opacity(0.8))
        //                     .foregroundColor(.white)
        //                     .cornerRadius(2)
        //             }
        //         }
        //     }
        //     .padding(4)
        // )
    }
    
    // Helper function to determine if scroll indicators should be shown
    private func shouldShowScrollIndicators(for children: [SkillNode]) -> Bool {
        // Calculate total visual width needed based on actual descendant counts
        let totalWidthNeeded = children.reduce(0) { totalWidth, child in
            let descendants = child.getAllDescendants()
            let estimatedChildWidth = max(100, CGFloat(descendants.count + 1) * 50) // Reasonable base width + space for descendants
            return totalWidth + estimatedChildWidth
        } + CGFloat(children.count - 1) * 10 // Further reduced spacing between children
        
        // Account for nodes with many descendants (they take more space)
        let totalDescendants = children.reduce(0) { count, child in
            count + child.getAllDescendants().count
        }
        
        // If there are many descendants, we likely need scrolling
        let hasManyDescendants = totalDescendants > children.count * 2
        
        // Show indicators if we have many children OR many descendants OR if width exceeds screen
        return children.count > 4 || hasManyDescendants || totalWidthNeeded > UIScreen.main.bounds.width - 40
    }
}

#Preview {
    NestedNodeView(node: SkillNode.example, onNodeTap: { _ in })
        .environmentObject(DataController())
} 
