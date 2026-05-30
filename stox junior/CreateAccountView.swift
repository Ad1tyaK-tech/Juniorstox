import SwiftUI

struct CreateAccountView: View {

    @EnvironmentObject var appState: AppState

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var isEmailValid: Bool {
        let emailRegex =
        #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return NSPredicate(
            format: "SELF MATCHES %@",
            emailRegex
        ).evaluate(with: email)
    }

    var isPasswordValid: Bool {
        password.count >= 8
    }

    var canCreateAccount: Bool {
        !fullName.isEmpty &&
        isEmailValid &&
        isPasswordValid
    }

    var body: some View {

        ZStack {

            Color.black.ignoresSafeArea()

            VStack {

                // TOP BAR
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

                // CONTENT
                VStack(spacing: 25) {

                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Start your financial journey.")
                        .foregroundColor(.gray)

                    VStack(spacing: 18) {

                        TextField("Full Name", text: $fullName)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(14)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(14)

                        if !email.isEmpty && !isEmailValid {
                            Text("Enter a valid email address")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        SecureField("Password", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(14)

                        if !password.isEmpty && !isPasswordValid {
                            Text("Password must be at least 8 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 30)

                    // CREATE BUTTON
                    Button {

                        appState.fullName = fullName
                        appState.authState = .loggedIn   // 🔥 IMPORTANT FIX

                    } label: {

                        Text("Create Profile")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canCreateAccount ? Color.green : Color.gray.opacity(0.5))
                            .cornerRadius(18)
                            .padding(.horizontal, 30)
                    }
                    .disabled(!canCreateAccount)

                    Spacer()
                }
            }
        }
    }
}
