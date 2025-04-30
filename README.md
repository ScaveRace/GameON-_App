# GameON-_App
## Architecture Overview

The app is built using SwiftUI and follows the MVVM (Model-View-ViewModel) architecture pattern. It uses Apple's MultipeerConnectivity framework for peer-to-peer communication.

## Core Components

### Multipeer Connectivity Implementation

#### MPConnectionManager
The `MPConnectionManager` class handles all peer-to-peer communication using the following components:

- **MCSession**: Manages the connection between peers
  - Handles data transfer between connected devices
  - Manages connection state
  - Provides delegate methods for connection events

- **MCNearbyServiceAdvertiser**: Handles device advertising
  - Broadcasts device availability
  - Manages service discovery
  - Handles invitation requests

- **MCNearbyServiceBrowser**: Handles peer discovery
  - Searches for nearby devices
  - Maintains list of available peers
  - Initiates connection requests

- **MCPeerID**: Represents peer identity
  - Stores unique display name
  - Manages peer identification
  - Handles peer state changes

### Game Logic Implementation

#### GameService
The `GameService` class manages all game-related logic:

- **Game State Management**
  - Tracks player turns
  - Manages game board state
  - Handles move validation
  - Implements win detection

- **Score Management**
  - Tracks player scores
  - Updates score display
  - Handles score synchronization

- **Player Management**
  - Manages player roles (Leader/Member)
  - Handles player turns
  - Tracks player moves

### Data Synchronization

#### MPGameMove Protocol
Custom protocol for game state synchronization:

- **Move Structure**
  ```swift
  struct MPGameMove {
      let action: GameAction
      let playrName: String
      let index: Int?
      let player1Score: Int?
      let player2Score: Int?
  }
  ```

- **Synchronization Process**
  1. Move encoding to JSON
  2. Reliable data transfer
  3. Move decoding and validation
  4. State update and UI refresh

### UI Implementation

#### SwiftUI Architecture
The app uses SwiftUI for its modern UI implementation:

- **View Hierarchy**
  - Main navigation stack
  - Game board view
  - Lobby view
  - Settings view

- **State Management**
  - @State for local view state
  - @Published for observable objects
  - @EnvironmentObject for shared state

- **Custom Components**
  - Game board grid
  - Player list
  - Score display
  - Connection status indicators

## Technical Details

### Connection Flow
1. Device advertising starts
2. Peer discovery begins
3. Connection request sent
4. Invitation accepted/rejected
5. Session established
6. Game state synchronized

### Data Transfer Protocol
- JSON encoding for moves
- Reliable message delivery
- Automatic reconnection
- State recovery mechanisms

### Error Handling
- Connection timeouts
- Data transfer failures
- State synchronization errors
- UI update failures

## Performance Considerations

### Memory Management
- Automatic reference counting
- Weak references for delegates
- Proper cleanup on disconnection

### Network Optimization
- Minimal data transfer
- Efficient state updates
- Connection pooling
- Background operation handling

## Security Implementation

### Data Protection
- Encrypted connections
- Secure peer authentication
- Data validation
- Input sanitization

## Testing

### Unit Tests
- Game logic tests
- Connection tests
- State management tests
- UI component tests

### Integration Tests
- Multi-device scenarios
- Connection scenarios
- Game flow tests
- Error handling tests

## Debugging

### Logging System
- Connection events
- Game state changes
- Error tracking
- Performance metrics

### Debug Tools
- Connection status display
- Game state inspection
- Network traffic monitoring
- Performance profiling

## Future Improvements

### Planned Features
- Enhanced error recovery
- Improved state synchronization
- Additional game modes
- Performance optimizations

### Technical Debt
- Code refactoring
- Documentation updates
- Test coverage improvements
- Performance enhancements 
