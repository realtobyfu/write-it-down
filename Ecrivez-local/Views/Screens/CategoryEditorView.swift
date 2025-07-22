//
//  CategoryEditorView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var category: Category
    
    @State private var name: String
    @State private var symbol: String
    @State private var colorString: String
    
    @Environment(\.presentationMode) var presentationMode
    var onSave: () -> Void  // No need to pass the `Category` back, we just save it

    private let colorMapping: [String: Color] = Dictionary(
        uniqueKeysWithValues: StyleManager.availableColors.map { ($0, StyleManager.color(from: $0)) }
    )

    private let availableSymbols = StyleManager.availableSymbols
    private let availableColors = StyleManager.availableColors

    init(category: Category, onSave: @escaping () -> Void) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category.name ?? "")
        _symbol = State(initialValue: category.symbol ?? "")
        _colorString = State(initialValue: category.colorString ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Show notice for default categories
            if category.isDefault {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("This is a default category and cannot be edited")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Edit Category Name
            Text("Category Name")
                .font(.headline)
            TextField("Enter category name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
                .disabled(category.isDefault)
            
            // Symbol selection
            Text("Select Icon")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableSymbols, id: \.self) { symbol in
                        Button(action: {
                            self.symbol = symbol
                        }) {
                            Image(systemName: symbol)
                                .font(.largeTitle)
                                .foregroundColor(self.symbol == symbol ? .blue : .primary)
                                .padding()
                                .background(
                                    Circle()
                                        .stroke(self.symbol == symbol ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .disabled(category.isDefault)
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
                    ForEach(availableColors, id: \.self) { colorString in
                        Button(action: {
                            self.colorString = colorString
                        }) {
                            Circle()
                                .fill(colorMapping[colorString] ?? .black)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(self.colorString == colorString ? Color.blue : Color.clear, lineWidth: 3)
                                )
                        }
                        .disabled(category.isDefault)
                    }
                }
                .padding(.vertical, 10)
            }

            Spacer()
            
            // Confirm Button
            Button(action: {
                // Update the existing category (only if not default)
                if !category.isDefault {
                    category.name = self.name
                    category.symbol = self.symbol
                    category.colorString = self.colorString
                }
                                
                onSave()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Confirm")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

        }
        .padding()
        .navigationTitle("Edit Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}


//struct CategoryEditorView_Previews: PreviewProvider {
//    @State static var sampleCategory = Category(symbol: "book", colorString: "green", name: "Sample Category")
//
//    static var previews: some View {
//        CategoryEditorView(category: sampleCategory)
//    }
//}
