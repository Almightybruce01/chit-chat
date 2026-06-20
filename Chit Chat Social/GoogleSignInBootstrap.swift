//
//  GoogleSignInBootstrap.swift
//  Chit Chat Social
//
//  Configures Google Sign-In and handles OAuth return URLs (required for iPad).
//

import Foundation
import UIKit
import FirebaseCore
import GoogleSignIn

enum GoogleSignInBootstrap {
    static func configureIfNeeded() {
        guard FirebaseApp.app() != nil,
              let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    @discardableResult
    static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
