//  WardView.swift
//  ASTA
//  Created by Shaswat Shrey on 03/02/26.


import SwiftUI

struct WardView: View {
    @EnvironmentObject var loginVM: LoginViewModel
    @StateObject private var vm = WardViewModel()
    @State private var selectedWard: Ward?
    @State private var showMenu: Bool = false
    @State private var allowNotifications: Bool = false
//    @Binding var isLoggedIn: Bool
    
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
                    //                    HStack {
                    //                        ButtonView(title: "Assistant") {
                    //                            goToAssitant = true
                    //                        }
                    //                    }
                    //                    .padding(.vertical, 16)
                    //                    .padding(.horizontal, 20)
                    //                }
                    //                .navigationDestination(isPresented: $goToAssitant) {
                    //                    AIChatView()
                    //                }
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
                            loginVM.logout()
                        } label: {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)          // removes system style
                        .tint(.clear)                 // prevents tint background
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showMenu.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                        .buttonStyle(.plain)
                        .tint(.clear)
                        .popover(isPresented: $showMenu) {
                            HStack {
                                Label("Notifications", systemImage: "bell")
                                Spacer()
                                Toggle("", isOn: $allowNotifications)
                                    .labelsHidden()
                                    .tint(.red)
                            }
                            .padding()
                            .frame(width: 240)
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
            }
        }
    }
}

//struct MenuPanelView: View {
//    @Binding var allowNotifications: Bool
//
//    var body: some View {
//        Toggle("Notifications", isOn: $allowNotifications)
//            .padding()
//            .background(Color.white)
//            .cornerRadius(15)
//            .shadow(radius: 10)
//            .frame(width: 220)
//    }
//}
