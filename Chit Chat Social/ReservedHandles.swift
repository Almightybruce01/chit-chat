//
//  ReservedHandles.swift
//  Chit Chat Social
//
//  System reserves (major brands) + admin-managed holds (you add names manually).
//  We do not scrape third-party sites; add celebrity or VIP handles yourself in Admin → Holds.
//

import Foundation

enum ReservedHandles {
    private static let adminHeldKey = "chitchatsocial.admin.held_usernames"
    private static let handoffEmailKey = "chitchatsocial.admin.handoff_email_by_username"

    /// Major brands and system names — cannot be released in-app.
    private static let systemBrands: [String] = [
        "google", "microsoft", "apple", "meta", "amazon", "tesla", "nvidia", "qualcomm",
        "facebook", "instagram", "twitter", "x", "youtube", "tiktok", "snapchat", "linkedin",
        "netflix", "spotify", "uber", "lyft", "airbnb", "doordash", "instacart", "grubhub",
        "paypal", "venmo", "slack", "zoom", "dropbox", "notion", "figma", "adobe", "canva",
        "reddit", "pinterest", "twitch", "discord", "roblox", "epicgames",
        "salesforce", "oracle", "cisco", "ibm", "intel", "amd", "dell", "hp",
        "samsung", "lg", "sony", "disney", "warner", "paramount", "hbo", "cnn", "fox", "espn",
        "verizon", "att", "tmobile", "sprint", "comcast", "xfinity",
        "walmart", "wal mart", "target", "costco", "bestbuy", "gamestop", "ikea", "wayfair",
        "lowes", "lowe", "homedepot", "home depot", "acehardware", "napa", "autozone", "oreilly",
        "sephora", "ulta", "macys", "nordstrom", "kohls", "jcpenney", "gap", "oldnavy",
        "cvs", "walgreens", "riteaid", "overstock",
        "mcdonalds", "mcdonald", "macdonalds", "mcdonald's", "starbucks", "cocacola", "coca cola", "pepsi",
        "dominos", "pizzahut", "tacobell", "wendys", "burgerking", "subway", "chickfila", "chick-fil-a",
        "dunkin", "dunkindonuts", "chipotle", "panera", "pandaexpress", "kfc", "popeyes",
        "kroger", "safeway", "albertsons", "publix", "wegmans", "wholefoods", "traderjoes",
        "chase", "bankofamerica", "wellsfargo", "amex", "americanexpress", "citibank", "capitalone",
        "geico", "statefarm", "progressive", "allstate", "libertymutual", "nationwide",
        "ford", "gm", "chevrolet", "toyota", "honda", "bmw", "mercedes", "benz", "hyundai", "kia", "nissan",
        "exxon", "shell", "bp", "chevron", "mobil", "texaco",
        "fedex", "ups", "usps", "dhl", "amazon",
        "delta", "united", "americanairlines", "southwest", "jetblue", "alaskaairlines",
        "hilton", "marriott", "hyatt", "ihg", "wyndham", "airbnb",
        "nba", "nfl", "nhl", "mlb", "mls", "espn", "bleacherreport", "sportingnews",
        "admin", "support", "help", "official", "verified", "moderator", "system",
        "chitchat", "chit chat", "chitchatsocial",
    ]

    private static let systemReserved: Set<String> = {
        var set = Set<String>()
        for b in systemBrands {
            let low = b.lowercased()
            set.insert(low)
            set.insert(low.replacingOccurrences(of: " ", with: ""))
            set.insert(low.replacingOccurrences(of: " ", with: "_"))
            set.insert(low.replacingOccurrences(of: "'", with: ""))
            set.insert(low.replacingOccurrences(of: "-", with: ""))
        }
        return set
    }()

    static func normalizedKey(_ username: String) -> String {
        username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
    }

    static func isSystemReserved(_ username: String) -> Bool {
        systemReserved.contains(normalizedKey(username))
    }

    private static func adminHeldSet() -> Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: adminHeldKey) ?? []
        return Set(arr.map { normalizedKey($0) })
    }

    static func adminHeldUsernamesSorted() -> [String] {
        (UserDefaults.standard.stringArray(forKey: adminHeldKey) ?? []).sorted()
    }

    static func isAdminHeld(_ username: String) -> Bool {
        adminHeldSet().contains(normalizedKey(username))
    }

    /// Blocks new signups and renames (except admin flows that release holds).
    static func isReserved(_ username: String) -> Bool {
        let k = normalizedKey(username)
        return systemReserved.contains(k) || adminHeldSet().contains(k)
    }

    @discardableResult
    static func addAdminHeldUsername(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard trimmed.count >= 3 else { return "Username must be at least 3 characters." }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return "Only letters, numbers, . and _."
        }
        let k = normalizedKey(trimmed)
        if systemReserved.contains(k) { return "That name is already a system-protected reserve." }
        var arr = UserDefaults.standard.stringArray(forKey: adminHeldKey) ?? []
        if arr.contains(where: { normalizedKey($0) == k }) { return "Already on your hold list." }
        arr.append(k)
        UserDefaults.standard.set(arr, forKey: adminHeldKey)
        return nil
    }

    static func removeAdminHeldUsername(_ raw: String) {
        let k = normalizedKey(raw)
        var arr = UserDefaults.standard.stringArray(forKey: adminHeldKey) ?? []
        arr.removeAll { normalizedKey($0) == k }
        UserDefaults.standard.set(arr, forKey: adminHeldKey)
    }

    // MARK: - Optional “intended owner” note (local only; not legal verification)

    static func handoffEmail(forUsername username: String) -> String? {
        let map = UserDefaults.standard.dictionary(forKey: handoffEmailKey) as? [String: String] ?? [:]
        return map[normalizedKey(username)]
    }

    static func setHandoffEmail(forUsername username: String, email: String) {
        let key = normalizedKey(username)
        var map = UserDefaults.standard.dictionary(forKey: handoffEmailKey) as? [String: String] ?? [:]
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if e.isEmpty {
            map.removeValue(forKey: key)
        } else {
            map[key] = e
        }
        UserDefaults.standard.set(map, forKey: handoffEmailKey)
    }
}
