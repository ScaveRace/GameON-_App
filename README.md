# GameON-_App
## Features

### Multiplayer Gameplay
- Real-time peer-to-peer connectivity
- Automatic player discovery
- Lobby system for game creation and joining
- Leader/Member roles for game management
- Real-time game state synchronization
- Score tracking and updates

### User Interface
- Modern dark mode design
- Intuitive navigation system
- Player list with role indicators
- Real-time connection status
- Game board with visual feedback
- Score display

### Game Management
- Create and join game lobbies
- Automatic role assignment (Leader/Member)
- Game state management
- Turn-based gameplay
- Winner detection and score updates
- Game reset functionality

## Technical Implementation

### Multipeer Connectivity
The app uses Apple's MultipeerConnectivity framework for peer-to-peer communication, which includes:
- `MCSession`: Manages the connection between peers and handles data transfer
- `MCNearbyServiceAdvertiser`: Advertises the device's availability for connections
- `MCNearbyServiceBrowser`: Discovers nearby devices advertising the service
- `MCPeerID`: Represents a peer in the session with a unique display name

### Game State Management
- `GameService`: Core game logic and state management
  - Handles player turns and moves
  - Manages game board state
  - Tracks scores and game progress
  - Implements winner detection logic
  - Synchronizes game state between peers

### Connection Management
- `MPConnectionManager`: Handles all peer-to-peer communication
  - Manages session establishment and teardown
  - Handles invitation acceptance/rejection
  - Synchronizes game moves between players
  - Maintains connection state and peer list
  - Implements reliable data transfer for game moves

### Data Synchronization
- Custom `MPGameMove` protocol for game state updates
- JSON encoding/decoding for move transmission
- Reliable message delivery for critical game events
- Automatic reconnection handling
- State recovery mechanisms for dropped connections

### UI Architecture
- SwiftUI-based modern interface
- Dark mode support with custom color scheme
- Reactive UI updates based on game state
- Navigation stack for view management
### Prerequisites
- iOS device running iOS 15.0 or later
- Xcode 13.0 or later (for development)
- Swift 5.5 or later

### Installation Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/GameON-_App.git
   ```

2. Open the project in Xcode:
   - Navigate to the project directory
   - Double-click on the `.xcodeproj` file

3. Build and run the project:
   - Select your target device
   - Click the "Run" button or press Cmd+R

## User Guide

### Setting Up Your Profile
1. Launch the GameON! app
2. Your default name is set to "Fynn"
3. You can change your name in the app settings

### Creating a Game Lobby
1. Open the app and tap "Create Game"
2. Your device will start advertising for nearby players
3. Wait for other players to join your lobby
4. As the leader, you'll see your name at the top of the player list
5. Once players have joined, tap "Start Game" to begin

### Joining a Game
1. Open the app and tap "Join Game"
2. The app will search for available games nearby
3. Select a game from the list of available players
4. Wait for the leader to accept your join request
5. Once accepted, you'll be taken to the game lobby
6. Wait for the leader to start the game

### Playing the Game
1. The leader (Player 1) always goes first
2. Take turns placing your marks on the game board
3. The game automatically tracks scores and detects winners
4. After a game ends, scores are updated and the game can be reset

### Changing Your Name
1. Go to the app settings
2. Find the "Your Name" field
3. Enter your desired name
4. The change will be applied immediately

## Troubleshooting

### Connection Issues
- Ensure Bluetooth and WiFi are enabled
- Make sure devices are within close proximity
- Restart the app if connection problems persist

### Game Issues
- If the game freezes, try resetting the app
- Ensure all players have the latest version of the app
- Check that all devices are connected to the same network

## Support

For any issues or questions, please contact the development team through the GitHub repository issues section.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
