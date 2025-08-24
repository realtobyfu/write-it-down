//
//  SyncControlView.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/16/25.
//
import Foundation
import SwiftUI

struct SyncControlView: View {
    @ObservedObject var syncManager = SyncManager.shared
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreDataManager: CoreDataManager
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    @State private var showingDatabaseResetAlert = false
    @State private var showingConsolidateAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enable Sync Toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $syncManager.syncEnabled) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.title2)
                            .foregroundColor(syncManager.syncEnabled ? .green : .gray)
                        VStack(alignment: .leading) {
                            Text("Sync Enabled")
                                .font(.headline)
                            Text("Automatically sync your notes across devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            if syncManager.syncEnabled {
                // Sync Options
                VStack(alignment: .leading, spacing: 12) {
                    // Consolidate duplicates button
                    Button(action: {
                        showingConsolidateAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.merge")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Consolidate Duplicates")
                                    .font(.subheadline)
                                Text("Remove duplicate categories from cloud")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Sync Status
                VStack(alignment: .leading, spacing: 12) {
                    // Status indicator
                    HStack {
                        switch syncManager.syncStatus {
                        case .idle:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Synced")
                                .font(.subheadline)
                        case .syncing:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                            Text("Syncing...")
                                .font(.subheadline)
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Sync Complete")
                                .font(.subheadline)
                        case .error(let message):
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Sync Error")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        // Manual sync button
                        Button(action: {
                            Task {
                                await syncManager.performAutoSync(context: context)
                            }
                        }) {
                            Image(systemName: syncManager.isSyncing ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(syncManager.isSyncing ? .gray : .blue)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .opacity(syncManager.isSyncing ? 0.5 : 0)
                                )
                        }
                        .disabled(syncManager.isSyncing)
                        .opacity(syncManager.isSyncing ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: syncManager.isSyncing)
                    }
                    
                    // Last sync time
                    if let lastSync = syncManager.lastSyncTime {
                        Text("Last synced \(lastSync, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Error details
                    if case .error(let message) = syncManager.syncStatus {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                        
                        if message.contains("no persistent stores") || message.contains("schema mismatch") {
                            Button("Reset Database") {
                                showingDatabaseResetAlert = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(.horizontal)
        .onReceive(NotificationCenter.default.publisher(for: .syncEnabledNotification)) { _ in
            // Trigger initial sync when sync is enabled
            Task {
                await syncManager.performAutoSync(context: context)
            }
        }
        .alert("Reset Database", isPresented: $showingDatabaseResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetDatabase()
            }
        } message: {
            Text("This will delete and recreate your local database. All local data will be lost, but any data you've synced to the server can be downloaded again. Continue?")
        }
        .alert("Consolidate Duplicate Categories", isPresented: $showingConsolidateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Consolidate", role: .destructive) {
                Task {
                    do {
                        try await syncManager.consolidateDuplicateCategoriesInSupabase()
                        // Trigger a sync after consolidation
                        await syncManager.performAutoSync(context: context)
                    } catch {
                        print("Failed to consolidate duplicates: \(error)")
                    }
                }
            }
        } message: {
            Text("This will merge duplicate categories in the cloud that have the same name, color, and symbol. Notes will be reassigned to the primary category. Continue?")
        }
    }
    
    private func resetDatabase() {
        coreDataManager.forceResetDatabase()
    }
}
