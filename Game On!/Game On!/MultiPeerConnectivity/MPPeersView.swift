import SwiftUI
import MultipeerConnectivity

struct MPPeersView: View {
    @EnvironmentObject var connectionManager: MPConnectionManager
    @EnvironmentObject var game: GameService
    @State private var navigateToLobby: Bool = false
    @State private var isLeader: Bool = false
    @State private var selectedLeader: MCPeerID? = nil
    @State private var showConnecting: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text("Available Players")
                        .font(.title)
                        .foregroundStyle(.foregroundButCol)
                        .padding(.bottom, 10)
                    
                    if showConnecting {
                        VStack {
                            ProgressView()
                                .padding()
                            Text("Connecting to game...")
                                .foregroundStyle(.foregroundButCol)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        List(connectionManager.availablePeers, id: \.self) { peer in
                            HStack {
                                Text(peer.displayName)
                                    .foregroundStyle(.black)
                                Spacer()
                                Button("Select") {
                                    // Store the leader's information
                                    selectedLeader = peer
                                    let context = "\(connectionManager.myPeerId.displayName) wants to join your game."
                                    connectionManager.nearbyServiceBrowser.invitePeer(
                                        peer,
                                        to: connectionManager.session,
                                        withContext: context.data(using: .utf8),
                                        timeout: 30
                                    )
                                    // This user will be a regular member, not a leader
                                    isLeader = false
                                    showConnecting = true
                                    print("Selected leader: \(peer.displayName)")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.button)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(.bgCol)
                    }
                }
                .background(.bgCol)
                .font(.title3)
                .foregroundStyle(.foregroundButCol)
                .fontWeight(.bold)
            }
            .onAppear {
                connectionManager.startBrowsing()
                // Reset the navigation flag
                navigateToLobby = false
            }
            .onDisappear {
                connectionManager.invitationHandler?(false, nil)
                connectionManager.stopBrowsing()
                // Don't reset connection state here, as it might disrupt the pairing
                // connectionManager.resetConnectionState()
            }
            // Use timer to check paired status to avoid race conditions
            .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                if connectionManager.paired && !navigateToLobby {
                    // Make sure to save the selected leader in the connection manager for reference
                    if let leader = selectedLeader {
                        connectionManager.receivedInviteFrom = leader
                        print("Saved leader in connection manager: \(leader.displayName)")
                    }
                    navigateToLobby = true // Trigger navigation once paired
                    print("Connection established, navigating to CreateGameView as \(isLeader ? "leader" : "member")")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .connectionEstablished)) { _ in
                // Connection established, navigate to lobby
                if !navigateToLobby {
                    navigateToLobby = true
                    print("📱 Received connection established notification, navigating to lobby...")
                }
            }
            .navigationDestination(isPresented: $navigateToLobby) {
                CreateGameView(isLeader: isLeader) // Navigate to CreateGameView when paired
            }
        }
    }
}

#Preview {
    MPPeersView()
        .environmentObject(MPConnectionManager(yourName: "Sample"))
        .environmentObject(GameService())
}
