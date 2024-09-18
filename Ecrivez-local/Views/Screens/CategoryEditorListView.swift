
//
//  CategorySettingsView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct CategoryEditorListView: View {
    @Binding var categories: [Category]
    @State private var selectedCategory: Category?

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(categories, id: \.self) { category in
                    NavigationLink(
                        destination: CategoryEditorView(category: $categories[categories.firstIndex(of: category)!])
                    ) {
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 45, height: 45)
                                .overlay(
                                    Image(systemName: category.symbol)
                                        .foregroundColor(.white)
                                )
                            Text(category.symbol.capitalized)
                                .font(.headline)
                                .padding(.leading, 10)

                            Spacer()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Categories")
    }
}

struct CategoryEditorListView_Previews: PreviewProvider {
    @State static var categories: [Category] = [
        Category(symbol: "book", colorName: "green"),
        Category(symbol: "fork.knife", colorName: "blue"),
        Category(symbol: "sun.min", colorName: "yellow"),
        Category(symbol: "movieclapper", colorName: "pink"),
        Category(symbol: "clapperboard", colorName: "brown"),
        Category(symbol: "paperplane", colorName: "gray")
    ]
    
    static var previews: some View {
        CategoryEditorListView(categories: $categories)
    }
}
