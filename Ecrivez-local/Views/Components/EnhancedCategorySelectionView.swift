import SwiftUI
import CoreData

struct EnhancedCategorySelectionView: View {
    @Binding var selectedCategory: Category?
    let categories: FetchedResults<Category>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        action: {
                            selectedCategory = category
                        }
                    )
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
                Text(category.name ?? "Untitled")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: category.color ?? "#007AFF") : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}