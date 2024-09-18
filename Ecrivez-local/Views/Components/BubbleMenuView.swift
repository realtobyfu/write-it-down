//
//  CardView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

import SwiftUI

struct BubbleMenuView: View {
    @Binding var showBubbles: Bool
    @Binding var selectedCategory: Category?
    var categories: [Category]
    var onCategorySelected: () -> Void

    var body: some View {
        ZStack {
            if showBubbles {
                HStack(spacing: 20) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            showBubbles = false
                            onCategorySelected()
                        }) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 45, height: 45)
                                .overlay(
                                    Image(systemName: category.symbol)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .offset(y: -100)
                .animation(.spring(response: 0.5, dampingFraction: 0.6))
                .padding(.horizontal, 10)
            }

            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        showBubbles.toggle()
                    }
                }) {
                    Image(systemName: showBubbles ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.red)
                }
                Spacer()
            }
        }
    }
}
