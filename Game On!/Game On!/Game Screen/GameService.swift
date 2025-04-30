import SwiftUI
@MainActor // makes that the ui is getting udated after changing
class GameService: ObservableObject {
    @Published var player1 = Player(gamePiece: .x, name: "Player 1")
    @Published var player2 = Player(gamePiece: .o, name: "Player 2")
    @Published var possibleMoves = Move.all
    @Published var gameOver = false
    @Published var gameBoard = GameSquare.reset
    @Published var isThinking = false
    
    // Add score tracking
    @Published var player1Score: Int = 0
    @Published var player2Score: Int = 0
    
    var gameType = GameType.single
    var currentPlayer: Player {
        if player1.isCurrent {
            return player1
        }else {
            return player2
        }
    }
    
    var gameStarted: Bool {
        player1.isCurrent || player2.isCurrent || isThinking
    }
    var boardDisabled: Bool {
        gameOver || !gameStarted
    }
    
    // In GameService.swift, add this method for compatibility:

    func setupGame(gameType: GameType, player1Name: String = "Player 1", player2Name: String = "Player 2") {
        print("📱 [CRITICAL] Setting up game with type: \(gameType)")
        self.gameType = gameType
        
        print("📱 [CRITICAL] Setting up players - Player 1: \(player1Name), Player 2: \(player2Name)")
        
        // Clear moves array
        self.possibleMoves = Move.all
        
        // Reset game state
        self.gameOver = false
        self.gameBoard = GameSquare.reset
        
        // Set up players
        switch gameType {
        case .single:
            print("📱 Single player game setup")
            player1.name = player1Name
            player2.name = "AI"
            player1.isCurrent = true
            player2.isCurrent = false
        case .bot:
            print("📱 Bot game setup")
            player1.name = "You"
            player2.name = "Bot"
            player1.isCurrent = true
            player2.isCurrent = false
        case .peer:
            print("📱 [CRITICAL] Peer game setup - Player 1: \(player1Name), Player 2: \(player2Name)")
            player1.name = player1Name
            player2.name = player2Name
            player1.isCurrent = true
            player2.isCurrent = false
        case .undetermined:
            print("📱 Undetermined game type - using defaults")
            player1.name = player1Name
            player2.name = player2Name
            player1.isCurrent = true
            player2.isCurrent = false
        }
        
        // Debug check to verify game type
        print("📱 [CRITICAL] Game type after setup: \(self.gameType)")
        
        print("📱 [CRITICAL] Player 1 (\(player1.name)) is current: \(player1.isCurrent)")
        print("📱 [CRITICAL] Player 2 (\(player2.name)) is current: \(player2.isCurrent)")
    }
    
    func reset() { // resets the whole thing
        print("📱 [CRITICAL] Resetting game - current gameType: \(gameType)")
        let currentGameType = gameType
        
        player1.isCurrent = false
        player2.isCurrent = false
        player1.moves.removeAll()
        player2.moves.removeAll()
        possibleMoves = Move.all
        gameOver = false
        gameBoard = GameSquare.reset
        
        // Preserve game type after reset
        gameType = currentGameType
        print("📱 [CRITICAL] Game reset complete - preserved gameType: \(gameType)")
    }
    
    func updateMoves(index: Int){
        if player1.isCurrent {
            player1.moves.append(index + 1)
            gameBoard[index].player = player1
        }else{
            player2.moves.append(index + 1)
            gameBoard[index].player = player2
        }
    }
    
    func checkIfWinner(connectionManager: MPConnectionManager? = nil) {
        print("📱 Checking for winner...")
        print("📱 Player1 (\(player1.name)) is winner: \(player1.isWinner)")
        print("📱 Player2 (\(player2.name)) is winner: \(player2.isWinner)")
        
        if player1.isWinner || player2.isWinner {
            gameOver = true
            print("📱 Winner found! Setting gameOver to true and updating score...")
            // Update scores when a winner is found
            updateScore(connectionManager: connectionManager)
        } else {
            print("📱 No winner yet.")
        }
    }
    func toggleCurrent(){
        player1.isCurrent.toggle()
        player2.isCurrent.toggle()
    }
    func makeMove(index: Int, connectionManager: MPConnectionManager? = nil) {
        if gameBoard[index].player == nil {
            print("📱 GameService: Making move at index \(index)")
            print("📱 GameService: Current player is \(currentPlayer.name)")
            
            withAnimation {
                updateMoves(index: index)
            }
            
            checkIfWinner(connectionManager: connectionManager)
            
            if !gameOver {
                if let matchingIndex = possibleMoves.firstIndex(where: {$0 == (index + 1)}) {
                    possibleMoves.remove(at: matchingIndex)
                }
                
                // Toggle the current player for the next turn
                toggleCurrent()
                print("📱 GameService: Toggled current player to \(currentPlayer.name)")
                
                if gameType == .bot && currentPlayer.name == player2.name {
                    Task {
                        await deviceMove()
                    }
                }
            }
            
            if possibleMoves.isEmpty {
                gameOver = true
            }
        }
    }
    func deviceMove() async {
        isThinking.toggle()
        try? await Task.sleep(nanoseconds: 100_000_000)
        if let move = possibleMoves.randomElement(){
            if let matchingIndex = Move.all.firstIndex(where: {$0 == move}) {
                makeMove(index: matchingIndex)
            }
        }
        isThinking.toggle()
    }
    
    // Add method to update scores when a player wins
    func updateScore(connectionManager: MPConnectionManager? = nil) {
        // Only process if the game is over and there was a winner (not a draw)
        if gameOver && !possibleMoves.isEmpty {
            print("📱 Updating score - winner found")
            
            // Only update score locally if this is a local game or we're the winner's device
            let isLocalGame = gameType != .peer
            let isWinnersDevice = (player1.isWinner && (connectionManager?.myPeerId.displayName == player1.name)) ||
                                  (player2.isWinner && (connectionManager?.myPeerId.displayName == player2.name))
            
            // For peer games, only the winner's device updates the score
            if isLocalGame || isWinnersDevice || connectionManager == nil {
                if player1.isWinner {
                    print("📱 Player 1 (\(player1.name)) wins! Current score: \(player1Score)")
                    player1Score += 1
                    print("📱 Player 1 (\(player1.name)) new score: \(player1Score)")
                } else if player2.isWinner {
                    print("📱 Player 2 (\(player2.name)) wins! Current score: \(player2Score)")
                    player2Score += 1
                    print("📱 Player 2 (\(player2.name)) new score: \(player2Score)")
                }
            } else {
                print("📱 Not updating score locally - waiting for sync from winner's device")
            }
            
            // In peer games, sync scores after updating
            if gameType == .peer && connectionManager != nil {
                print("📱 Syncing scores with peer...")
                connectionManager?.syncScores()
            }
        } else {
            print("📱 Not updating score - gameOver: \(gameOver), possibleMoves empty: \(possibleMoves.isEmpty)")
        }
    }
    
    // Reset scores method
    func resetScores() {
        player1Score = 0
        player2Score = 0
        print("📱 Scores reset")
    }
}
