import SwiftUI

struct MainMenu: View {
    @EnvironmentObject var connectionManager: MPConnectionManager
    @EnvironmentObject var game: GameService
    @AppStorage("yourName") var yourName = ""
    @State private var opponentName: String = ""
    @FocusState private var focus: Bool
    @State private var startGame = false
    @State private var changeName = false
    @State private var newName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(Color("BgCol")).edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image("GameOn!")
                        .resizable()
                        .frame(width: 200, height: 200)
                    
                    Spacer()
                    
                    // Display the current name
                    Text("Current name: \(connectionManager.myPeerId.displayName)")
                        .foregroundStyle(.foregroundButCol)
                        .padding(.bottom, 10)
                    
                    Button("Set Name") {
                        changeName = true
                        // Pre-populate with current name
                        newName = connectionManager.myPeerId.displayName
                    }
                    .frame(width: 100, height: 30)
                    .background(.foregroundButCol, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.black)
                    .padding()
                    .alert("Change Name", isPresented: $changeName, actions: {
                        TextField("New name", text: $newName)
                            .focused($focus)
                            .submitLabel(.done)
                            .onSubmit{
                                if !newName.isEmpty {
                                    yourName = newName
                                    // Update the display name in the connection manager
                                    connectionManager.updateDisplayName(newName)
                                }
                                changeName = false
                            }
                        Button("Save", role: .none) {
                            if !newName.isEmpty {
                                yourName = newName
                                // Update the display name in the connection manager
                                connectionManager.updateDisplayName(newName)
                            }
                            changeName = false
                        }
                        Button("Cancel", role: .cancel) {}
                    }, message: {
                        Text("Enter a new display name to use in the game.")
                    })
                    
                    NavigationLink("Create Game", destination: CreateGameView())
                        .foregroundColor(.foregroundButCol)
                        .frame(width: 200, height: 30)
                        .foregroundStyle(.black)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color("ButtonColor"), in: RoundedRectangle(cornerRadius: 10))
                    
                    NavigationLink("Join Game", destination: JoinGameView())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.foregroundButCol)
                        .frame(width: 200, height: 30)
                        .padding()
                        .background(Color("ButtonColor"), in: RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            // Set initial name on app start
            if !yourName.isEmpty {
                connectionManager.updateDisplayName(yourName)
            }
        }
    }
}

#Preview {
    MainMenu()
        .environmentObject(MPConnectionManager(yourName: "Sample"))
        .environmentObject(GameService())
}
