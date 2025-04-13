//
//  Untitled.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct QuickAddItemsView: View {
    @State private var isExpanded = false
    @State private var isEditing = false
    @State private var quickItems = ["TShirt", "Shirt", "Bedsheet", "Pillow Cover", "Pajama", "Bath Towel"]
    @State private var showingAddAlert = false
    @State private var newItemText = ""
    @EnvironmentObject var viewModel: submissionViewModel
    
    var body: some View {
        VStack {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("Quick Add")
                        .font(.headline)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                }
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(UIConstants.secondaryColor)
                .cornerRadius(UIConstants.cornerRadius)
            }
            .padding(.horizontal)
            
            if isExpanded {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button(action: { isEditing.toggle() }) {
                            Text(isEditing ? "Done" : "Edit")
                                .foregroundColor(UIConstants.primaryColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    if isEditing {
                        Button(action: { showingAddAlert = true }) {
                            Image(systemName: "plus.rectangle.fill")
                                .foregroundColor(UIConstants.primaryColor)
                                .font(.system(size: 32))
                        }
                        .padding(.bottom, 8)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 1) {
                        ForEach(quickItems, id: \.self) { item in
                            HStack {
                                if isEditing {
                                    Button(action: {
                                        quickItems.removeAll { $0 == item }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Button(action: {
                                    if !isEditing {
                                        viewModel.addItem(item)
                                    }
                                }) {
                                    Text(item)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(UIConstants.secondaryColor)
                                        .cornerRadius(8)
                                }
                                .disabled(isEditing)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showingAddAlert) {
            NavigationView {
                VStack(spacing: 20) {
                    TextField("Item name", text: $newItemText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            newItemText = ""
                            showingAddAlert = false
                        }
                        
                        Button("Add") {
                            if !newItemText.isEmpty {
                                quickItems.append(newItemText)
                                newItemText = ""
                            }
                            showingAddAlert = false
                        }
                    }
                }
                .navigationTitle("Add Quick Item")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
            }
        }
    }
}


