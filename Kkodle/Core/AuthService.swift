//
//  AuthService.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import Foundation
import FirebaseAuth
import Observation

@Observable
final class AuthService {
    private(set) var userId: String?
    private(set) var isSigningIn = false
    private(set) var signInError: String?

    func signInIfNeeded() async {
        if let existing = Auth.auth().currentUser {
            userId = existing.uid
            return
        }
        isSigningIn = true
        signInError = nil
        do {
            let result = try await Auth.auth().signInAnonymously()
            userId = result.user.uid
        } catch {
            signInError = error.localizedDescription
        }
        isSigningIn = false
    }
}
