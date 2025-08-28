import SwiftUI
import CoreData

struct EnhancedCategorySelectionView: View {
    @Binding var selectedCategory: Category?
    let categories: [Category]
    
    /// Sorted categories with selected category first for better UX
    private var sortedCategories: [Category] {
        guard let selected = selectedCategory else { return categories }
        
        var sorted = categories.filter { $0.id != selected.id }
        sorted.insert(selected, at: 0)
        return sorted
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(sortedCategories.enumerated()), id: \.element.id) { index, category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        action: {
                            selectedCategory = category
                        }
                    )
                    
                    // Add extra spacing after the selected category (first item)
                    if index == 0 && sortedCategories.count > 1 {
                        Spacer()
                            .frame(width: 8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.symbol ?? "folder")
                    .font(.caption)
//                Text(category.name ?? "Untitled")
//                    .font(.caption)
            }
            .frame(width: 40, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
