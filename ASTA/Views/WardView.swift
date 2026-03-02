//  WardView.swift
//  ASTA
//  Created by Shaswat Shrey on 03/02/26.


import SwiftUI

struct WardView: View {

    @StateObject private var vm = WardViewModel()
    @State private var selectedWard: Ward?
    @Binding var isLoggedIn: Bool
    
    @State private var goToAssitant: Bool = false

    var body: some View {

        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.88, blue: 0.90),
                        Color(red: 0.95, green: 0.80, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    
                    // 🔹 Scrollable Content
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            ForEach(vm.wards) { ward in
                                WardCardView(
                                    title: ward.name.uppercased(),
                                    type: ward.type ?? "Ward",
                                    floor: ward.floor != nil ? "Floor \(ward.floor!)" : "N/A",
                                    occupied: ward.occupied_beds,
                                    total: ward.capacity,
                                    color: .red
                                ) {
                                    vm.setSelectedWard(ward)
                                    selectedWard = ward
                                }
                            }
                            
                        }
                        .padding(.top, 5)
                        .padding(.bottom, 20)
                    }
                    
                    // 🔹 Static Assistant Button (fixed at bottom)
                    HStack {
                        ButtonView(title: "Assistant") {
                            goToAssitant = true
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                }
                .navigationDestination(isPresented: $goToAssitant) {
                    AIChatView()
                }
            }
            
            .onAppear {
                Task {
                    await vm.fetchWards()
                }
            }
            .navigationDestination(item: $selectedWard) { ward in
                ICUWardView(ward: ward)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ward View")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                            UserDefaults.standard.removeObject(forKey: "userId")
                            UserDefaults.standard.removeObject(forKey: "orgId")
                            UserDefaults.standard.removeObject(forKey: "wardId")
                            isLoggedIn = false
                        } label: {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)          // removes system style
                        .tint(.clear)                 // prevents tint background
                }
            }
        }
    }
}

