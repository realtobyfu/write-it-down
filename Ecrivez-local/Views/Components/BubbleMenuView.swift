//
//  CardView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct BubbleMenuView: View {
    @Binding var showBubbles: Bool
    @Binding var selectedCategory: Category?
    var categories: [Category]
    var onCategorySelected: () -> Void

    var body: some View {
        ZStack {
            if showBubbles {

                ScrollView(.horizontal, showsIndicators: false) { // Add scrolling
                    HStack(spacing: 20) {
                        ForEach(categories.sorted(by: {$0.index < $1.index }), id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                showBubbles = false
                                onCategorySelected()
                            }) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 45, height: 45)
                                    .overlay(
                                        Image(systemName: category.symbol ?? "circle")
                                            .foregroundColor(Color.background)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
//                    .padding(.bottom, 75)

                    .background(Color.background)

                }
                .padding(.top, 8)
                .padding(.bottom, 15)
                .animation(.spring(response: 0.5, dampingFraction: 0.6))
                .background(Color.background)
            }


//            HStack {
//                Spacer()
//                Button(action: {
//                    withAnimation {
//                        showBubbles.toggle()
//                    }
//                }) {
//                    Image(systemName: showBubbles ? "minus.circle.fill" : "plus.circle.fill")
//                        .font(.system(size: 52))
//                        .foregroundColor(.red)
//                }
//                Spacer()
//            }
        }
    }
}
