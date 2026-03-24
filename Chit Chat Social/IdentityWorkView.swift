import SwiftUI

struct SocialLinksView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section("Connected Platforms") {
                ForEach(SocialPlatform.allCases) { platform in
                    Toggle(
                        platform.displayName,
                        isOn: Binding(
                            get: { appState.currentUser.linkedPlatforms.contains(platform) },
                            set: { _ in appState.togglePlatformLink(platform) }
                        )
                    )
                }
            }
            Section {
                Text("Connected platforms power discovery and cross-post strategy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Social Integrations")
    }
}

struct ResumeEnterpriseView: View {
    @EnvironmentObject private var appState: AppState
    @State private var contractTitle = ""
    @State private var budget = ""
    @State private var location = ""
    @State private var localHire = true
    @State private var listingTitle = ""
    @State private var listingPrice = ""
    @State private var listingCategory = ""

    var body: some View {
        Form {
            Section("Resume") {
                TextField("Headline", text: $appState.resume.headline)
                TextField("Years experience", value: $appState.resume.yearsExperience, format: .number)
                Text(appState.resume.skills.joined(separator: " | "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Quick Contract") {
                TextField("Title", text: $contractTitle)
                TextField("Budget", text: $budget)
                    .keyboardType(.numberPad)
                TextField("Location", text: $location)
                Toggle("Local hire", isOn: $localHire)
                Button("Publish Contract") {
                    _ = appState.addContract(
                        title: contractTitle.isEmpty ? "Untitled Contract" : contractTitle,
                        budgetUSD: Int(budget) ?? 0,
                        location: location.isEmpty ? "Remote" : location,
                        isLocalHire: localHire
                    )
                    contractTitle = ""
                    budget = ""
                    location = ""
                }
            }

            Section("Marketplace Listing") {
                TextField("Listing title", text: $listingTitle)
                TextField("Price", text: $listingPrice)
                    .keyboardType(.numberPad)
                TextField("Category", text: $listingCategory)
                Button("Create Listing") {
                    appState.addListing(
                        title: listingTitle.isEmpty ? "Untitled Listing" : listingTitle,
                        priceUSD: Int(listingPrice) ?? 0,
                        category: listingCategory.isEmpty ? "General" : listingCategory
                    )
                    listingTitle = ""
                    listingPrice = ""
                    listingCategory = ""
                }
            }
        }
        .navigationTitle("Enterprise")
    }
}
