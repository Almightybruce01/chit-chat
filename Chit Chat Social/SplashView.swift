//
//  SplashView.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-25.
//

import SwiftUI
import AVFoundation
import UIKit

struct SplashView: View {
    @AppStorage("playStartupSounds") private var playStartupSounds = false
    @State private var popPlayer: AVAudioPlayer?
    @State private var showMain = false

    var body: some View {
        Group {
            if showMain {
                ContentView()
            } else {
                ZStack {
                    Color(UIColor.systemBackground)
                    ProgressView("Loading…")
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            Task { @MainActor in
                await Task.yield()
                showMain = true
            }
            playStartupSoundIfEnabled()
        }
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
