//
//  SplashView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-25.
//

import SwiftUI
import AVFoundation

struct SplashView: View {
    @AppStorage("playStartupSounds") private var playStartupSounds = false
    @State private var popPlayer: AVAudioPlayer?

    var body: some View {
        ContentView()
            .onAppear(perform: playStartupSoundIfEnabled)
    }

    private func playStartupSoundIfEnabled() {
        guard playStartupSounds else { return }
        prepareSounds()
        popPlayer?.play()
    }

    private func prepareSounds() {
        guard popPlayer == nil else { return }
        if let popURL = Bundle.main.url(forResource: "startup_pop", withExtension: "wav") {
            popPlayer = try? AVAudioPlayer(contentsOf: popURL)
            popPlayer?.prepareToPlay()
            popPlayer?.volume = 0.95
        }
    }
}
