import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ImportSkillTreeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var textInput = ""
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var importResult: ImportResult?
    @State private var showingSuccessNotification = false
    
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
        .overlay(
            // Success notification popup
            Group {
                if showingSuccessNotification, let result = importResult {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        Text("Import Successful!")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("\(result.treesCount) skill tree\(result.treesCount == 1 ? "" : "s") with \(result.nodesCount) node\(result.nodesCount == 1 ? "" : "s") imported")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(showingSuccessNotification ? 1.0 : 0.8)
                    .opacity(showingSuccessNotification ? 1.0 : 0.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSuccessNotification)
                }
            }
        )
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
            showingSuccessNotification = true
            
            // Auto-dismiss after showing success notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
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
        
        // Performance optimization: batch processing variables
        var nodeOrderCounter: Int64 = 0
        var treeOrderCounter: Int64 = 0
        
        // Get initial order values once instead of querying for each entity
        let nodeRequest: NSFetchRequest<SkillNode> = SkillNode.fetchRequest()
        nodeRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SkillNode.order_, ascending: false)]
        nodeRequest.fetchLimit = 1
        if let lastNode = try? context.fetch(nodeRequest).first {
            nodeOrderCounter = lastNode.order_ + 1
        }
        
        let treeRequest: NSFetchRequest<SkillTree> = SkillTree.fetchRequest()
        treeRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SkillTree.order_, ascending: false)]
        treeRequest.fetchLimit = 1
        if let lastTree = try? context.fetch(treeRequest).first {
            treeOrderCounter = lastTree.order_ + 1
        }
        
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
        var currentWorkingLevel = 1 // Track the level we're currently adding nodes to
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("##") {
                // Level root node (## Level X Root Node Title)
                let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                
                guard !content.isEmpty else {
                    continue
                }
                
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                // Ensure the tree has this level in its maxLevel
                if currentLevel > tree.maxLevel {
                    tree.maxLevel = currentLevel
                }
                
                // Create root node for this level with optimized initialization
                let (parsedName, _) = parseTaggedContent(content, defaultType: .root)
                let rootNode = SkillNode(context: context)
                rootNode.id_ = UUID()
                rootNode.name_ = parsedName
                rootNode.nodeType_ = SkillNodeType.root.rawValue
                rootNode.creationDate_ = Date()
                rootNode.isCompleted_ = false
                rootNode.level_ = Int64(currentLevel)
                rootNode.order_ = 0
                rootNode.tree_ = tree
                
                // Clear the node stack and add this root node
                nodeStack.removeAll()
                nodeStack.append((rootNode, 0)) // Root nodes are at depth 0
                
                currentWorkingLevel = currentLevel // Set the working level to the current root node's level
                currentLevel += 1
                
            } else if line.hasPrefix("#") {
                // Tree name (# Tree Title)
                let content = String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                
                guard !content.isEmpty else {
                    continue
                }
                
                // Create tree with optimized initialization
                let tree = SkillTree(context: context)
                tree.id_ = UUID()
                tree.name_ = content
                tree.description_ = ""
                tree.creationDate_ = Date()
                tree.currentLevel_ = 1
                tree.maxLevel_ = 1
                tree.order_ = treeOrderCounter
                treeOrderCounter += 1
                
                skillTrees.append(tree)
                currentTree = tree
                nodeStack.removeAll()
                currentLevel = 1
                currentWorkingLevel = 1
                
            } else if line.hasPrefix("-") {
                // Regular node with dashes
                let dashCount = line.prefix(while: { $0 == "-" }).count
                let content = String(line.dropFirst(dashCount)).trimmingCharacters(in: .whitespaces)
                
                guard !content.isEmpty else {
                    continue
                }
                
                guard let tree = currentTree else {
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                let (parsedName, nodeType) = parseTaggedContent(content, defaultType: .goal)
                
                // Create node with optimized initialization
                let node = SkillNode(context: context)
                node.id_ = UUID()
                node.name_ = parsedName
                node.nodeType_ = nodeType.rawValue
                node.creationDate_ = Date()
                node.isCompleted_ = false
                node.level_ = Int64(currentWorkingLevel)
                node.order_ = nodeOrderCounter
                node.tree_ = tree
                nodeOrderCounter += 1
                
                // Remove nodes from stack that are at this level or deeper
                nodeStack.removeAll { $0.1 >= dashCount }
                
                // Find parent (the last node with depth = dashCount - 1)
                if let parentInfo = nodeStack.last(where: { $0.1 == dashCount - 1 }) {
                    node.parentNode_ = parentInfo.0
                }
                
                // Add to stack
                nodeStack.append((node, dashCount))
            }
        }
        
        // Verify we created at least one tree
        guard !skillTrees.isEmpty else {
            throw ImportError.invalidFormat("No skill trees were created.")
        }
        
        // Save the context once at the end
        try context.save()
        
        let totalNodes = skillTrees.reduce(0) { sum, tree in 
            sum + (tree.nodes_?.allObjects as? [SkillNode] ?? []).count 
        }
        
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

#Preview {
    ImportSkillTreeView()
        .environmentObject(DataController.preview)
}