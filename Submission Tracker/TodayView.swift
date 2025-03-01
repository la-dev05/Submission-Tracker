//
//  TodayView.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var viewModel: submissionViewModel
    @State private var newItemText = ""
    @State private var isKeyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0
    
    private func addNewItem() {
        if !newItemText.isEmpty {
            withAnimation {
                viewModel.addItem(newItemText)
                newItemText = ""
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: UIConstants.padding) {
                HStack {
                    Button(action: { viewModel.markAsSubmitted() }) {
                        Label("Mark as Submitted", systemImage: "checkmark.circle.fill")
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(UIConstants.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(UIConstants.cornerRadius)
                            .shadow(radius: UIConstants.shadowRadius)
                            .font(.system(size: 18))
                    }
                    .disabled(viewModel.currentItems.isEmpty)
                    .opacity(viewModel.currentItems.isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal)
                
                HStack {
                    TextField("Add new item...", text: $newItemText)
                        .font(.system(size: 18))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .padding(.trailing, 8)
                        .onSubmit(addNewItem)
        
                    Button(action: addNewItem) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(UIConstants.primaryColor)
                            .font(.system(size: 32))
                    }
                    .padding(.trailing, 4)
                }
                .padding(.horizontal)
                
                if viewModel.currentItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No items yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.currentItems) { item in
                            HStack(spacing: 15) {
                                Text("#\(item.displayNumber)")
                                    .foregroundColor(UIConstants.primaryColor)
                                    .font(.system(.body, design: .rounded))
                                    .frame(width: 30, alignment: .leading)
                                
                                Text(item.description)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if let sequence = item.sequenceNumber {
                                    Text("(\(sequence))")
                                        .foregroundColor(.gray)
                                        .font(.system(.subheadline, design: .rounded))
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(UIConstants.secondaryColor.opacity(0.3))
                            .cornerRadius(8)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.removeCurrentItem(viewModel.currentItems[index])
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                if !isKeyboardVisible {
                    Spacer().frame(height: 200)
                }
            }
            
            if !isKeyboardVisible {
                QuickAddItemsView()
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("Today's submission")
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                isKeyboardVisible = true
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
                keyboardHeight = 0
            }
        }
        .animation(.spring(), value: isKeyboardVisible)
    }
}
