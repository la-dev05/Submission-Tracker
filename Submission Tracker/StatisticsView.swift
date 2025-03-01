//
//  StatisticsView.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var viewModel: submissionViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total Items Card
                StatCard(title: "Total Items", value: "\(viewModel.history.values.flatMap { $0 }.count)")
                
                // Monthly Distribution
                VStack(alignment: .leading) {
                    Text("Monthly Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.getMonthlyStats(), id: \.month) { stat in
                                VStack {
                                    Text("\(stat.count)")
                                        .font(.title2.bold())
                                    Text(stat.month.formatted(.dateTime.month().year()))
                                        .font(.caption)
                                }
                                .frame(width: 100)
                                .padding()
                                .background(UIConstants.secondaryColor)
                                .cornerRadius(UIConstants.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Item Type Distribution
                VStack(alignment: .leading) {
                    Text("Item Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.getStatistics(), id: \.name) { stat in
                        HStack {
                            Text(stat.name)
                            Spacer()
                            Text("\(stat.count) (\(String(format: "%.1f", stat.percentage))%)")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                .background(UIConstants.secondaryColor.opacity(0.3))
                .cornerRadius(UIConstants.cornerRadius)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
    }
}
