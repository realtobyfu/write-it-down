import SwiftUI
import CoreData

struct CategoryEditorListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.index, ascending: true)]
    ) var categories: FetchedResults<Category>

    @State private var showingAddCategoryView = false
    @State private var newCategory: Category? = nil


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
                                    Image(systemName: categories[index].symbol ?? "circle")
                                        .foregroundColor(.white)
                                )
                            Text(categories[index].name ?? "Unnamed Category")
                                .font(.headline)
                                .padding(.leading, 10)

                            Spacer()
                        }
                    }
                }
                .onDelete(perform: deleteCategory)
                .onMove(perform: moveCategory)
            }
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                EditButton()
            }
            
            // "+" Button
            Button(action: {
                newCategory = Category(context: context)
                showingAddCategoryView = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.blue)
                    )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .sheet(isPresented: $showingAddCategoryView) {
                if let newCategory = newCategory {
                    CategoryEditorView(
                        category: newCategory,
                        onSave: {
                            saveContext()
                            self.newCategory = nil
                            showingAddCategoryView = false
                        }
                    )
                }
            }
        }
        .navigationTitle("Categories")
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        var reorderedCategories = categories.map { $0 }
        reorderedCategories.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reorderedCategories.enumerated() {
            category.index = Int16(index)
        }
        saveContext()
    }

    private func deleteUnnamedCategories() {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == nil")
        
        do {
            let categoriesWithNoName = try context.fetch(fetchRequest)
            for category in categoriesWithNoName {
                context.delete(category)
            }
            saveContext()
        } catch {
            print("Error fetching categories with no name: \(error)")
        }
    }

    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let categoryToDelete = categories[index]
            context.delete(categoryToDelete)
        }
        saveContext()
    }


    private func saveContext() {
        do {
            // Filter out categories with no name before saving
            let unnamedCategories = categories.filter { $0.name == nil || $0.name?.isEmpty == true }
            for category in unnamedCategories {
                context.delete(category) // Delete invalid categories
            }

            if context.hasChanges {
                try context.save()
                print("Context saved successfully.")
            }
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
