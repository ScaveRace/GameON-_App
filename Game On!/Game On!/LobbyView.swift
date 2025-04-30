import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var connectionManager: MPConnectionManager
    @EnvironmentObject var game: GameService
    @State private var navigateToGame = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgCol.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Header
                    Text("Game Lobby")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Debug info - useful for troubleshooting
                    Text("Connected peers: \(connectionManager.session.connectedPeers.count)")
                        .foregroundColor(.white)
                    
                    // Players list
                    // In LobbyView.swift, modify the Players list section:

                    // Players list
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Show the leader (host)
                            if connectionManager.session.connectedPeers.isEmpty {
                                // If no connected peers, this must be the leader's view
                                playerRow(name: connectionManager.myPeerId.displayName, role: "Leader")
                            } else {
                                // Show all connected peers
                                ForEach(connectionManager.session.connectedPeers, id: \.self) { peer in
                                    if peer == connectionManager.receivedInviteFrom {
                                        // This is the host that invited us
                                        playerRow(name: peer.displayName, role: "Leader")
                                    } else {
                                        playerRow(name: peer.displayName, role: "Member")
                                    }
                                }
                                
                                // Show this player
                                playerRow(name: connectionManager.myPeerId.displayName, role: connectionManager.receivedInviteFrom == nil ? "Leader" : "Member")
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Text("Waiting for leader to start the game...")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .colorScheme(.dark)
            .navigationDestination(isPresented: $navigateToGame) {
                GameView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .startGame)) { _ in
                navigateToGame = true
            }
            .onAppear {
                // Print debugging info
                print("Connected peers in LobbyView: \(connectionManager.session.connectedPeers.map { $0.displayName })")
            }
        }
    }
    
    private func playerRow(name: String, role: String) -> some View {
        HStack {
            Text(name)
                .foregroundColor(.white)
            Spacer()
            Text(role)
                .foregroundColor(role == "Leader" ? .green : .blue)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}
    
    #Preview {
        LobbyView()
            .environmentObject(MPConnectionManager(yourName: "Sample"))
            .environmentObject(GameService())
    }

