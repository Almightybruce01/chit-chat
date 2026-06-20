import SwiftUI
import StoreKit

struct VerificationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.storeKit) private var storeKit
    @Environment(\.colorScheme) private var colorScheme
    @State private var note = ""
    @State private var hasInstagramVerification = false
    @State private var submitted = false
    @State private var selectedCategory: VerificationCategory
    @State private var purchaseSucceeded = false

    init(initialCategory: VerificationCategory? = nil) {
        _selectedCategory = State(initialValue: initialCategory ?? .creator)
    }

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section {
                    Label("Two separate badges", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Official verification (free) is reviewed by our team and shows a blue check. Paid verification badge (In-App Purchase) is optional, costs money once through Apple, and shows a separate gold paid badge. They are not the same.")
                        .font(.caption)
                }
                .foregroundStyle(secondaryText)

                Section {
                    Text("FREE — Team review")
                        .font(.caption.bold())
                        .foregroundStyle(BrandPalette.neonGreen)
                } header: {
                    Text("Official verification")
                } footer: {
                    Text("Submitting here does not charge you and does not unlock the paid badge.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(VerificationCategory.allCases) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        if selectedCategory == .business {
                            Text("Business accounts must get each job post approved before it goes live.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                        }
                    }
                    Toggle("Already verified on Instagram", isOn: $hasInstagramVerification)
                    TextField("Add profile details", text: $note, axis: .vertical)
                        .lineLimit(3...5)

                    Button("Submit free official verification request") {
                        appState.requestVerification(
                            note: note.isEmpty ? "No additional note" : note,
                            hasInstagramVerification: hasInstagramVerification,
                            category: selectedCategory
                        )
                        submitted = true
                        note = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandPalette.neonGreen)
                }

                Section {
                    Text("PAID — Apple In-App Purchase")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                } header: {
                    Text("Paid verification badge")
                } footer: {
                    Text("One-time non-consumable purchase through Apple. Separate from the free official request above.")
                }

                Section {
                    paidBadgePurchaseContent

                    Button("Restore Purchases") {
                        Task {
                            await storeKit.restorePurchases()
                            appState.syncPaidVerificationEntitlement(active: storeKit.hasPaidVerification)
                            if storeKit.hasPaidVerification {
                                purchaseSucceeded = true
                                HapticTokens.success()
                            }
                        }
                    }
                    .disabled(storeKit.isRestoring || storeKit.isPurchasing)

                    if let err = storeKit.purchaseError, !err.isEmpty {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Current Status") {
                    Text(officialStatusLine)
                        .foregroundStyle(primaryText)
                    Text(paidStatusLine)
                        .foregroundStyle(secondaryText)
                        .font(.caption)
                    Text("Free request queue: \(appState.verificationRequests.filter { $0.status == .pending }.count) pending")
                        .foregroundStyle(secondaryText)
                        .font(.caption)
                }

                if submitted {
                    Section {
                        Text("Free official verification request submitted. Our team will review it separately from any paid badge.")
                            .foregroundStyle(colorScheme == .light ? .green.opacity(0.85) : .green)
                    }
                }
                if purchaseSucceeded {
                    Section {
                        Text("Paid verification badge unlocked via In-App Purchase.")
                            .foregroundStyle(colorScheme == .light ? .green.opacity(0.85) : .green)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Verification")
        .task {
            await storeKit.loadProductsIfNeeded()
            await storeKit.refreshPurchasedProducts()
            appState.syncPaidVerificationEntitlement(active: storeKit.hasPaidVerification)
        }
        .onChange(of: storeKit.productLoadState) { _, state in
            if case .unavailable = state {
                Task { await storeKit.loadProductsIfNeeded() }
            }
        }
        .onChange(of: storeKit.hasPaidVerification) { _, active in
            appState.syncPaidVerificationEntitlement(active: active)
        }
    }

    @ViewBuilder
    private var paidBadgePurchaseContent: some View {
        if appState.currentUser.verificationStatus == .verifiedInternal {
            Text("You already have official verification. The optional paid badge is not required.")
                .font(.caption)
                .foregroundStyle(secondaryText)
        } else if storeKit.hasPaidVerification || appState.currentUser.verificationStatus == .paid {
            Label("Paid verification badge active", systemImage: "dollarsign.seal.fill")
                .foregroundStyle(.yellow)
            Text("This gold paid badge is separate from free official verification.")
                .font(.caption)
                .foregroundStyle(secondaryText)
        } else if let product = storeKit.paidVerificationProduct {
            VStack(alignment: .leading, spacing: 10) {
                Text("Paid Verification Badge")
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                Button {
                    Task {
                        purchaseSucceeded = false
                        if await storeKit.purchasePaidVerification() {
                            appState.grantPaidVerificationFromPurchase()
                            purchaseSucceeded = true
                            HapticTokens.success()
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if storeKit.isPurchasing {
                            ProgressView()
                                .tint(.black)
                            Text("Processing…")
                                .fontWeight(.semibold)
                        } else {
                            Text("Buy Paid Verification Badge — \(product.displayPrice)")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .disabled(storeKit.isPurchasing)
            }
        } else if storeKit.productLoadState == .loading || storeKit.productLoadState == .idle {
            HStack(spacing: 10) {
                ProgressView()
                Text("Loading App Store product…")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }
            Button("Retry") {
                Task { await storeKit.loadProducts() }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(storeKit.productUnavailableMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                Button("Retry loading product") {
                    Task { await storeKit.loadProducts() }
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandPalette.neonBlue)
            }
        }
    }

    private var primaryText: Color {
        colorScheme == .light ? .black : .white
    }

    private var secondaryText: Color {
        colorScheme == .light ? .black.opacity(0.72) : .white.opacity(0.82)
    }

    private var officialStatusLine: String {
        switch appState.currentUser.verificationStatus {
        case .verifiedInternal:
            return "Official: Verified (free, team-approved)"
        case .pending:
            return "Official: Pending team review"
        case .unverified, .paid:
            return "Official: Not verified"
        }
    }

    private var paidStatusLine: String {
        if storeKit.hasPaidVerification || appState.currentUser.verificationStatus == .paid {
            return "Paid badge: Active (In-App Purchase)"
        }
        return "Paid badge: Not purchased"
    }
}
