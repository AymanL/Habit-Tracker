import SwiftUI

struct SkillTreeCoreGraphicsView: View {
    @ObservedObject var skillTree: SkillTree
    
    // Layout constants
    let nodeRadius: CGFloat = 30
    let verticalSpacing: CGFloat = 100
    let horizontalSpacing: CGFloat = 120
    
    var rootNode: SkillNode? {
        skillTree.nodes.first(where: { $0.isRootNode })
    }
    
    var childNodes: [SkillNode] {
        rootNode?.childNodes.sorted(by: { $0.order < $1.order }) ?? []
    }
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard let root = rootNode else { return }
                let centerX = size.width / 2
                let rootY = nodeRadius + 20
                
                // Draw root node
                let rootCenter = CGPoint(x: centerX, y: rootY)
                drawNode(context: &context, at: rootCenter, label: root.name)
                
                // Draw children
                let count = max(childNodes.count, 1)
                let totalWidth = CGFloat(count - 1) * horizontalSpacing
                for (i, child) in childNodes.enumerated() {
                    let childX = centerX - totalWidth / 2 + CGFloat(i) * horizontalSpacing
                    let childY = rootY + verticalSpacing
                    let childCenter = CGPoint(x: childX, y: childY)
                    
                    // Draw line from root to child
                    var path = Path()
                    path.move(to: rootCenter)
                    path.addLine(to: childCenter)
                    context.stroke(path, with: .color(.gray), lineWidth: 2)
                    
                    // Draw child node
                    drawNode(context: &context, at: childCenter, label: child.name)
                }
            }
        }
        .frame(minHeight: 300)
        .background(Color(.systemBackground))
    }
    
    func drawNode(context: inout GraphicsContext, at center: CGPoint, label: String) {
        let rect = CGRect(x: center.x - nodeRadius, y: center.y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)
        context.fill(Ellipse().path(in: rect), with: .color(.blue))
        
        let text = Text(label)
            .font(.caption)
            .foregroundColor(.white)
        context.draw(text, at: CGPoint(x: center.x, y: center.y + nodeRadius + 12), anchor: .center)
    }
}