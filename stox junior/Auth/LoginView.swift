import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var password = ""

    var canLogin: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {

        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    
                    Button {
                        appState.authState = .welcome
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 25) {
                    
                    Spacer()
                    
                    Text("Login")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text("Welcome back")
                        .foregroundColor(.gray)
                    
                    // EMAIL
                    VStack(alignment: .leading, spacing: 6) {
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // PASSWORD
                    VStack(alignment: .leading, spacing: 6) {
                        
                        SecureField("Password", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // LOGIN BUTTON
                    Button {
                        // simple login (no backend yet)
                        DispatchQueue.main.async {
                            appState.authState = .loggedIn
                        }
                        
                    } label: {
                        
                        Text("Log In")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canLogin ? Color.green : Color.gray)
                            .cornerRadius(14)
                            .padding(.horizontal, 30)
                    }
                    .disabled(!canLogin)
                    
                    Spacer()
                }
            }
        }
    }
}//
//  loginview.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

