import Foundation
import Contacts

final class ContactSyncManager: ObservableObject {
    @Published var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    @Published var displayNames: [String] = []
    @Published var identifiers: [String] = []
    @Published var statusMessage = "Contacts not requested."

    private let store = CNContactStore()

    func requestAndLoadContacts() {
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                if granted {
                    self.loadContacts()
                } else {
                    self.statusMessage = "Contacts access denied."
                }
            }
        }
    }

    private func loadContacts() {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]
        var names: [String] = []
        var ids: [String] = []
        let request = CNContactFetchRequest(keysToFetch: keys)
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let combined = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                if !combined.isEmpty {
                    names.append(combined)
                }
                ids.append(contact.identifier)
            }
            displayNames = names
            identifiers = ids
            statusMessage = "Loaded \(names.count) contacts."
        } catch {
            statusMessage = "Failed to load contacts."
        }
    }
}
