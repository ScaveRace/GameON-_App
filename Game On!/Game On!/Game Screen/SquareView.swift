import SwiftUI

struct SquareView: View {
    @EnvironmentObject var game: GameService
    @EnvironmentObject var connectionManager: MPConnectionManager
    let index: Int
    
    var body: some View {
        Button {
            if game.gameType == .peer {
                let gameMove = MPGameMove(action: .move, playrName: game.currentPlayer.name, index: index)
                game.makeMove(index: index, connectionManager: connectionManager)
                connectionManager.send(gameMove: gameMove)
            } else {
                game.makeMove(index: index)
            }
        } label: {
            game.gameBoard[index].image
                .resizable()
                .frame(width: 100, height: 100)
                .border(Color("ForegroundButCol"))
        }
        .disabled(game.gameBoard[index].player != nil)
    }
}
