import SwiftUI

struct ProfileButton: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        let initials = appState.fullName
            .split(separator: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()

        Group {
            if let avatar = AvatarItem.all.first(where: { $0.id == appState.selectedAvatarId }),
               !appState.selectedAvatarId.isEmpty {
                AsyncImage(url: avatar.url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Text(String(avatar.name.prefix(1)))
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                }
            } else if let image = appState.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
        }
        .frame(width: 38, height: 38)
        .background(AppColors.accent)
        .clipShape(Circle())
    }
}
