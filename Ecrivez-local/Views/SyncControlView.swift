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
    
    @State private var syncOperation: SyncOperation? = nil
    @State private var syncError: String? = nil
    @State private var lastUploadTime: Date? = UserDefaults.standard.object(forKey: "lastUploadTime") as? Date
    @State private var lastDownloadTime: Date? = UserDefaults.standard.object(forKey: "lastDownloadTime") as? Date
    @State private var showingDatabaseResetAlert = false
    
    enum SyncOperation {
        case upload, download, fullSync
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Syncing", isOn: $syncManager.syncEnabled)
                .padding(.horizontal)
            
            if syncManager.syncEnabled {
                // Last sync times
                syncInfoSection
                
                // Operation buttons
                HStack(spacing: 16) {
                    Button(action: { startSync(.upload) }) {
                        VStack {
                            Image(systemName: "arrow.up.to.line")
                                .font(.system(size: 24))
                            Text("Upload")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(syncOperation != nil)
                    
                    Button(action: { startSync(.download) }) {
                        VStack {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 24))
                            Text("Download")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(syncOperation != nil)
                    
                    Button(action: { startSync(.fullSync) }) {
                        VStack {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 24))
                            Text("Full Sync")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(syncOperation != nil)
                }
                .padding(.horizontal)
                
                // Progress indicator
                if let operation = syncOperation {
                    HStack {
                        ProgressView()
                        Text(operationLabel(for: operation))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
                
                // Error message
                if let error = syncError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        if error.contains("no persistent stores") || error.contains("schema mismatch") {
                            Button("Reset Database") {
                                showingDatabaseResetAlert = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .alert("Reset Database", isPresented: $showingDatabaseResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetDatabase()
            }
        } message: {
            Text("This will delete and recreate your local database. All local data will be lost, but any data you've synced to the server can be downloaded again. Continue?")
        }
    }
    
    private var syncInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let lastUploadTime = lastUploadTime {
                Text("Last upload: \(lastUploadTime, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let lastDownloadTime = lastDownloadTime {
                Text("Last download: \(lastDownloadTime, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private func operationLabel(for operation: SyncOperation) -> String {
        switch operation {
        case .upload:
            return "Uploading your data..."
        case .download:
            return "Downloading your data..."
        case .fullSync:
            return "Syncing all data..."
        }
    }
    
    private func startSync(_ operation: SyncOperation) {
        syncOperation = operation
        syncError = nil
        
        Task {
            do {
                switch operation {
                case .upload:
                    try await syncManager.uploadData(context: context)
                    self.lastUploadTime = Date()
                    UserDefaults.standard.set(self.lastUploadTime, forKey: "lastUploadTime")
                    
                case .download:
                    try await syncManager.downloadData(context: context)
                    self.lastDownloadTime = Date()
                    UserDefaults.standard.set(self.lastDownloadTime, forKey: "lastDownloadTime")
                    
                case .fullSync:
                    try await syncManager.performFullSync(context: context)
                    self.lastUploadTime = Date()
                    self.lastDownloadTime = Date()
                    UserDefaults.standard.set(self.lastUploadTime, forKey: "lastUploadTime")
                    UserDefaults.standard.set(self.lastDownloadTime, forKey: "lastDownloadTime")
                }
            } catch {
                syncError = error.localizedDescription
            }
            
            syncOperation = nil
        }
    }
    
    private func resetDatabase() {
        coreDataManager.forceResetDatabase()
        syncError = "Database has been reset. Try downloading your data now."
    }
    
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
