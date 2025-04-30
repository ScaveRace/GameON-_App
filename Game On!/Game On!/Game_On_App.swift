import SwiftUI

@main
struct Game_On_App: App {
    @AppStorage("yourName") var yourName = "Player"
    @StateObject private var connectionManager: MPConnectionManager
    @StateObject private var game = GameService()
    
    init() {
        // Initialize connection manager with stored name
        _connectionManager = StateObject(wrappedValue: MPConnectionManager(yourName: UserDefaults.standard.string(forKey: "yourName") ?? "Player"))
        
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some Scene {
        WindowGroup {
            MainMenu()
                .environmentObject(connectionManager)
                .environmentObject(game)
        }
    }
}
