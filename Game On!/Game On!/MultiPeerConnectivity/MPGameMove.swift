import Foundation

struct MPGameMove: Codable {
    enum Action: Int, Codable {
        case start, move, reset, end, syncScores
    }
    let action: Action
    let playrName: String?
    let index: Int?
    
    // Add score fields for synchronization
    let player1Score: Int?
    let player2Score: Int?
    
    // Update initializers to include score parameters with default nil values
    init(action: Action, playrName: String? = nil, index: Int? = nil, player1Score: Int? = nil, player2Score: Int? = nil) {
        self.action = action
        self.playrName = playrName
        self.index = index
        self.player1Score = player1Score
        self.player2Score = player2Score
    }
    
    func data() -> Data? {
        try? JSONEncoder().encode(self)
    }
}
// In MPGameMove.swift, add after the existing struct
extension Notification.Name {
    static let startGame = Notification.Name("startGame")
    static let endGame = Notification.Name("endGame")
    static let connectionEstablished = Notification.Name("connectionEstablished")
}
