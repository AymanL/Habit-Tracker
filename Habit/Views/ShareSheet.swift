import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onDismiss: (() -> Void)?
    
    init(items: [Any], onDismiss: (() -> Void)? = nil) {
        self.items = items
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 

// struct ShareSheet: UIViewControllerRepresentable {
//     let items: [Any]
    
//     func makeUIViewController(context: Context) -> UIActivityViewController {
//         print("DEBUG: Creating UIActivityViewController with items: \(items)")
//         let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
//         controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
//             print("DEBUG: Share sheet completed - Activity: \(String(describing: activityType)), Completed: \(completed), Error: \(String(describing: error))")
//         }
//         return controller
//     }
    
//     func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
//         print("DEBUG: Updating UIActivityViewController")
//     }
// } 

/////
// struct ShareSheet: UIViewControllerRepresentable {
//     let items: [Any]
    
//     func makeUIViewController(context: Context) -> UIActivityViewController {
//         let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
//         return controller
//     }
    
//     func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
// }