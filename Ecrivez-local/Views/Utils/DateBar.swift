//
//  DateBar.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 8/7/24.
//

import SwiftUI

// this is the date bar to be called by
// NoteView to display the date
struct DateBar: View {
    var date: Date
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.blue)
                .font(.title2)
            Text(dateFormatted)
                .font(.headline)
                .foregroundColor(.blue)
            Spacer()
        }
        .padding(5)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding(.horizontal, 10)
    }
    
    // Date formatter for displaying the date
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
//
//#Preview {
//    DateBar()
//}
