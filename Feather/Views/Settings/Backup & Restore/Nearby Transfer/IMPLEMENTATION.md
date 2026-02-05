# Nearby Transfer Feature - Implementation Documentation

## Overview
The Nearby Transfer feature enables wireless backup transfer between Portal devices using Apple's MultipeerConnectivity framework. It reuses the exact backup creation and restore logic from BackupRestoreView while replacing file-based I/O with live device-to-device transfer.

## Architecture

### Components

#### 1. NearbyTransferView.swift
- **Purpose**: Entry point for the Nearby Transfer feature
- **Features**:
  - Informational header with feature overview
  - Quick start button to begin transfer
  - Feature highlights (security, speed, no internet required)
  - System requirements
  - List of transferable items

#### 2. PairingView.swift
- **Purpose**: Main transfer coordination view
- **Features**:
  - Segmented control for Send/Receive mode selection
  - Send Mode:
    - Discovers nearby devices using MCNearbyServiceBrowser
    - Lists available receiving devices
    - Initiates backup preparation and transfer on device selection
  - Receive Mode:
    - Advertises device using MCNearbyServiceAdvertiser
    - Shows receiver status and device information
    - Automatically accepts incoming connections
  - Integrates with TransferProgressView for live progress
  - Presents RestoreOptionsView upon successful receive

#### 3. TransferProgressView.swift
- **Purpose**: Real-time transfer progress monitoring
- **Features**:
  - Progress circle with percentage
  - Transfer statistics:
    - Bytes transferred / total bytes
    - Transfer speed (MB/s)
    - Estimated time remaining
    - Current item being transferred
  - State-based UI:
    - Discovering devices
    - Connecting to peer
    - Transferring with live progress
    - Completion status
    - Error handling with retry option
  - Cancel and retry actions

#### 4. NearbyTransferService.swift
- **Purpose**: Core MultipeerConnectivity coordination
- **Features**:
  - Manages MCSession, MCNearbyServiceAdvertiser, MCNearbyServiceBrowser
  - Handles peer discovery and connection
  - Send mode:
    - Encrypts backup payload using AES-256
    - Sends size header followed by chunked data transfer
    - Reports progress with speed calculation
  - Receive mode:
    - Receives size header and data chunks
    - Decrypts and validates received backup
    - Stores temporary backup for restoration
  - Error handling and connection management
  - Automatic retry support

#### 5. BackupPayload.swift
- **Purpose**: Backup serialization and encryption
- **Features**:
  - Packages backup directory into single data structure
  - Serializes files with relative paths preserved
  - AES-256-GCM encryption with password-based key derivation
  - Decryption and extraction to destination directory

### Data Flow

#### Send Flow:
1. User selects Send mode in PairingView
2. Service starts browsing for nearby devices
3. User taps on discovered device
4. PairingView calls `prepareBackupForTransfer()` to create backup directory
   - Reuses exact logic from BackupRestoreView.prepareBackup()
   - Includes certificates, apps, sources, frameworks, archives, database, settings
5. BackupPayload packages directory into encrypted data
6. Service sends size header then data chunks via MCSession
7. TransferProgressView shows real-time progress
8. Completion or error state displayed

#### Receive Flow:
1. User selects Receive mode in PairingView
2. Service starts advertising device
3. Service automatically accepts incoming connections
4. Service receives size header and data chunks
5. TransferProgressView shows real-time progress
6. On completion, BackupPayload decrypts and extracts to temp directory
7. RestoreOptionsView presents Merge or Replace options
8. Selected restore method applied using BackupRestoreView logic
9. App restarts to apply changes

### Security

- **Encryption**: AES-256-GCM encryption using CryptoKit
- **Key Derivation**: SHA256 hash of shared password
- **Connection Security**: MCSession with .required encryption preference
- **Validation**: Backup markers and integrity checks before restoration

### Integration Points

#### BackupRestoreView Integration:
- Added "Wireless Transfer" section with navigation to NearbyTransferView
- Uses same BackupOptions structure
- Reuses prepareBackup logic for creating backup directory
- Reuses restore logic for applying received backup

#### Storage Integration:
- Uses Storage.shared for Core Data access
- Uses FileManager extensions (certificates, signed, unsigned, archives)
- Accesses documentsURL for file operations

#### Managers Integration:
- HapticsManager for user feedback
- AppLogManager for logging (where applicable)
- UIAlertController extensions for error messages

### Privacy Permissions

Added to Info.plist:
- `NSLocalNetworkUsageDescription`: Required for peer discovery on local network
- `NSBonjourServices`: Specifies service types (_portal-backup._tcp, _portal-backup._udp)

## File Structure

```
Feather/Views/Settings/Backup & Restore/Nearby Transfer/
├── NearbyTransferView.swift        # Entry point
├── PairingView.swift                # Send/Receive coordination
├── TransferProgressView.swift       # Progress monitoring
├── NearbyTransferService.swift      # MultipeerConnectivity logic
└── BackupPayload.swift              # Serialization & encryption
```

## Key Features

1. **Reusability**: Exact same backup/restore logic as file-based backup
2. **Live Transfer**: No intermediate files, direct device-to-device
3. **Progress Tracking**: Real-time progress with speed and ETA
4. **Security**: End-to-end encrypted transfers
5. **Error Handling**: Retry capability on failure
6. **User Experience**: Clear instructions and status indicators
7. **Flexibility**: Merge or Replace restore options

## Testing Considerations

1. **Two Devices Required**: Testing requires two iOS devices on same network
2. **Permissions**: Ensure local network permission granted
3. **Network**: Both devices must be on same Wi-Fi network or within Bluetooth range
4. **Battery**: Large backups may take time; ensure sufficient battery
5. **Storage**: Verify sufficient storage on receiving device
6. **Interruption**: Test connection loss and retry scenarios

## Future Enhancements

Possible improvements:
- Custom password/PIN for encryption
- Transfer resumption after interruption
- Compression before transfer
- Selective backup item transfer
- Transfer history and logs
- QR code pairing for easier discovery
