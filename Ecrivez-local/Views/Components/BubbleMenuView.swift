//
//  CardView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

// Enhanced BubbleMenuView with iPad support
struct BubbleMenuView: View {
    @Binding var showBubbles: Bool
    @Binding var selectedCategory: Category?
    var categories: [Category]
    var onCategorySelected: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ZStack {
            if showBubbles {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIPad ? 30 : 20) {
                        ForEach(categories.sorted(by: {$0.index < $1.index }), id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                showBubbles = false
                                onCategorySelected()
                            }) {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: isIPad ? 60 : 45, height: isIPad ? 60 : 45)
                                        .overlay(
                                            Image(systemName: category.symbol ?? "circle")
                                                .foregroundColor(Color.background)
                                                .font(isIPad ? .title2 : .body)
                                        )
                                    
                                    if isIPad, let name = category.name {
                                        Text(name)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, isIPad ? 20 : 10)
                    .padding(.top, 5)
                    .padding(.bottom, isIPad ? 20 : 15)
                    .background(Color.background)
                }
                .padding(.top, showBubbles ? 8: 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6))
                .background(Color.background)
            }
        }
    }
}
