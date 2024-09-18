//
//  CategorySettingsView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct CategoryEditorView: View {
    @Binding var category: Category

    let availableSymbols = ["book", "fork.knife", "sun.min", "movieclapper", "clapperboard", "paperplane"]
    let availableColors = ["green", "blue", "yellow", "pink", "brown", "gray", "red", "purple", "orange", "teal", "indigo"]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Edit \(category.symbol.capitalized)")
                .font(.title2)
                .padding(.bottom, 20)

            // Symbol selection
            Text("Select Icon")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableSymbols, id: \.self) { symbol in
                        Button(action: {
                            category.symbol = symbol
                        }) {
                            Image(systemName: symbol)
                                .font(.largeTitle)
                                .foregroundColor(category.symbol == symbol ? .blue : .primary)
                                .padding()
                                .background(
                                    Circle()
                                        .stroke(category.symbol == symbol ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.vertical, 10)
            }

            Divider().padding(.vertical, 20)

            // Color selection
            Text("Select Color")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableColors, id: \.self) { colorName in
                        Button(action: {
                            category.colorName = colorName
                        }) {
                            Circle()
                                .fill(Color(colorName))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(category.colorName == colorName ? Color.blue : Color.clear, lineWidth: 3)
                                )
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
    }
}
