//
//  CalendarDayView.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasItems: Int // Changed from bool to int
    let isToday: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(DateFormatter.dayFormatter.string(from: date))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? UIConstants.primaryColor : .primary))
                if hasItems > 0 {
                    Text("\(hasItems)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .white : UIConstants.primaryColor)
                }
            }
            .frame(height: 45)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                            .fill(UIConstants.primaryColor)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                            .stroke(UIConstants.primaryColor, lineWidth: 1)
                    }
                }
            )
        }
    }
}
