//
//  CategoryEditorView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI
import CoreData

struct CategoryEditorView: View {
    var category: Category?
    
    @State private var name: String
    @State private var symbol: String
    @State private var colorString: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    var onSave: () -> Void

    private let colorMapping: [String: Color] = Dictionary(
        uniqueKeysWithValues: StyleManager.availableColors.map { ($0, StyleManager.color(from: $0)) }
    )

    private let availableSymbols = StyleManager.availableSymbols
    private let availableColors = StyleManager.availableColors
    
    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let symbolColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    init(category: Category? = nil, onSave: @escaping () -> Void) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _symbol = State(initialValue: category?.symbol ?? "")
        _colorString = State(initialValue: category?.colorString ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Live Preview Section
                    previewSection
                    
                    // Name Edit Section
                    nameSection
                    
                    // Icon Selection Section
                    iconSelectionSection
                    
                    // Color Selection Section
                    colorSelectionSection
                }
                .padding()
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if category?.isDefault == true {
                    Text("DEFAULT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                
                VStack(spacing: 12) {
                    // Preview Category Chip
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(selectedColor)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .shadow(radius: 2)
                    )
                    
                    Text("How your category will appear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var nameSection: some View {
        VStack(spacing: 16) {
            Text("Category Name")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Enter category name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }
    
    private var iconSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Category Icon")
                    .font(.headline)
                
                Spacer()
            }
            
            LazyVGrid(columns: symbolColumns, spacing: 12) {
                ForEach(availableSymbols, id: \.self) { symbolName in
                    Button(action: {
                        symbol = symbolName
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(symbol == symbolName ? selectedColor.opacity(0.2) : Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(symbol == symbolName ? selectedColor : Color.clear, lineWidth: 2)
                                )
                            
                            Image(systemName: symbolName)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(symbol == symbolName ? selectedColor : .primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var colorSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Category Color")
                    .font(.headline)
                
                Spacer()
            }
            
            LazyVGrid(columns: colorColumns, spacing: 12) {
                ForEach(availableColors, id: \.self) { colorName in
                    Button(action: {
                        colorString = colorName
                    }) {
                        ZStack {
                            Circle()
                                .fill(colorMapping[colorName] ?? .black)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorString == colorName ? 3 : 0)
                                )
                                .shadow(radius: 2)
                            
                            if colorString == colorName {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var selectedColor: Color {
        return colorMapping[colorString] ?? .blue
    }
    
    private func saveCategory() {
        let categoryToSave: Category
        
        if let existingCategory = category {
            // Editing existing category
            categoryToSave = existingCategory
        } else {
            // Creating new category
            categoryToSave = Category(context: context)
            categoryToSave.id = UUID()
            // Set index for new category (put it at the end)
            let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
            let existingCount = (try? context.count(for: fetchRequest)) ?? 0
            categoryToSave.index = Int16(existingCount)
        }
        
        // Apply all changes
        categoryToSave.name = name
        categoryToSave.symbol = symbol
        categoryToSave.colorString = colorString
        
        onSave()
        dismiss()
    }
}
