import SwiftUI

extension AppState {

    // MARK: - Settings State

    private struct SettingsState: Codable {
        var selectedAvatarId: String = ""
        var ownedAvatarIds: [String] = []
        var hapticsDisabled: Bool = false
        var blockCellularData: Bool = false
        var linkedEmail: String = ""
        var colorSchemePref: String = "light"
    }

    var preferredColorScheme: ColorScheme? {
        switch colorSchemePref {
        case "dark":   return .dark
        case "system": return nil
        default:       return .light
        }
    }

    func loadSettingsState(from account: UserAccount) {
        guard let data = account.settingsJSON.data(using: .utf8),
              let state = try? JSONDecoder().decode(SettingsState.self, from: data) else { return }
        selectedAvatarId  = state.selectedAvatarId
        ownedAvatarIds    = Set(state.ownedAvatarIds)
        hapticsDisabled   = state.hapticsDisabled
        blockCellularData = state.blockCellularData
        linkedEmail       = state.linkedEmail
        colorSchemePref   = state.colorSchemePref
        SoundManager.isDisabled = state.hapticsDisabled
    }

    func encodeSettingsState() -> String {
        let state = SettingsState(
            selectedAvatarId:  selectedAvatarId,
            ownedAvatarIds:    Array(ownedAvatarIds),
            hapticsDisabled:   hapticsDisabled,
            blockCellularData: blockCellularData,
            linkedEmail:       linkedEmail,
            colorSchemePref:   colorSchemePref
        )
        return encode(state) ?? "{}"
    }

    // MARK: - Avatar

    func unlockAvatar(_ id: String) {
        guard let item = AvatarItem.all.first(where: { $0.id == id }) else { return }
        guard gems >= item.category.gemCost, !ownedAvatarIds.contains(id) else { return }
        gems -= item.category.gemCost
        ownedAvatarIds.insert(id)
        saveToAccount()
    }

    func setHapticsDisabled(_ disabled: Bool) {
        hapticsDisabled = disabled
        SoundManager.isDisabled = disabled
        saveToAccount()
    }
}
