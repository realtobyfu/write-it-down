//
//  CommentRowView.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/6/25.
//

import SwiftUI

struct CommentRowView: View {
    let comment: CommentModel
    let isOwner: Bool
    let onDelete: () -> Void
    let onEdit: (String) -> Void
    
    @State private var isEditing = false
    @State private var editedContent = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("@")
                            .font(.subheadline)
                        
                        Text("\(comment.profiles?.username ?? "User")")
                            .font(.custom("Baskerville", size: 18))
                            .italic()
                    }
                    
                    // Timestamp
                    Text(formattedTimestamp(for: comment.created_at ?? Date()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Inside CommentRowView, replace the current HStack for editing buttons with this:
                if isOwner {
                    HStack(spacing: 12) {
                        Button {
                            // Start editing
                            editedContent = comment.content
                            isEditing = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .opacity(0.7)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button {
                            // Delete comment
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .opacity(0.7)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                }
            }
            
            // Comment content - either static text or edit field
            if isEditing {
                TextField("Edit comment", text: $editedContent)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        onEdit(editedContent)
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(editedContent.isEmpty)
                }
            } else {
                Text(comment.content)
                    .font(.body)
            }
            
            Divider()
        }
        .padding(.vertical, 4)
    }
    
    // Helper to format timestamp as requested
    private func formattedTimestamp(for date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        // Show just one time indicator (minutes, hours, or days)
        if let minutes = components.minute, minutes < 60 {
            return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let days = components.day, days == 1 {
            return "Yesterday"
        } else if let days = components.day, days < 7 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
