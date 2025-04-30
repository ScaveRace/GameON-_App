import SwiftUI

struct GameView: View {
    @EnvironmentObject var game: GameService
    @EnvironmentObject var connectionManager: MPConnectionManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background color to match app theme
            Color("BgCol").edgesIgnoringSafeArea(.all)
            
            // Disable swipe back gesture
            DisableSwipeBackGesture()
            
            VStack {
                // Score display section
                HStack {
                    VStack {
                        Text(game.player1.name)
                            .fontWeight(.semibold)
                        Text("\(game.player1Score)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("ButtonColor"))
                    }
                    .frame(width: 100)
                    
                    Spacer()
                    
                    Text("VS")
                        .font(.headline)
                        .foregroundColor(Color("ForegroundButCol"))
                    
                    Spacer()
                    
                    VStack {
                        Text(game.player2.name)
                            .fontWeight(.semibold)
                        Text("\(game.player2Score)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("ButtonColor"))
                    }
                    .frame(width: 100)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .foregroundColor(Color("ForegroundButCol"))
                
                if game.gameType == .peer {
                    // Display player information for peer games
                    HStack {
                        VStack {
                            Text(game.player1.name)
                                .fontWeight(.bold)
                            Text("(X)")
                                .font(.caption)
                            if game.player1.isCurrent {
                                Text("Your turn")
                                    .font(.caption)
                                    .foregroundColor(Color("ButtonColor"))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(game.player1.name == connectionManager.myPeerId.displayName ? 
                                     Color("ButtonColor").opacity(0.3) : Color.gray.opacity(0.2))
                        )
                        
                        Spacer()
                        
                        Text("VS")
                            .font(.headline)
                            .foregroundColor(Color("ForegroundButCol"))
                        
                        Spacer()
                        
                        VStack {
                            Text(game.player2.name)
                                .fontWeight(.bold)
                            Text("(O)")
                                .font(.caption)
                            if game.player2.isCurrent {
                                Text("Your turn")
                                    .font(.caption)
                                    .foregroundColor(Color("ButtonColor"))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(game.player2.name == connectionManager.myPeerId.displayName ? 
                                     Color("ButtonColor").opacity(0.3) : Color.gray.opacity(0.2))
                        )
                    }
                    .padding()
                    .foregroundColor(Color("ForegroundButCol"))
                } else if [game.player1.isCurrent, game.player2.isCurrent].allSatisfy{ $0 == false} {
                    // For non-peer games, show the player selection
                    Text("Select a player to start")
                        .foregroundColor(Color("ForegroundButCol"))
                        .font(.title2)
                        .padding(.top)
                    
                    // Player selection buttons for non-peer games
                    HStack {
                        Button(game.player1.name) {
                            game.player1.isCurrent = true
                        }
                        .buttonStyle(PlayerButtonStyle(player: game.player1))
                        
                        Button(game.player2.name) {
                            game.player2.isCurrent = true
                            if game.gameType == .bot {
                                Task {
                                    await game.deviceMove()
                                }
                            }
                        }
                        .buttonStyle(PlayerButtonStyle(player: game.player2))
                    }
                    .disabled(game.gameStarted)
                    .padding(.bottom)
                }
                
                // Game grid
                VStack {
                    HStack {
                        ForEach(0...2, id: \.self) { index in
                            SquareView(index: index)
                        }
                    }
                    HStack {
                        ForEach(3...5, id: \.self) { index in
                            SquareView(index: index)
                        }
                    }
                    HStack {
                        ForEach(6...8, id: \.self) { index in
                            SquareView(index: index)
                        }
                    }
                }
                .overlay {
                    if game.isThinking {
                        VStack {
                            Text(" Thinking... ")
                                .foregroundColor(Color("BgCol"))
                                .background(Rectangle().fill(Color("ForegroundButCol")))
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("ForegroundButCol")))
                        }
                    }
                }
                .disabled(game.boardDisabled ||
                         game.gameType == .peer &&
                         connectionManager.myPeerId.displayName != game.currentPlayer.name)
                
                // Game over section
                VStack {
                    if game.gameOver {
                        Text("Game Over")
                            .font(.title2)
                            .foregroundColor(Color("ForegroundButCol"))
                            .padding(.top, 10)
                        
                        if game.possibleMoves.isEmpty {
                            Text("Nobody wins")
                                .foregroundColor(Color("ForegroundButCol"))
                        } else {
                            Text("\(game.currentPlayer.name) wins!")
                                .foregroundColor(Color("ForegroundButCol"))
                        }
                        
                        Button("New Game") {
                            game.reset()
                            if game.gameType == .peer {
                                let gameMove = MPGameMove(action: .reset, playrName: nil, index: nil)
                                connectionManager.send(gameMove: gameMove)
                                
                                // For peer games, player1 (leader) always goes first
                                game.player1.isCurrent = true
                                game.player2.isCurrent = false
                            }
                        }
                        .padding()
                        .background(Color("ButtonColor"), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(Color("ForegroundButCol"))
                        .padding(.top, 5)
                    }
                }
                .font(.headline)
                
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("TicTacToe")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Game") {
                    // Reset scores before ending the game
                    game.resetScores()
                    
                    dismiss()
                    if game.gameType == .peer {
                        let gameMove = MPGameMove(action: .end, playrName: nil, index: nil)
                        connectionManager.send(gameMove: gameMove)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("ButtonColor"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundColor(Color("ForegroundButCol"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // CRITICAL: Check if we're in peer mode at all
            print("📱 [CRITICAL] GameView appeared - current game type: \(game.gameType)")
            
            // Set up connection manager link to game service
            connectionManager.setup(game: game)
            
            if game.gameType == .peer {
                print("📱 [CRITICAL] Processing PEER game initialization")
                print("📱 [CRITICAL] My name: \(connectionManager.myPeerId.displayName)")
                print("📱 [CRITICAL] Player1 (X): \(game.player1.name)")
                print("📱 [CRITICAL] Player2 (O): \(game.player2.name)")
                
                // Determine my role in the game
                let amILeader = connectionManager.myPeerId.displayName == game.player1.name
                print("📱 [CRITICAL] My role: \(amILeader ? "Leader (X)" : "Member (O)")")
                
                // Ensure the game state is properly initialized
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // CRITICAL: Make absolutely sure we're still in peer mode
                    if game.gameType != .peer {
                        print("📱 [CRITICAL] Correcting game type to .peer")
                        game.gameType = .peer
                    }
                    
                    // Force set player1 (leader) as current at start of game
                    print("📱 [CRITICAL] Setting initial turn state:")
                    print("📱 [CRITICAL] Before: Player1 (\(game.player1.name)) is current: \(game.player1.isCurrent)")
                    print("📱 [CRITICAL] Before: Player2 (\(game.player2.name)) is current: \(game.player2.isCurrent)")
                    
                    // Always ensure player1 (leader) goes first in peer games
                    game.player1.isCurrent = true
                    game.player2.isCurrent = false
                    
                    print("📱 [CRITICAL] After: Player1 (\(game.player1.name)) is current: \(game.player1.isCurrent)")
                    print("📱 [CRITICAL] After: Player2 (\(game.player2.name)) is current: \(game.player2.isCurrent)")
                    print("📱 [CRITICAL] Game ready - current player: \(game.currentPlayer.name)")
                    print("📱 [CRITICAL] Is it my turn? \(connectionManager.myPeerId.displayName == game.currentPlayer.name ? "YES" : "NO")")
                    
                    // If I'm the leader, send a turn confirmation to the 2nd player
                    if amILeader {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let turnConfirmation = MPGameMove(action: .move, playrName: connectionManager.myPeerId.displayName, index: -5)
                            connectionManager.send(gameMove: turnConfirmation)
                            print("📱 [CRITICAL] Leader sent turn confirmation signal")
                        }
                    }
                }
            } else {
                // For non-peer games, just reset
                print("📱 [INFO] Initializing non-peer game")
                game.reset()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .endGame)) { _ in
            // Reset scores when receiving end game notification
            game.resetScores()
            dismiss()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
            .environmentObject(GameService())
            .environmentObject(MPConnectionManager(yourName: "Sample"))
    }
}

struct PlayerButtonStyle: ButtonStyle {
    let player: Player
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(player.isCurrent ? Color("ButtonColor") : Color.gray.opacity(0.6))
            )
            .foregroundColor(Color("ForegroundButCol"))
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Add a UIViewControllerRepresentable to disable the swipe back gesture
struct DisableSwipeBackGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}
