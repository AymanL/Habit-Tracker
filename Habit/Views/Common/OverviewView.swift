import SwiftUI

struct OverviewView: View {
    var title: String
    var mainText: String
    var secondaryText1: String
    var secondaryText2: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title3.bold())
            HStack() {
                VStack(alignment: .leading) {
                    VStack() {
                        Text(mainText)
                            .font(.system(size: 50).bold())
                    }
                    HStack {
                        Text(secondaryText1)
                            .padding(.trailing, 60)
                        Text(secondaryText2)
                    }
                }
                .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding()
    }
} 