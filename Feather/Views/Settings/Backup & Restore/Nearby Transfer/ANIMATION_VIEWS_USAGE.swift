import SwiftUI

// MARK: - Example Usage Documentation
// This file demonstrates how to integrate SenderAnimationView and ReceiverAnimationView
// with the existing Nearby Transfer functionality.

/*
 Usage Example 1: As a full-screen overlay during transfer
 
 In PairingView.swift or similar view:
 
 struct PairingView: View {
     @StateObject private var service = NearbyTransferService()
     @State private var showAnimation = false
     
     var body: some View {
         ZStack {
             // Your existing UI
             NBList("Nearby Transfer") {
                 // ... existing content
             }
             
             // Animation overlay
             if showAnimation {
                 if service.mode == .send {
                     SenderAnimationView(state: service.state)
                         .transition(.opacity)
                 } else {
                     ReceiverAnimationView(state: service.state)
                         .transition(.opacity)
                 }
             }
         }
         .onChange(of: service.state) { newState in
             // Show animation during active transfer states
             switch newState {
             case .transferring, .completed, .failed:
                 withAnimation {
                     showAnimation = true
                 }
             case .idle:
                 withAnimation {
                     showAnimation = false
                 }
             default:
                 break
             }
         }
     }
 }

 Usage Example 2: As a dedicated view via NavigationLink
 
 NavigationLink(destination: TransferAnimationView(service: service)) {
     Text("Start Transfer")
 }
 
 struct TransferAnimationView: View {
     @ObservedObject var service: NearbyTransferService
     @Environment(\.dismiss) var dismiss
     
     var body: some View {
         Group {
             if service.mode == .send {
                 SenderAnimationView(state: service.state)
             } else {
                 ReceiverAnimationView(state: service.state)
             }
         }
         .navigationBarHidden(true)
         .onChange(of: service.state) { newState in
             if case .completed = newState {
                 // Optionally auto-dismiss after success
                 DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                     dismiss()
                 }
             }
         }
     }
 }

 Usage Example 3: As a sheet presentation
 
 .sheet(isPresented: $showTransferAnimation) {
     if service.mode == .send {
         SenderAnimationView(state: service.state)
     } else {
         ReceiverAnimationView(state: service.state)
     }
 }

 Features:
 - Full-screen immersive animations
 - Automatic state handling based on TransferState
 - iOS version compatibility with fallbacks
 - Modern AirDrop-style animations
 - Real-time progress updates
 - Distinct sender (blue/purple) vs receiver (cyan/indigo) color schemes
 - Smooth transitions between states
 - Particle effects on completion (iOS 17+)
*/
