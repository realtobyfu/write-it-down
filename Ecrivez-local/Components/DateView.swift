//
//  DatePicker.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 8/14/24.
//

import SwiftUI

struct DateView: View {
    @Binding var selectedDate: Date?

    var body: some View {
        VStack {
            if let selectedDate = selectedDate {
                // Display the selected date and provide an option to clear it
                Text("Selected Date: \(selectedDate, formatter: dateFormatter)")
                    .padding()

                Button(action: {
                    self.selectedDate = nil // Clear the date
                }) {
                    Text("Clear Date")
                }
            } else {
                // Allow the user to select a date
                DatePicker("Select Date", selection: Binding($selectedDate, Date()), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
            }
        }
    }

    // Helper date formatter for displaying the date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
