import SwiftUI
import UIKit
//  welcomeview.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
            ZStack {
                
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.blue.opacity(0.8),
                        Color.green.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating circles for visual effect
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 250)
                    .blur(radius: 10)
                    .offset(x: 120, y: -250)
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 300)
                    .blur(radius: 20)
                    .offset(x: -150, y: 250)
                
                VStack(spacing: 25) {
                    
                    Spacer()
                    
                    // App Logo
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                    
                    // App Name
                    Text("Stox")
                        .font(.system(size: 55, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Subtitle
                    Text("A Digital Marketplace")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Learn markets, trends, and investing through interactive simulations.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 35)
                        .foregroundColor(.white.opacity(0.75))
                    
                    Spacer()
                    
                    VStack(spacing: 18) {
                        
                        Button {
                            appState.authState = .signup
                            }label: {
                            Text("Build an Account")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(18)
                        }
                        
                        Button(action: {
                            appState.authState = .login
                        }) {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }


// MARK: - CREATE ACCOUNT SCREEN
