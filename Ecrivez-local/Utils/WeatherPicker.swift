//
//  WeatherPicker.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 8/2/24.
//

import SwiftUI

struct WeatherPicker: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedIndex = 0
    @Binding var weather: String
    
    let weatherOptions = ["☀️ Sunny", "⛅ Partly Cloudy", "🌩️ Stormy", "☁️ Cloudy", "🌧 Rainy", "❄️ Snowy"]
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Text("How is the Weather?")
                    .font(.headline)

                Text(weatherOptions[selectedIndex].split(separator: " ")[0])
                    .font(.system(size: 100))
                    .padding()
                
                Picker("Select the Weather", selection: $selectedIndex) {
                    Text("Sunny").tag(0)
                    Text("Partly Cloudy").tag(1)
                    Text("Stormy").tag(2)
                    Text("Cloudy").tag(3)
                    Text("Rainy").tag(4)
                    Text("Snowy").tag(5)
                }
//                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Spacer()
                Button(action: {
                    // updates the weather on selection
                    weather = weatherOptions[selectedIndex].split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).dropFirst().joined(separator: " ")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Confirm")
//                    Image(systemName: "checkmark.circle.fill")
//                        .font(.system(size: 52))
//                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
                .frame(alignment: .center)
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct WeatherPicker_Previews: PreviewProvider {
    @State static var weather = ""
    
    static var previews: some View {
        WeatherPicker(weather: $weather)
    }
}
