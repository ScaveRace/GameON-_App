import SwiftUI

struct JoinGameView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgCol.edgesIgnoringSafeArea(.all)
                VStack {
                    MPPeersView() // Simplified, no need for startGame here
                }
                .padding(10)
            }
            .navigationTitle(Text("Join Game"))
        }
    }
}

#Preview {
    JoinGameView()
        .environmentObject(MPConnectionManager(yourName: "Fynn"))
}
