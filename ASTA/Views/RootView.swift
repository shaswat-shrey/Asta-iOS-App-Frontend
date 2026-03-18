//  RootView.swift
//  ASTA
//  Created by Shaswat Shrey on 12/02/26.

import SwiftUI

struct RootView: View {

    @StateObject private var loginVM = LoginViewModel()

    var body: some View {
        if loginVM.isLoggedIn {
            WardView()
                .environmentObject(loginVM)
        } else {
            LoginView()
                .environmentObject(loginVM)
        }
    }
}
