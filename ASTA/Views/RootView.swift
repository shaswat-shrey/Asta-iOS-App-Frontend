//  RootView.swift
//  ASTA
//  Created by Shaswat Shrey on 12/02/26.

import SwiftUI

struct RootView: View {

    @State private var isLoggedIn =
        UserDefaults.standard.string(forKey: "userId") != nil

    var body: some View {
        if isLoggedIn {
            WardView(isLoggedIn: $isLoggedIn)
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}
