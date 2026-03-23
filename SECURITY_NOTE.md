# Security note — Firebase & public repo

`GoogleService-Info.plist` is **gitignored** and must be added locally (copy from `GoogleService-Info.plist.example` and fill from [Firebase Console](https://console.firebase.google.com/) → Project settings → Your apps).

**If this repo was ever public with the real plist in history:** rotate your Firebase **Web API key** and **iOS app** config in Google Cloud / Firebase, then consider [BFG](https://rtyley.github.io/bfg-repo-cleaner/) or `git filter-repo` to purge history (advanced).
