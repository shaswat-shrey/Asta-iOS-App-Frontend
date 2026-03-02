//  LoginView.swift
//  ASTA
//  Created by Shaswat Shrey on 01/02/26.

import SwiftUI

struct LoginView: View {
    
    @State private var isPasswordVisible: Bool = false
    @Binding var isLoggedIn: Bool
    
    @StateObject private var vm = LoginViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                // MARK: - Background Gradient
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.88, blue: 0.90),
                        Color(red: 0.95, green: 0.80, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // MARK: - Icon
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 10)
                    
                    // MARK: - Title
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontDesign(Font.Design.rounded)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Sign in to your account")
                        .foregroundColor(.black)
                        .fontDesign(Font.Design.rounded)
                        .padding(.bottom, 20)
                    
                    
                    // MARK: - Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .fontWeight(.semibold)
                            .fontDesign(Font.Design.rounded)
                            .foregroundColor(.black)
                        
                        ZStack(alignment: .leading) {
                            if vm.email.isEmpty {
                                Text("Enter your username")
                                    .foregroundColor(.black.opacity(0.6))
                                    .fontDesign(Font.Design.rounded)
                                    .padding(.leading, 31)
                            }
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.orange)
                                
                                TextField("", text: $vm.email)
                                    .foregroundColor(.black)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(15)
                    }
                    
                    // MARK: - Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .fontWeight(.semibold)
                            .fontDesign(Font.Design.rounded)
                            .foregroundColor(.black)
                        
                        ZStack(alignment: .leading) {
                            if vm.password.isEmpty {
                                Text("Enter your password")
                                    .fontDesign(Font.Design.rounded)
                                    .foregroundColor(.black.opacity(0.6))
                                    .padding(.leading, 28)
                            }
                            
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.purple)
                                
                                Group {
                                    if isPasswordVisible {
                                        TextField("", text: $vm.password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                    } else {
                                        SecureField("", text: $vm.password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                    }
                                }
                                .foregroundColor(.black)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        isPasswordVisible.toggle()
                                    }
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(30/2)
                    }
                    
                    // MARK: - Sign In Button
                    Button {
                        Task {
                            await vm.login()
                            if vm.isLoggedIn {
                                isLoggedIn = true
                            }
                        }
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontDesign(Font.Design.rounded)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30/2)
                    }
                    .padding(.top, 15)
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)
            }
            // Navigation destination
        }
    }
}
