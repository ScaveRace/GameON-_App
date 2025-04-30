import SwiftUI

struct CreateGameView: View {
    @EnvironmentObject var connectionManager: MPConnectionManager
    @EnvironmentObject var game: GameService
    @AppStorage("yourName") var yourName = "Fynn"
    
    @State private var newPlayers: [String] = []
    @State private var startGame: Bool = false
    @State private var navigateToLobby: Bool = false
    @State private var leaderName: String?
    
    var isLeader: Bool = true // By default, assume this is the leader
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCol.edgesIgnoringSafeArea(.all) // Background color
                
                VStack {
                    // Header
                    Text(isLeader 
                         ? "\(connectionManager.myPeerId.displayName)'s Lobby" 
                         : leaderName != nil 
                            ? "\(leaderName!)'s Lobby"
                            : "Game Lobby")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Debug info - display connected peers
                    Text("Connected peers: \(connectionManager.session.connectedPeers.count)")
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    if !connectionManager.session.connectedPeers.isEmpty {
                        Text("Peer names: \(connectionManager.session.connectedPeers.map { $0.displayName }.joined(separator: ", "))")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    
                    // Scrollable List for Players
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if isLeader {
                                // Leader view - show self as leader
                                playerRow(name: connectionManager.myPeerId.displayName, role: "Leader")
                                
                                // Show joined players
                                ForEach(newPlayers, id: \ .self) { player in
                                    playerRow(name: player, role: "Member")
                                }
                            } else {
                                // Non-leader view
                                if !connectionManager.session.connectedPeers.isEmpty {
                                    // First peer is always the host in non-leader view
                                    playerRow(name: connectionManager.session.connectedPeers[0].displayName, role: "Leader")
                                } else if leaderName != nil {
                                    // Use the saved leader name if available
                                    playerRow(name: leaderName!, role: "Leader")
                                }
                                
                                // Show self as member
                                playerRow(name: connectionManager.myPeerId.displayName, role: "Member")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    
                    // Start Game Button - only show for the leader
                    if isLeader {
                        HStack {
                            Spacer()
                            Button("Start Game") {
                                // Get the first peer from the connected peers list
                                if !connectionManager.session.connectedPeers.isEmpty {
                                    let peerID = connectionManager.session.connectedPeers[0]
                                    
                                    print("📱 Initializing game as leader with peer: \(peerID.displayName)")
                                    
                                    // IMPORTANT: Set game type FIRST
                                    game.gameType = .peer
                                    
                                    // Leader is player1 (X), connected peer is player2 (O)
                                    let leaderName = connectionManager.myPeerId.displayName  // Leader
                                    let memberName = peerID.displayName  // Connected peer (member)
                                    
                                    // Reset game state before setup
                                    game.reset()
                                    
                                    // Set up the game with correct player names
                                    game.setupGame(gameType: .peer, player1Name: leaderName, player2Name: memberName)
                                    
                                    // Double ensure player names are set correctly
                                    game.player1.name = leaderName
                                    game.player2.name = memberName
                                    
                                    // Leader goes first (player1)
                                    game.player1.isCurrent = true
                                    game.player2.isCurrent = false
                                    
                                    print("📱 Leader setup complete:")
                                    print("📱 Player1 (X): \(game.player1.name)")
                                    print("📱 Player2 (O): \(game.player2.name)")
                                    
                                    // Send start game notification to the other player
                                    let gameMove = MPGameMove(action: .start, playrName: leaderName, index: nil)
                                    connectionManager.send(gameMove: gameMove)
                                    print("📱 Sent start notification to member")
                                    
                                    // Navigate to the game
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        startGame = true
                                    }
                                } else {
                                    print("❌ No connected peers available to start game")
                                }
                            }
                            .padding()
                            .background(Color.button, in: RoundedRectangle(cornerRadius: 10))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .disabled(connectionManager.session.connectedPeers.isEmpty) // Disable if no players have joined
                        }
                        .padding()
                    } else {
                        // Message for non-leader players
                        Text("Waiting for leader to start the game...")
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    // Navigation destination shared by both roles
                    NavigationLink(destination: GameView(), isActive: $startGame) {
                        EmptyView()
                    }
                }
            }
            .colorScheme(.dark) // Dark mode
            .onAppear {
                if isLeader {
                    connectionManager.startAdvertising()
                    print("Start advertising as leader")
                } else {
                    print("Joined as member, connected peers: \(connectionManager.session.connectedPeers.map { $0.displayName })")
                    
                    // Store the leader name if it's available from receivedInviteFrom
                    if let inviter = connectionManager.receivedInviteFrom {
                        leaderName = inviter.displayName
                        print("Set leader name from invitation: \(leaderName ?? "nil")")
                    } 
                    // Or from connected peers if not found via invitation
                    else if !connectionManager.session.connectedPeers.isEmpty {
                        leaderName = connectionManager.session.connectedPeers[0].displayName
                        print("Set leader name from connected peers: \(leaderName ?? "nil")")
                    }
                }
            }
            .onDisappear {
                if isLeader {
                    connectionManager.stopAdvertising()
                }
                // Don't reset the connection state if we're navigating to the game
                if !startGame {
                    connectionManager.resetConnectionState()
                    print("Resetting connection state...")
                } else {
                    print("Navigating to game, preserving connection...")
                }
            }
            .onChange(of: connectionManager.paired) { paired in
                if paired && isLeader {
                    navigateToLobby = true
                }
            }
            .onChange(of: connectionManager.session.connectedPeers.count) { _ in
                print("Connected peers changed: \(connectionManager.session.connectedPeers.map { $0.displayName })")
                if !isLeader && !connectionManager.session.connectedPeers.isEmpty {
                    leaderName = connectionManager.session.connectedPeers[0].displayName
                    print("Updated leader name to: \(leaderName ?? "nil")")
                }
            }
            .alert("Join Request", isPresented: $connectionManager.receivedInvite) {
                if let receivedPeer = connectionManager.receivedInviteFrom {
                    Button("Accept") {
                        newPlayers.append(receivedPeer.displayName)
                        connectionManager.invitationHandler?(true, connectionManager.session)
                        // Upon acceptance, we need to flag the player as paired 
                        // to trigger the lobby navigation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            connectionManager.paired = true
                            print("Invitation accepted, navigating to lobby...")
                        }
                    }
                    Button("Reject") {
                        connectionManager.invitationHandler?(false, nil)
                    }
                }
            } message: {
                Text("\(connectionManager.receivedInviteFrom?.displayName ?? "Unknown") wants to join your game.")
            }
            // Listen for start game notification
            .onReceive(NotificationCenter.default.publisher(for: .startGame)) { _ in
                print("📱 [CRITICAL] Received startGame notification in CreateGameView")
                
                // CRITICAL: Make absolutely sure game type is set to peer
                game.gameType = .peer
                
                // Log game state before navigating
                print("📱 [CRITICAL] Game state before navigation:")
                print("📱 [CRITICAL] Game type: \(game.gameType)")
                print("📱 [CRITICAL] Player1: \(game.player1.name) (isCurrent: \(game.player1.isCurrent))")
                print("📱 [CRITICAL] Player2: \(game.player2.name) (isCurrent: \(game.player2.isCurrent))")
                print("📱 [CRITICAL] Connected peers: \(connectionManager.session.connectedPeers.map { $0.displayName })")
                
                // Navigate to the game view after a short delay to ensure state is properly set
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("📱 [CRITICAL] Starting navigation to GameView...")
                    startGame = true
                }
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
    CreateGameView(isLeader: true)
        .environmentObject(MPConnectionManager(yourName: "Sample"))
        .environmentObject(GameService())
}
