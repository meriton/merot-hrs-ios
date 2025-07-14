import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image("MerotLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .padding(12)
                    .background(
                        colorScheme == .dark 
                            ? Color(.systemGray2)
                            : Color.clear
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                colorScheme == .dark 
                                    ? Color(.systemGray4) 
                                    : Color.clear, 
                                lineWidth: 1
                            )
                    )
                
                Text("Employer Dashboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(ModernTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(ModernTextFieldStyle())
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await authService.login(email: email, password: password)
                        }
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Signing In...")
                                    .fontWeight(.semibold)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(MerotButtonStyle())
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Login Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authService.errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: authService.errorMessage) { errorMessage in
                showingAlert = errorMessage != nil
            }
        }
    }
}