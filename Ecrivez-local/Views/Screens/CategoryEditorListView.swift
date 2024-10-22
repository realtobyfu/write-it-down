
//
//  CategoryEditorListView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct CategoryEditorListView: View {
    @Environment(\.managedObjectContext) private var context
    var categories: FetchedResults<Category>
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(categories.indices, id: \.self) { index in
                    NavigationLink(
                        destination: CategoryEditorView(
                            category: categories[index],
                            onSave: {
                                saveContext()
                            }
                        )
                    ) {
                        HStack {
                            Circle()
                                .fill(categories[index].color)
                                .frame(width: 45, height: 45)
                                .overlay(
                                    Image(systemName: categories[index].symbol!)
                                        .foregroundColor(.white)
                                )
                            Text(categories[index].name!)
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

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
