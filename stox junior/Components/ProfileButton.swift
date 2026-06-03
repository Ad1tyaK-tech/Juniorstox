import SwiftUI

struct ProfileButton: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        let initials = appState.fullName
            .split(separator: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()

        return Group {

            if let image = appState.profileImage {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else {

                Text(initials.isEmpty ? "?" : initials)
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
        }
        .frame(width: 38, height: 38)
        .background(Color.gray.opacity(0.4))
        .clipShape(Circle())
    }
}//
//  profilebutton.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

