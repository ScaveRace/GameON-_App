import MultipeerConnectivity
import Dispatch
import ObjectiveC

// Define keys for associated objects
private struct AssociatedKeys {
    static var myPeerId = "myPeerId"
}

extension String {
    static var serviceName = "gameon"
}

class MPConnectionManager: NSObject, ObservableObject {
    let serviceType = String.serviceName
    private var _internalPeerId: MCPeerID
    var session: MCSession
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    var nearbyServiceBrowser: MCNearbyServiceBrowser
    var game: GameService?
    
    // Create a computed property for myPeerId that works with the Objective-C runtime
    var myPeerId: MCPeerID {
        get {
            if let peerId = objc_getAssociatedObject(self, &AssociatedKeys.myPeerId) as? MCPeerID {
                return peerId
            }
            return _internalPeerId
        }
    }
    
    func setup(game: GameService) {
        self.game = game
    }
    
    @Published var availablePeers = [MCPeerID]()
    @Published var receivedInvite: Bool = false
    @Published var receivedInviteFrom: MCPeerID?
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var paired: Bool = false
    
    var isAvailableToPlay: Bool = false {
        didSet {
            if isAvailableToPlay {
                startAdvertising()
            } else {
                stopAdvertising()
            }
        }
    }
    
    init(yourName: String) {
        _internalPeerId = MCPeerID(displayName: yourName)
        session = MCSession(peer: _internalPeerId, securityIdentity: nil, encryptionPreference: .required)
        nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: _internalPeerId, discoveryInfo: nil, serviceType: serviceType)
        nearbyServiceBrowser = MCNearbyServiceBrowser(peer: _internalPeerId, serviceType: serviceType)
        super.init()
        session.delegate = self
        nearbyServiceAdvertiser.delegate = self
        nearbyServiceBrowser.delegate = self
    }
    
    deinit {
        stopBrowsing()
        stopAdvertising()
    }
    
    func startAdvertising() {
        nearbyServiceAdvertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        nearbyServiceAdvertiser.stopAdvertisingPeer()
    }
    
    func startBrowsing() {
        nearbyServiceBrowser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        nearbyServiceBrowser.stopBrowsingForPeers()
        availablePeers.removeAll()
    }
    
    func send(gameMove: MPGameMove) {
        if !session.connectedPeers.isEmpty {
            do {
                if let data = gameMove.data() {
                    try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                }
            } catch {
                print("Error sending game move: \(error.localizedDescription)")
            }
        }
    }
    
    func updateDisplayName(_ newName: String) {
        // We can't modify the MCPeerID directly, so we need to reset everything
        
        // First stop all networking services
        stopBrowsing()
        stopAdvertising()
        session.disconnect()
        
        // Create a new peer ID with the new name
        let newPeerId = MCPeerID(displayName: newName)
        
        // Store the new peer ID using the associated object
        objc_setAssociatedObject(self, &AssociatedKeys.myPeerId, newPeerId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Create new session, advertiser, and browser with the new peer ID
        let newSession = MCSession(peer: newPeerId, securityIdentity: nil, encryptionPreference: .required)
        let newAdvertiser = MCNearbyServiceAdvertiser(peer: newPeerId, discoveryInfo: nil, serviceType: serviceType)
        let newBrowser = MCNearbyServiceBrowser(peer: newPeerId, serviceType: serviceType)
        
        // Set up delegates for new objects
        newSession.delegate = self
        newAdvertiser.delegate = self
        newBrowser.delegate = self
        
        // Replace the existing session, advertiser, and browser
        self.session = newSession
        self.nearbyServiceAdvertiser = newAdvertiser
        self.nearbyServiceBrowser = newBrowser
        
        // Reset the connection state variables
        paired = false
        receivedInvite = false
        receivedInviteFrom = nil
        invitationHandler = nil
        isAvailableToPlay = false
        availablePeers.removeAll()
        
        print("Display name updated to: \(newName)")
    }
    
    func resetConnectionState() {
        session.disconnect()
        
        paired = false
        receivedInvite = false
        receivedInviteFrom = nil
        invitationHandler = nil
        isAvailableToPlay = false
        availablePeers.removeAll()
    }
    
    // Add a function to send score updates to connected peers
    @MainActor func syncScores() {
        if !session.connectedPeers.isEmpty && game?.gameType == .peer {
            guard let gameService = game else { 
                print("📱 syncScores: Error - game service is nil")
                return 
            }
            
            print("📱 syncScores: Preparing to sync - Player1: \(gameService.player1Score), Player2: \(gameService.player2Score)")
            
            let scoreUpdate = MPGameMove(
                action: .syncScores,
                playrName: myPeerId.displayName,
                index: nil,
                player1Score: gameService.player1Score,
                player2Score: gameService.player2Score
            )
            send(gameMove: scoreUpdate)
            print("📱 syncScores: Sent score update to peers: Player1: \(gameService.player1Score), Player2: \(gameService.player2Score)")
        } else {
            print("📱 syncScores: Not syncing - no connected peers or not in peer mode")
            if let gameService = game {
                print("📱 syncScores: Current game type: \(gameService.gameType)")
                print("📱 syncScores: Connected peers: \(session.connectedPeers.count)")
            }
        }
    }
}

extension MPConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = availablePeers.firstIndex(of: peerID) else { return }
        DispatchQueue.main.async {
            self.availablePeers.remove(at: index)
        }
    }
}

extension MPConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.receivedInvite = true
            self.receivedInviteFrom = peerID
            self.invitationHandler = { (accept, session) in
                // Call the original handler
                invitationHandler(accept, session)
                
                // If invitation was accepted, update state appropriately
                if accept {
                    // This will be updated properly when the session officially connects,
                    // but we need to properly handle the UI transition here
                    print("Invitation accepted, preparing to join lobby")
                }
            }
            self.isAvailableToPlay = false
        }
    }
}

extension MPConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.paired = false
                self.isAvailableToPlay = true
                print("📱 Peer disconnected: \(peerID.displayName)")
            case .connecting:
                print("📱 Connecting to peer: \(peerID.displayName)")
            case .connected:
                self.paired = true
                print("📱 Connected to peer: \(peerID.displayName)")
                print("📱 All connected peers: \(session.connectedPeers.map { $0.displayName })")
                
                // Determine if I'm the leader (invited others) or a member (accepted invitation)
                let amILeader = self.receivedInviteFrom == nil
                print("📱 My role: \(amILeader ? "Leader" : "Member")")
                
                if !amILeader && self.receivedInviteFrom == nil {
                    // Member doesn't have the leader reference yet, store it
                    self.receivedInviteFrom = peerID
                    print("📱 Stored leader reference: \(peerID.displayName)")
                }
                
                self.isAvailableToPlay = false
                
                // Post notification about connection
                NotificationCenter.default.post(name: .connectionEstablished, object: nil)
            @unknown default:
                self.paired = false
                self.isAvailableToPlay = true
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let gameMove = try? JSONDecoder().decode(MPGameMove.self, from: data) else {
            print("Failed to decode game move")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch gameMove.action {
            case .start:
                print("📱 [CRITICAL] Received start game notification from: \(peerID.displayName)")
                
                // CRITICAL: Force GameType to peer for joining player
                if let gameService = self.game {
                    print("📱 [CRITICAL] FORCING game type to .peer")
                    gameService.gameType = .peer
                } else {
                    print("❌ [CRITICAL] Game service not initialized!")
                }
                
                // For the joining player, the leader (sender) is player1, and self is player2
                let leaderName = peerID.displayName
                let memberName = self.myPeerId.displayName
                
                print("📱 [CRITICAL] Setting up game for joining player:")
                print("📱 [CRITICAL] Leader (X): \(leaderName)")
                print("📱 [CRITICAL] Member (O): \(memberName)")
                
                // Reset and set up the game with correct player assignments
                self.game?.reset()
                self.game?.setupGame(gameType: .peer, player1Name: leaderName, player2Name: memberName)
                
                // Double check the game type again
                if let gameType = self.game?.gameType {
                    print("📱 [CRITICAL] Game type after setup: \(gameType)")
                    if gameType != .peer {
                        print("📱 [CRITICAL] Game type is not peer! Forcing to peer again.")
                        self.game?.gameType = .peer
                    }
                }
                
                // Double ensure names are set correctly
                self.game?.player1.name = leaderName
                self.game?.player2.name = memberName
                
                // Automatically set player1 as current (leader goes first)
                self.game?.player1.isCurrent = true
                self.game?.player2.isCurrent = false
                
                print("📱 [CRITICAL] Game setup complete. Navigating to game view...")
                
                // Post notification to navigate to game view (CRITICAL)
                NotificationCenter.default.post(name: .startGame, object: nil)
                
                // Send acknowledgment after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let acknowledgement = MPGameMove(action: .move, playrName: memberName, index: -1)
                    self.send(gameMove: acknowledgement)
                    print("📱 Sent game start acknowledgement to leader")
                }
                
            case .syncScores:
                print("📱 Received score update from \(peerID.displayName)")
                
                // Update scores if they are provided
                if let p1Score = gameMove.player1Score, let p2Score = gameMove.player2Score, let gameService = self.game {
                    print("📱 Score sync: Received - Player1: \(p1Score), Player2: \(p2Score)")
                    print("📱 Score sync: Current - Player1: \(gameService.player1Score), Player2: \(gameService.player2Score)")
                    
                    Task { @MainActor in
                        gameService.player1Score = p1Score
                        gameService.player2Score = p2Score
                        print("📱 Score sync: Updated - Player1: \(gameService.player1Score), Player2: \(gameService.player2Score)")
                    }
                } else {
                    print("📱 Score sync: Error - Missing score data or game service")
                    if gameMove.player1Score == nil || gameMove.player2Score == nil {
                        print("📱 Score sync: Scores missing from message")
                    }
                    if self.game == nil {
                        print("📱 Score sync: Game service is nil")
                    }
                }
                
            case .move:
                if let index = gameMove.index, let name = gameMove.playrName {
                    if index == -1 {
                        // Special case: acknowledgement of game start
                        print("📱 Received game start acknowledgement from: \(name)")
                        
                        // Extra protection - ensure game type is still peer
                        if let gameService = self.game, gameService.gameType != .peer {
                            print("📱 [CRITICAL] Correcting game type to .peer after acknowledgement")
                            gameService.gameType = .peer
                            
                            // Ensure player1 (leader) starts
                            gameService.player1.isCurrent = true
                            gameService.player2.isCurrent = false
                        }
                        
                        // Send a dummy "ready" move to ensure both sides are synced
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let readyMove = MPGameMove(action: .move, playrName: self.myPeerId.displayName, index: -2)
                            self.send(gameMove: readyMove)
                            print("📱 [CRITICAL] Sent ready signal to ensure turn synchronization")
                        }
                        return
                    }
                    
                    if index == -2 {
                        // Special case: "ready" signal - ensure turns are set correctly
                        print("📱 [CRITICAL] Received ready signal from: \(name)")
                        
                        if let gameService = self.game {
                            // Enforce correct player turn state
                            gameService.player1.isCurrent = true
                            gameService.player2.isCurrent = false
                            
                            print("📱 [CRITICAL] Game is ready - confirmed player1 (\(gameService.player1.name)) goes first")
                            print("📱 [CRITICAL] Current player: \(gameService.currentPlayer.name)")
                        }
                        return
                    }
                    
                    if index == -3 {
                        // Special case: "sync" signal after reset
                        print("📱 [CRITICAL] Received sync signal after reset from: \(name)")
                        
                        if let gameService = self.game {
                            // Enforce correct player turn state
                            gameService.player1.isCurrent = true
                            gameService.player2.isCurrent = false
                            
                            print("📱 [CRITICAL] Game sync completed - confirmed player1 (\(gameService.player1.name)) goes first")
                        }
                        return
                    }
                    
                    if index == -5 {
                        // Special case: Turn confirmation from leader
                        print("📱 [CRITICAL] Received turn confirmation from leader: \(name)")
                        
                        if let gameService = self.game {
                            // Force update player states for joining player
                            gameService.player1.isCurrent = true
                            gameService.player2.isCurrent = false
                            
                            print("📱 [CRITICAL] Turn confirmation - Player1 (\(gameService.player1.name)) is current: \(gameService.player1.isCurrent)")
                            print("📱 [CRITICAL] Turn confirmation - Player2 (\(gameService.player2.name)) is current: \(gameService.player2.isCurrent)")
                            print("📱 [CRITICAL] Turn confirmation - current player: \(gameService.currentPlayer.name)")
                        }
                        return
                    }
                    
                    print("📱 Received move from \(name) at index \(index)")
                    // Extra protection to ensure we're still in peer mode
                    if let gameService = self.game, gameService.gameType != .peer {
                        print("📱 [CRITICAL] Correcting game type to .peer before applying move")
                        gameService.gameType = .peer
                    }
                    
                    if name != self.myPeerId.displayName {
                        // Only process moves from the other player
                        self.game?.makeMove(index: index, connectionManager: self)
                    }
                }
                
            case .reset:
                print("📱 Received game reset request")
                // Preserve game type before reset
                let gameTypeIsPeer = self.game?.gameType == .peer
                
                self.game?.reset()
                
                // Restore game type after reset
                if gameTypeIsPeer {
                    print("📱 [CRITICAL] Restoring game type to .peer after reset")
                    self.game?.gameType = .peer
                }
                
                // For peer games, set player1 as current after reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if self.game?.gameType == .peer {
                        self.game?.player1.isCurrent = true
                        self.game?.player2.isCurrent = false
                        
                        print("📱 [CRITICAL] After reset: player1 is current: \(self.game?.player1.isCurrent ?? false)")
                        print("📱 [CRITICAL] After reset: player2 is current: \(self.game?.player2.isCurrent ?? false)")
                        
                        // Send an additional sync message to ensure both sides are on the same page
                        let syncMove = MPGameMove(action: .move, playrName: self.myPeerId.displayName, index: -3)
                        self.send(gameMove: syncMove)
                        print("📱 [CRITICAL] Sent sync signal after reset")
                    }
                }
                
            case .end:
                print("📱 Received game end notification")
                // Reset scores when the game ends
                self.game?.resetScores()
                
                // Sync the reset scores to both devices
                if let gameService = self.game, gameService.gameType == .peer {
                    let scoreUpdate = MPGameMove(
                        action: .syncScores,
                        playrName: self.myPeerId.displayName,
                        index: nil,
                        player1Score: 0,
                        player2Score: 0
                    )
                    self.send(gameMove: scoreUpdate)
                    print("📱 Sent final score reset to peers")
                }
                
                NotificationCenter.default.post(name: .endGame, object: nil)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not implemented
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not implemented
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not implemented
    }
}
