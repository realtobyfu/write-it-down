//
//  CategoryEditorView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct CategoryEditorView: View {
    @Binding var category: Category

    let colorMapping: [String: Color] = [
        "green": .green,
        "blue": .blue,
        "yellow": .yellow,
        "pink": .pink,
        "brown": .brown,
        "gray": .gray,
        "red": .red,
        "purple": .purple,
        "orange": .orange,
        "teal": .teal,
        "indigo": .indigo
    ]

    let availableSymbols = ["book", "fork.knife", "sun.min", "movieclapper", "message.badge.filled.fill", "list.bullet", "paperplane"]
    let availableColors = ["green", "blue", "yellow", "pink", "brown", "gray", "red", "purple", "orange", "teal", "indigo"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Edit Category Name
            Text("Category Name")
                .font(.headline)
            TextField("Enter category name", text: $category.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
            
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

            Divider().padding(.vertical, 10)

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
                                .fill(colorMapping[colorName] ?? .black)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(category.colorName == colorName ? Color.blue : Color.clear, lineWidth: 3)
                                )
                        }
                    }
                }
                .padding(.vertical, 10)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Edit Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct CategoryEditorView_Previews: PreviewProvider {
    @State static var sampleCategory = Category(symbol: "book", colorName: "green", name: "Sample Category")

    static var previews: some View {
        CategoryEditorView(category: $sampleCategory)
    }
}
