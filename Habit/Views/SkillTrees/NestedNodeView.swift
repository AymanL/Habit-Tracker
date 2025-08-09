import SwiftUI

// MARK: - Per-Level Height Sharing

struct LevelHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        let incoming = nextValue()
        for (level, height) in incoming {
            value[level] = max(value[level] ?? 0, height)
        }
    }
}

private struct LevelHeightMapKey: EnvironmentKey {
    static let defaultValue: [Int: CGFloat] = [:]
}

extension EnvironmentValues {
    var levelHeightMap: [Int: CGFloat] {
        get { self[LevelHeightMapKey.self] }
        set { self[LevelHeightMapKey.self] = newValue }
    }
}

// MARK: - Node Center Preference (for connector lines)

struct NodeCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: Anchor<CGPoint>] = [:]
    
    static func reduce(value: inout [UUID: Anchor<CGPoint>], nextValue: () -> [UUID: Anchor<CGPoint>]) {
        value.merge(nextValue()) { current, new in current }
    }
}

// MARK: - Per-Level Height Sharing

struct LevelHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        let incoming = nextValue()
        for (level, height) in incoming {
            value[level] = max(value[level] ?? 0, height)
        }
    }
}

private struct LevelHeightMapKey: EnvironmentKey {
    static let defaultValue: [Int: CGFloat] = [:]
}

extension EnvironmentValues {
    var levelHeightMap: [Int: CGFloat] {
        get { self[LevelHeightMapKey.self] }
        set { self[LevelHeightMapKey.self] = newValue }
    }
}

// MARK: - Node Center Preference (for connector lines)

struct NodeCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: Anchor<CGPoint>] = [:]
    
    static func reduce(value: inout [UUID: Anchor<CGPoint>], nextValue: () -> [UUID: Anchor<CGPoint>]) {
        value.merge(nextValue()) { current, new in current }
    }
}

struct NestedNodeView: View {
    @ObservedObject var node: SkillNode
    let onNodeTap: (SkillNode) -> Void
    @Environment(\.levelHeightMap) private var levelHeightMap
    @Environment(\.levelHeightMap) private var levelHeightMap
    
    // Debug state
    @State private var showDebugInfo = false
    @State private var nodeFrame: CGRect = .zero
    
    var body: some View {
        VStack() {
            // Current node
            SkillNodeVisualView(node: node) {
                onNodeTap(node)
            } onValidate: {
                // Toggle completion on tap
                switch node.nodeType {
                case .goal, .activity, .boss:
                    if node.isCompleted { node.uncompleteForToday() } else { node.complete() }
                case .habitLinked:
                    if node.isCompletedForToday() { node.uncompleteForToday() } else { node.completeForToday() }
                case .root:
                    break
                }
                try? node.managedObjectContext?.save()
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
            
            // Children (if any) - non-boss on first row, boss on second row
            if node.hasChildren {
                let sortedChildren = Array(node.childNodes).sorted(by: { $0.order < $1.order })
                let nonBossChildren = sortedChildren.filter { $0.nodeType != .boss }
                let bossChildren = sortedChildren.filter { $0.nodeType == .boss }

                VStack(spacing: 0) {
                    if !nonBossChildren.isEmpty {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(nonBossChildren, id: \.id) { childNode in
                                // Align children tops and prevent each child from stretching horizontally
                                NestedNodeView(node: childNode, onNodeTap: onNodeTap)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .background(showDebugInfo ? Color.orange.opacity(0.08) : Color.clear)
                        .frame(alignment: nonBossChildren.count == 1 ? .center : .leading)
                    }

                    if !bossChildren.isEmpty {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(bossChildren, id: \.id) { childNode in
                                NestedNodeView(node: childNode, onNodeTap: onNodeTap)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .background(showDebugInfo ? Color.purple.opacity(0.08) : Color.clear)
                        .frame(alignment: bossChildren.count == 1 ? .center : .leading)
                    }
                }
            }
        }
        // Debug visuals
        .if(Constants.debugSkillTreeUI) { view in
            view
                .border(Color.red, width: 2)
                .background(Color.blue.opacity(0.1))
        }
        .if(Constants.debugSkillTreeUI) { view in
            view.background(
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
        }
        .backgroundPreferenceValue(NodeCenterPreferenceKey.self) { centers in
            GeometryReader { proxy in
                Path { path in
                    guard let parentAnchor = centers[node.id] else { return }
                    let parentPoint = proxy[parentAnchor]
                    let sortedChildren = Array(node.childNodes).sorted(by: { $0.order < $1.order })
                    let childPoints: [CGPoint] = sortedChildren.compactMap { centers[$0.id] }.map { proxy[$0] }
                    guard !childPoints.isEmpty else { return }
                    let minChildX = childPoints.map { $0.x }.min() ?? parentPoint.x
                    let maxChildX = childPoints.map { $0.x }.max() ?? parentPoint.x
                    let minChildY = childPoints.map { $0.y }.min() ?? parentPoint.y
                    let junctionY = (parentPoint.y + minChildY) / 2.0
                    path.move(to: parentPoint)
                    path.addLine(to: CGPoint(x: parentPoint.x, y: junctionY))
                    path.move(to: CGPoint(x: minChildX, y: junctionY))
                    path.addLine(to: CGPoint(x: maxChildX, y: junctionY))
                    for cp in childPoints {
                        path.move(to: CGPoint(x: cp.x, y: junctionY))
                        path.addLine(to: cp)
                    }
                }
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
            }
        }
        .onAppear {
            // Comprehensive tree debugging
            print("🌳 === TREE DISPLAY DEBUG ===")
            print("📋 Current Node: '\(node.name)'")
            print("   ├─ Parent: '\(node.parentNode?.name ?? "none")'")
            print("   ├─ Tree: '\(node.tree?.name ?? "none")'")
            print("   ├─ Order: \(node.order)")
            print("   ├─ Type: \(node.nodeType)")
            print("   ├─ Has Children: \(node.hasChildren)")
            print("   ├─ Children Count: \(node.childNodes.count)")
            print("   └─ Depth: \(node.depth)")
            
            if node.hasChildren {
                print("   👶 Children:")
                let sortedChildren = Array(node.childNodes).sorted(by: { $0.order < $1.order })
                for (index, child) in sortedChildren.enumerated() {
                    print("      \(index + 1). '\(child.name)' (Order: \(child.order), Type: \(child.nodeType))")
                }
            }
            
            // If this is a root node, show the entire tree structure
            if node.parentNode == nil {
                print("🌱 === ROOT NODE DETECTED - SHOWING FULL TREE ===")
                printTreeStructure(node: node, level: 0)
            }
            
            print("🌳 === END TREE DISPLAY DEBUG ===")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            showDebugInfo.toggle()
            print("🔎 Debug overlay for '\(node.name)' \(showDebugInfo ? "ON" : "OFF")")
        }
    }
    
    // Helper function to print the complete tree structure
    private func printTreeStructure(node: SkillNode, level: Int) {
        let indent = String(repeating: "   ", count: level)
        let prefix = level == 0 ? "🌳" : "├─"
        
        print("\(indent)\(prefix) '\(node.name)' (Order: \(node.order), Type: \(node.nodeType), Children: \(node.childNodes.count))")
        
        let sortedChildren = Array(node.childNodes).sorted(by: { $0.order < $1.order })
        for (index, child) in sortedChildren.enumerated() {
            let isLast = index == sortedChildren.count - 1
            let childPrefix = isLast ? "└─" : "├─"
            print("\(indent)   \(childPrefix) '\(child.name)' (Order: \(child.order), Type: \(child.nodeType), Children: \(child.childNodes.count))")
            
            if child.hasChildren {
                printTreeStructure(node: child, level: level + 2)
            }
        }
    }
}

#Preview {
    NestedNodeView(node: SkillNode.example, onNodeTap: { _ in })
        .environmentObject(DataController())
} 
