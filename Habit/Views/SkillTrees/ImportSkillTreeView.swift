import SwiftUI
import UniformTypeIdentifiers

struct ImportSkillTreeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var textInput = ""
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var importResult: ImportResult?
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            // Wrap main content in a vertical ScrollView so the view is scrollable
            ScrollView {
                VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Import Skill Trees")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Import skill trees from a text file")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
                
                // Format instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Format:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• # = Tree name (container only)")
                        Text("• ## = Level root node (actual node)")
                        Text("• 1+ dashes = Regular nodes within level")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Example
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("""
                        # Programming Skills
                        ## Learn Swift Fundamentals
                        - Basic Syntax
                        -- Variables and Constants
                        -- Data Types
                        - Control Flow
                        -- If Statements
                        -- Loops
                        ## Build First App
                        - UI Design
                        -- Interface Builder
                        -- Auto Layout
                        - Data Management
                        -- Core Data
                        
                        # Fitness Goals
                        ## Cardio Foundation
                        - Running
                        -- 5K Run
                        -- 10K Run
                        - Swimming
                        ## Strength Building
                        - Push Exercises
                        - Pull Exercises
                        """)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
                
                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Input Method:")
                        .font(.headline)
                    
                    // Input buttons
                    HStack(spacing: 16) {
                        Button(action: { showingFilePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.title2)
                                Text("Choose File")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBlue))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Clear and focus on text input
                            textInput = ""
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "text.cursor")
                                    .font(.title2)
                                Text("Type Text")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGreen))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Text input area
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or paste text directly:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $textInput)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(minHeight: 150)
                            
                            if textInput.isEmpty {
                                Text("Paste your skill tree structure here...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { 
                        performImport()
                    }) {
                        Text("Import Skill Trees")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    loadTextFromFile(file)
                }
            case .failure(let error):
                alertTitle = "File Error"
                alertMessage = "Could not read file: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPreview) {
            if let result = importResult {
                ImportResultView(result: result) {
                    dismiss()
                }
            }
        }
    }
    
    private func loadTextFromFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            alertTitle = "Access Error"
            alertMessage = "Unable to access the selected file"
            showingAlert = true
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            textInput = content
        } catch {
            alertTitle = "Read Error"
            alertMessage = "Could not read file content: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func performImport() {
        let trimmedInput = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty else {
            alertTitle = "Empty Input"
            alertMessage = "Please provide some text to import"
            showingAlert = true
            return
        }
        
        do {
            let result = try parseAndImportSkillTrees(trimmedInput)
            importResult = result
            showingPreview = true
        } catch let error as ImportError {
            alertTitle = "Import Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        } catch {
            alertTitle = "Unexpected Error"
            alertMessage = "An unexpected error occurred: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func parseAndImportSkillTrees(_ text: String) throws -> ImportResult {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        
        // Check that we have at least one tree (starts with #)
        let hasTreeLine = lines.contains { $0.hasPrefix("#") && !$0.hasPrefix("##") }
        guard hasTreeLine else {
            throw ImportError.invalidFormat("At least one skill tree name (starting with #) is required.")
        }
        
        var skillTrees: [SkillTree] = []
        var currentTree: SkillTree?
        var nodeStack: [(SkillNode, Int)] = []
        
        let context = dataController.container.viewContext
        
        print("🔄 Starting line-by-line processing...")
        
        func parseTaggedContent(_ raw: String, defaultType: SkillNodeType) -> (String, SkillNodeType) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("["), let close = trimmed.firstIndex(of: "]") else {
                return (trimmed, defaultType)
            }
            let tagRange = trimmed.index(after: trimmed.startIndex)..<close
            let tag = String(trimmed[tagRange]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let remainder = trimmed.index(after: close)..<trimmed.endIndex
            let name = String(trimmed[remainder]).trimmingCharacters(in: .whitespaces)
            let mapping: [String: SkillNodeType] = [
                "goal": .goal,
                "g": .goal,
                "action": .activity,
                "activity": .activity,
                "a": .activity,
                "boss": .boss,
                "boss fight": .boss,
                "bossfight": .boss
            ]
            let type = mapping[tag] ?? defaultType
            return (name.isEmpty ? trimmed : name, type)
        }

        var currentLevel = 1
        
        for (index, line) in lines.enumerated() {
            print("📄 Processing line \(index + 1): '\(line)'")
            
            if line.hasPrefix("##") {
                // Level root node (## Level X Root Node Title)
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                
                guard !content.isEmpty else {
                    print("  ⏭️ Skipping empty level root content")
                    continue
                }
                
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for level root node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  🏛️ Creating level \(currentLevel) root node: '\(content)'")
                
                // Ensure the tree has this level in its maxLevel
                if currentLevel > tree.maxLevel {
                    tree.maxLevel = currentLevel
                    print("  📈 Updated tree maxLevel to \(currentLevel)")
                }
                
                // Create root node for this level
                let (parsedName, _) = parseTaggedContent(content, defaultType: .root)
                let rootNode = SkillNode(context: context, name: parsedName, type: .root)
                rootNode.tree = tree
                rootNode.level = currentLevel
                rootNode.order = 0
                
                // Clear the node stack and add this root node
                nodeStack.removeAll()
                nodeStack.append((rootNode, 0)) // Root nodes are at depth 0
                
                print("  ✅ Level \(currentLevel) root node created")
                currentLevel += 1
                
            } else if line.hasPrefix("#") {
                // Tree name (# Tree Title)
                let content = String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                
                guard !content.isEmpty else {
                    print("  ⏭️ Skipping empty tree content")
                    continue
                }
                
                print("  🌳 Creating new skill tree: '\(content)'")
                let tree = SkillTree(context: context, name: content, description: "")
                skillTrees.append(tree)
                currentTree = tree
                nodeStack.removeAll()
                currentLevel = 1
                print("  ✅ Tree created and set as current")
                print("  📊 Current state: \(skillTrees.count) trees")
                
            } else if line.hasPrefix("-") {
                // Regular node with dashes
                let dashCount = line.prefix(while: { $0 == "-" }).count
                let content = String(line.dropFirst(dashCount)).trimmingCharacters(in: .whitespaces)
                
                guard !content.isEmpty else {
                    print("  ⏭️ Skipping empty node content")
                    continue
                }
                
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  🔵 Creating node at depth \(dashCount): '\(content)'")
                
                let (parsedName, nodeType) = parseTaggedContent(content, defaultType: .goal)
                let node = SkillNode(context: context, name: parsedName, type: nodeType)
                node.tree = tree
                
                // Set the level to the current level being processed
                node.level = currentLevel - 1 // currentLevel was incremented after creating root node
                
                // Remove nodes from stack that are at this level or deeper
                nodeStack.removeAll { $0.1 >= dashCount }
                
                // Find parent (the last node with depth = dashCount - 1)
                if let parentInfo = nodeStack.last(where: { $0.1 == dashCount - 1 }) {
                    node.parentNode = parentInfo.0
                    print("  👨‍👩‍👧‍👦 Set parent: '\(parentInfo.0.name)' for '\(parsedName)'")
                } else if dashCount > 1 {
                    print("  ⚠️ No parent found for depth \(dashCount), but depth > 1")
                }
                
                // Add to stack
                nodeStack.append((node, dashCount))
                
                print("  ✅ Node created at level \(node.level) with parent: \(node.parentNode?.name ?? "none")")
                print("  📊 Stack depth: \(nodeStack.count)")
            } else {
                print("  ⚠️ Unrecognized line format: '\(line)'")
            }
        }
        
        // Verify we created at least one tree
        guard !skillTrees.isEmpty else {
            throw ImportError.invalidFormat("No skill trees were created.")
        }
        
        // Save the context
        try context.save()
        
        print("✅ Successfully imported \(skillTrees.count) skill trees")
        
        let totalNodes = skillTrees.reduce(0) { sum, tree in sum + tree.nodes.count }
        
        return ImportResult(
            treesCount: skillTrees.count,
            nodesCount: totalNodes,
            skillTrees: skillTrees
        )
    }
}

struct ImportResult {
    let treesCount: Int
    let nodesCount: Int
    let skillTrees: [SkillTree]
}

enum ImportError: LocalizedError {
    case emptyFile
    case invalidFormat(String)
    case noTreeDefined(lineNumber: Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty or contains no valid content."
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .noTreeDefined(let lineNumber):
            return "Line \(lineNumber): Node defined without a skill tree. Add a tree name (starting with #) first."
        }
    }
}

struct ImportResultView: View {
    let result: ImportResult
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Success header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Import Successful!")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                
                // Statistics
                VStack(spacing: 16) {
                    StatRow(
                        title: "Skill Trees",
                        value: "\(result.treesCount)",
                        icon: "tree"
                    )
                    
                    StatRow(
                        title: "Total Nodes",
                        value: "\(result.nodesCount)",
                        icon: "circle.grid.2x2"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Tree list
                if !result.skillTrees.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Imported Skill Trees:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(result.skillTrees, id: \.id) { tree in
                                    SkillTreePreviewRow(skillTree: tree)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle("Import Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct SkillTreePreviewRow: View {
    let skillTree: SkillTree
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(skillTree.name_ ?? "")
                    .font(.headline)
                
                Spacer()
                
                Text("\(skillTree.totalNodesCount) nodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    ImportSkillTreeView()
        .environmentObject(DataController.preview)
}