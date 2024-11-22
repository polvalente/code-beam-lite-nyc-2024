//
//  ContentView.swift
//  Beamstagram
//

import SwiftUI
import LiveViewNative
import LiveViewNativeLiveForm

struct ContentView: View {
    var body: some View {
        #LiveView(
            .automatic(
                development: .localhost(path: "/image_processing"),
                production: URL(string: "https://example.com")!
            ),
            addons: [
                .liveForm,
                .nxAddon
            ]
        ) {
            ConnectingView()
        } disconnected: {
            DisconnectedView()
        } reconnecting: { content, isReconnecting in
            ReconnectingView(isReconnecting: isReconnecting) {
                content
            }
        } error: { error in
            ErrorView(error: error)
        }
    }
}
