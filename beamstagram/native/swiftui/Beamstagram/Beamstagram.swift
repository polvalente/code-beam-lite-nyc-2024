//
//  Beamstagram.swift
//  Beamstagram
//

import SwiftUI


class IRESEnvironment: ObservableObject {
    @Published var device: UnsafePointer<iree_hal_device_t>?
    @Published var vmInstance: UnsafePointer<iree_vm_instance_t>?
    @Published var bytecodeSize: UInt64 = 0
    @Published var bytecodePointer: UnsafePointer<CUnsignedChar>? = nil

}

@main
struct Beamstagram: App {
    @StateObject var ireeEnv = IRESEnvironment()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ireeEnv)
        }
    }
}
