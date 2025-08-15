import SwiftUI

struct SkillTreeVisualizationView: View {
    @ObservedObject var skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    
    // Debug state
    @State private var showDebugMode = false
    @State private var showLayoutGuides = false
    @State private var levelHeights: [Int: CGFloat] = [:]
    @State private var showPreviousLevels: Bool = false
    
    var rootNode: SkillNode? {
        skillTree.getRootNodeForLevel(skillTree.currentLevel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Level Progress Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(skillTree.currentLevel) of \(skillTree.maxLevel)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    let progress = skillTree.getCurrentLevelProgress()
                    HStack {
                        Text("\(progress.completed)/\(progress.total) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if skillTree.canUnlockNextLevel() {
                            Text("• Ready to unlock next level!")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                // Level unlock preview
                if skillTree.currentLevel < skillTree.maxLevel {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next Level")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        let nextLevelNodes = skillTree.getNodesForLevel(skillTree.currentLevel + 1)
                        Text("\(nextLevelNodes.count) new goals")
                            .font(.caption)
                            .foregroundColor(skillTree.canUnlockNextLevel() ? .green : .gray)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Debug controls (collapsed)
            if showDebugMode {
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
            }
            
            // Hierarchical tree visualization with level progression
            VStack(spacing: 24) {
                // Show "See more" button for previous levels if there are any
                if skillTree.currentLevel > 1 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPreviousLevels.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: showPreviousLevels ? "chevron.up" : "chevron.down")
                                .font(.caption)
                            Text(showPreviousLevels ? "Hide previous levels" : "See previous levels (\(skillTree.currentLevel - 1))")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // Previous completed levels (collapsible) - lazy loaded
                if showPreviousLevels {
                    LazyVStack(spacing: 16) {
                        CompletedLevelsView(skillTree: skillTree, onNodeTap: onNodeTap, showLayoutGuides: showLayoutGuides, levelHeights: $levelHeights)
                    }
                }
                
                // Current level tree (unlocked)
                if let root = rootNode {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Level \(skillTree.currentLevel) - Current Progress")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
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
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                    )
                    .shadow(radius: 1)
                } else {
                    Text("No root node found")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // Locked future levels - lazy loaded
                LazyVStack(spacing: 16) {
                    LockedLevelsView(skillTree: skillTree, onNodeTap: onNodeTap)
                }
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

// MARK: - Locked Levels View
struct LockedLevelsView: View {
    @ObservedObject var skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    @State private var showAllLevels = false
    
    var lockedLevels: [Int] {
        guard skillTree.maxLevel > skillTree.currentLevel else { return [] }
        return Array((skillTree.currentLevel + 1)...skillTree.maxLevel)
    }
    
    var visibleLevels: [Int] {
        // Performance optimization: only show next 3 levels by default
        if showAllLevels || lockedLevels.count <= 3 {
            return lockedLevels
        } else {
            return Array(lockedLevels.prefix(3))
        }
    }
    
    var body: some View {
        if !lockedLevels.isEmpty {
            VStack(spacing: 16) {
                ForEach(visibleLevels, id: \.self) { level in
                    LockedLevelSection(
                        skillTree: skillTree,
                        level: level,
                        onNodeTap: onNodeTap
                    )
                }
                
                // Show "Show more" button if there are hidden levels
                if lockedLevels.count > 3 && !showAllLevels {
                    Button("Show \(lockedLevels.count - 3) more locked levels") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllLevels = true
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Locked Level Section
struct LockedLevelSection: View {
    @ObservedObject var skillTree: SkillTree
    let level: Int
    let onNodeTap: (SkillNode) -> Void
    
    var levelNodes: [SkillNode] {
        skillTree.getNodesForLevel(level).filter { $0.nodeType != .root }
    }
    
    var rootNode: SkillNode? {
        skillTree.getRootNodeForLevel(level)
    }
    
    var isNextLevel: Bool {
        level == skillTree.currentLevel + 1
    }
    
    var canUnlock: Bool {
        isNextLevel && skillTree.canUnlockNextLevel()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Level header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: canUnlock ? "lock.open.fill" : "lock.fill")
                        .font(.title3)
                        .foregroundColor(canUnlock ? .orange : .gray)
                    
                    Text("Level \(level)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(canUnlock ? .primary : .secondary)
                    
                    if canUnlock {
                        Text("Ready to Unlock!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Text("\(levelNodes.count) goals")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(canUnlock ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundColor(canUnlock ? .orange : .gray)
                    .cornerRadius(8)
            }
            
            // Level content - show the tree structure for this level
            if let root = rootNode {
                // Display the tree structure for this level using NestedNodeView
                // but with locked appearance
                NestedNodeView(node: root, onNodeTap: { _ in }, onNodeLongPress: { _ in })
                    .opacity(0.6)
                    .overlay(
                        // Lock overlay
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.1))
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                    .foregroundColor(.gray.opacity(0.7))
                            )
                    )
            } else if levelNodes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No goals defined for this level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                // Fallback: create a root node if it doesn't exist but nodes do
                VStack(spacing: 8) {
                    Image(systemName: "exclamation.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Level structure needs repair")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(canUnlock ? Color.orange.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canUnlock ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(canUnlock ? 1.0 : 0.7)
    }
    
    private func hasHierarchicalStructure(_ nodes: [SkillNode]) -> Bool {
        // Check if any nodes have parent-child relationships within this level
        return nodes.contains { node in
            nodes.contains { otherNode in
                node.parentNode == otherNode || otherNode.parentNode == node
            }
        }
    }
}

// MARK: - Locked Tree Structure View
struct LockedTreeStructureView: View {
    let nodes: [SkillNode]
    let onNodeTap: (SkillNode) -> Void
    
    var rootLevelNodes: [SkillNode] {
        nodes.filter { node in
            node.parentNode == nil || !nodes.contains(node.parentNode!)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rootLevelNodes) { node in
                LockedNodeHierarchyView(
                    node: node,
                    allLevelNodes: nodes,
                    onNodeTap: onNodeTap
                )
            }
        }
    }
}

// MARK: - Locked Node Hierarchy View
struct LockedNodeHierarchyView: View {
    @ObservedObject var node: SkillNode
    let allLevelNodes: [SkillNode]
    let onNodeTap: (SkillNode) -> Void
    
    var childrenInLevel: [SkillNode] {
        allLevelNodes.filter { $0.parentNode == node }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Current node
            LockedSkillNodeCard(node: node, onNodeTap: onNodeTap, canUnlock: false)
            
            // Children nodes (indented)
            if !childrenInLevel.isEmpty {
                VStack(spacing: 4) {
                    ForEach(childrenInLevel) { child in
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 2, height: 20)
                            
                            LockedSkillNodeCard(node: child, onNodeTap: onNodeTap, canUnlock: false)
                        }
                        .padding(.leading, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Locked Skill Node Card
struct LockedSkillNodeCard: View {
    @ObservedObject var node: SkillNode
    let onNodeTap: (SkillNode) -> Void
    let canUnlock: Bool
    
    var body: some View {
        Button(action: {
            // Locked nodes can't be tapped
        }) {
            HStack(spacing: 12) {
                // Node icon
                Image(systemName: node.nodeType.icon)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                
                // Node info
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    if !node.nodeDescription.isEmpty {
                        Text(node.nodeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Lock icon
                Image(systemName: canUnlock ? "lock.open.fill" : "lock.fill")
                    .font(.caption)
                    .foregroundColor(canUnlock ? .orange : .gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .disabled(true)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completed Levels View
struct CompletedLevelsView: View {
    let skillTree: SkillTree
    let onNodeTap: (SkillNode) -> Void
    let showLayoutGuides: Bool
    @Binding var levelHeights: [Int: CGFloat]
    @State private var showAllLevels = false
    
    var completedLevels: [Int] {
        // All levels before the current level are considered completed
        return Array(1..<skillTree.currentLevel).sorted()
    }
    
    var visibleLevels: [Int] {
        // Performance optimization: only show last 3 levels by default
        if showAllLevels || completedLevels.count <= 3 {
            return completedLevels
        } else {
            return Array(completedLevels.suffix(3))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Show "Show more" button if there are hidden levels
            if completedLevels.count > 3 && !showAllLevels {
                Button("Show \(completedLevels.count - 3) more levels") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllLevels = true
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            
            ForEach(visibleLevels, id: \.self) { level in
                CompletedLevelSection(
                    skillTree: skillTree,
                    level: level,
                    onNodeTap: onNodeTap,
                    showLayoutGuides: showLayoutGuides,
                    levelHeights: $levelHeights
                )
            }
        }
    }
}

// MARK: - Completed Level Section
struct CompletedLevelSection: View {
    let skillTree: SkillTree
    let level: Int
    let onNodeTap: (SkillNode) -> Void
    let showLayoutGuides: Bool
    @Binding var levelHeights: [Int: CGFloat]
    
    var rootNode: SkillNode? {
        skillTree.getRootNodeForLevel(level)
    }
    
    var body: some View {
        if let root = rootNode {
            VStack(spacing: 16) {
                HStack {
                    Text("Level \(level)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
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
                    .opacity(0.8) // Slightly dimmed to show it's completed
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.4), lineWidth: 2)
                    )
            )
            .shadow(radius: 1)
        }
    }
}

#Preview {
    SkillTreeVisualizationView(skillTree: SkillTree.example) { _ in }
        .environmentObject(DataController())
} 