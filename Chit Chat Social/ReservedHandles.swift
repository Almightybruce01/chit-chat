//
//  ReservedHandles.swift
//  Chit Chat Social
//
//  Major brands and entities — these usernames cannot be claimed by users.
//  Covers Google, Microsoft, McDonald's, Lowe's, and every major business.
//

import Foundation

enum ReservedHandles {
    /// Major brands, celebrities, and system names — cannot be claimed. Covers variants (spaces, no spaces, apostrophes).
    private static let reserved: Set<String> = {
        let brands = [
            // Tech
            "google", "microsoft", "apple", "meta", "amazon", "tesla", "nvidia", "qualcomm",
            "facebook", "instagram", "twitter", "x", "youtube", "tiktok", "snapchat", "linkedin",
            "netflix", "spotify", "uber", "lyft", "airbnb", "doordash", "instacart", "grubhub",
            "paypal", "venmo", "slack", "zoom", "dropbox", "notion", "figma", "adobe", "canva",
            "reddit", "pinterest", "twitch", "discord", "roblox", "epicgames",
            "salesforce", "oracle", "cisco", "ibm", "intel", "amd", "dell", "hp",
            "samsung", "lg", "sony", "disney", "warner", "paramount", "hbo", "cnn", "fox", "espn",
            "verizon", "att", "tmobile", "sprint", "comcast", "xfinity",
            // Retail
            "walmart", "wal mart", "target", "costco", "bestbuy", "gamestop", "ikea", "wayfair",
            "lowes", "lowe", "homedepot", "home depot", "acehardware", "napa", "autozone", "oreilly",
            "sephora", "ulta", "macys", "nordstrom", "kohls", "jcpenney", "gap", "oldnavy",
            "cvs", "walgreens", "riteaid", "overstock",
            // Food & Drink
            "mcdonalds", "mcdonald", "macdonalds", "mcdonald's", "starbucks", "cocacola", "coca cola", "pepsi",
            "dominos", "pizzahut", "tacobell", "wendys", "burgerking", "subway", "chickfila", "chick-fil-a",
            "dunkin", "dunkindonuts", "chipotle", "panera", "pandaexpress", "kfc", "popeyes",
            "kroger", "safeway", "albertsons", "publix", "wegmans", "wholefoods", "traderjoes",
            // Finance & Insurance
            "chase", "bankofamerica", "wellsfargo", "amex", "americanexpress", "citibank", "capitalone",
            "geico", "statefarm", "progressive", "allstate", "libertymutual", "nationwide",
            // Automotive
            "ford", "gm", "chevrolet", "toyota", "honda", "bmw", "mercedes", "benz", "hyundai", "kia", "nissan",
            "exxon", "shell", "bp", "chevron", "mobil", "texaco",
            // Shipping & Logistics
            "fedex", "ups", "usps", "dhl", "amazon",
            // Travel & Hospitality
            "delta", "united", "americanairlines", "southwest", "jetblue", "alaskaairlines",
            "hilton", "marriott", "hyatt", "ihg", "wyndham", "airbnb",
            // Sports & Media
            "nba", "nfl", "nhl", "mlb", "mls", "espn", "bleacherreport", "sportingnews",
            "admin", "support", "help", "official", "verified", "moderator", "system",
            "chitchat", "chit chat", "chitchatsocial"
        ]
        var set = Set<String>()
        for b in brands {
            let low = b.lowercased()
            set.insert(low)
            set.insert(low.replacingOccurrences(of: " ", with: ""))
            set.insert(low.replacingOccurrences(of: " ", with: "_"))
            set.insert(low.replacingOccurrences(of: "'", with: ""))
            set.insert(low.replacingOccurrences(of: "-", with: ""))
        }
        return set
    }()

    static func isReserved(_ username: String) -> Bool {
        let key = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
        return reserved.contains(key)
    }
}
