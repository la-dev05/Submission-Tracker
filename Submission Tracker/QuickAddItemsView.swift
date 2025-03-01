//
//  Untitled.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct QuickAddItemsView: View {
    let commonItems = ["Tshirt", "Shirt", "Pajama", "Bed Sheet", "Pillow Cover", "Jeans"]
    @EnvironmentObject var viewModel: submissionViewModel
    @State private var isExpanded = true
    @State private var dragOffset: CGFloat = 0
    
//    private func getNextNumberForItem(_ item: String) -> Int {
//        return viewModel.currentItems
//            .filter { $0.description.starts(with: item) }
//            .compactMap { $0.sequenceNumber }
//            .max()
//            .map { $0 + 1 } ?? 1
//    }
    
    private func addCommonItem(_ item: String) {
        let itemName = item
        viewModel.addItem(itemName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Drag indicator bar
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .cornerRadius(2)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            Text("Quick Add")
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 90, maximum: 140))
                ], spacing: 10) {
                    ForEach(commonItems, id: \.self) { item in
                        Button(action: { addCommonItem(item) }) {
                            Text(item)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                                .background(UIConstants.primaryColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .background(
            Color(UIColor.systemBackground)
                .opacity(0.95)
                .edgesIgnoringSafeArea(.bottom)
        )
        .shadow(color: Color.black.opacity(0.05),
                radius: 20, x: 0, y: -10)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    let translation = gesture.translation.height
                    dragOffset = translation
                }
                .onEnded { gesture in
                    let translation = gesture.translation.height
                    let velocity = gesture.velocity.height
                    
                    withAnimation(.spring()) {
                        dragOffset = 0
                        if abs(translation) > 50 || abs(velocity) > 500 {
                            isExpanded.toggle()
                        }
                    }
                }
        )
        .animation(.spring(), value: isExpanded)
    }
}

