import SwiftUI

struct DashboardTabButton: View {

    let title: String
    let selected: Bool

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(selected ? .black : .white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    selected
                    ? Color.green
                    : Color.white.opacity(0.08)
                )
                .cornerRadius(12)
        }
    }
}//
//  tabbutton.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

