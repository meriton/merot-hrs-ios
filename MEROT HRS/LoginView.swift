import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var userType = "employer"
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if horizontalSizeClass == .regular && geometry.size.width > 600 {
                    // iPad layout - side by side
                    HStack(spacing: 0) {
                        // Left side - branding
                        VStack {
                            Spacer()
                            
                            Image("MerotLogo")
                                .renderingMode(colorScheme == .dark ? .template : .original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .foregroundColor(colorScheme == .dark ? .white : nil)
                                .padding(20)
                            
                            Text("Your Team, Beyond Borders.")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
                        
                        // Right side - login form
                        VStack(spacing: 30) {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                Text(userType == "admin" ? "Admin Dashboard" : "Employer Dashboard")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Sign in to your account")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User Type")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Picker("User Type", selection: $userType) {
                                        Text("Employer").tag("employer")
                                        Text("Admin").tag("admin")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
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
                                
                                Button(action: {
                                    Task {
                                        await authService.login(email: email, password: password, userType: userType)
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
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 60)
                    }
                } else {
                    // iPhone layout - original vertical design
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image("MerotLogo")
                            .renderingMode(colorScheme == .dark ? .template : .original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .foregroundColor(colorScheme == .dark ? .white : nil)
                            .padding(12)
                        
                        Text(userType == "admin" ? "Admin Dashboard" : "Employer Dashboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User Type")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Picker("User Type", selection: $userType) {
                                        Text("Employer").tag("employer")
                                        Text("Admin").tag("admin")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
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
                                    await authService.login(email: email, password: password, userType: userType)
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
                }
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