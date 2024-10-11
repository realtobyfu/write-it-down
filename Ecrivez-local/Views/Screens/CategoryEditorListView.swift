
//
//  CategoryEditorListView.swift
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
                ForEach(categories) { category in
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
                            Text(category.name)
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
        Category(symbol: "book", colorName: "green", name: "Book"),
        Category(symbol: "fork.knife", colorName: "blue", name: "Cooking"),
        Category(symbol: "sun.min", colorName: "yellow", name: "Day"),
        Category(symbol: "movieclapper", colorName: "pink", name: "Movie"),
        Category(symbol: "message.badge.filled.fill", colorName: "brown", name: "Message"),
        Category(symbol: "list.bullet", colorName: "gray", name: "List")
    ]

    static var previews: some View {
        CategoryEditorListView(categories: $categories)
    }
}
