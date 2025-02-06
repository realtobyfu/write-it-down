//
//  UserDefaultsAuthStorage.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/31/25.
//

import Foundation
import Supabase
import Boutique

/// Boutique-based AuthLocalStorage for Supabase sessions.
//final class BoutiqueAuthStorage: AuthLocalStorage, @unchecked Sendable {
//    
//    // 1) Use `@StoredValue<Data>` or `@SecurelyStoredValue<Data>`,
//    //    depending on whether you want encryption/keychain storage or not.
//    //    If you want encryption, switch to `@SecurelyStoredValue`.
//    @StoredValue<Data>(key: "SupabaseSessionData", defaultValue: nil)
//    private var supabaseSessionData
//    
//    // MARK: - AuthLocalStorage Conformance
//    
//    func store(key: String, value: Data) throws {
//        // For Supabase, the `key` is typically "supabase.authToken"
//        // or something, but they’ll call this for any key it uses.
//        supabaseSessionData = value
//    }
//    
//    func retrieve(key: String) throws -> Data? {
//        supabaseSessionData
//    }
//    
//    func remove(key: String) throws {
//        supabaseSessionData = nil
//    }
//}
