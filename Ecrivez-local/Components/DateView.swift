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
        HStack {
            if let selectedDate = selectedDate {
                // Display the selected date and provide an option to clear it
                Text("Selected Date: \(selectedDate, formatter: dateFormatter)")
                    .padding()

                Button(action: {
                    self.selectedDate = nil // Clear the date
                }) {
                    Text("-")
                }
            }

            // DatePicker for optional date with default value fallback
            DatePicker("Select Date", selection: Binding(
                get: { selectedDate ?? Date() }, // If nil, return the current date
                set: { newValue in selectedDate = newValue } // Set the new value
            ), displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
    }

    // Helper date formatter for displaying the date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
