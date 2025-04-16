//
//  SyncToggleView.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/16/25.
//
import Foundation
import SwiftUI

struct SyncToggleView: View {
    @ObservedObject var syncManager = SyncManager.shared
    @Environment(\.managedObjectContext) private var context
    
    @State private var showingSyncProgress = false
    @State private var syncError: String? = nil
    
    var body: some View {
        VStack {
            Toggle("Enable Syncing", isOn: $syncManager.syncEnabled)
                .padding()
                .onChange(of: syncManager.syncEnabled) { _, newValue in
                    if newValue {
                        Task {
                            showingSyncProgress = true
                            do {
                                try await syncManager.performFullSync(context: context)
                                syncError = nil
                            } catch {
                                syncError = error.localizedDescription
                            }
                            showingSyncProgress = false
                        }
                    }
                }
            
            if let lastSync = syncManager.lastSyncTime {
                Text("Last synced: \(lastSync, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if showingSyncProgress {
                ProgressView("Syncing...")
                    .padding()
            }
            
            if let error = syncError {
                Text("Sync error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button("Sync Now") {
                Task {
                    showingSyncProgress = true
                    do {
                        try await syncManager.performFullSync(context: context)
                        syncError = nil
                    } catch {
                        syncError = error.localizedDescription
                    }
                    showingSyncProgress = false
                }
            }
            .disabled(!syncManager.syncEnabled || showingSyncProgress)
            .padding()
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

