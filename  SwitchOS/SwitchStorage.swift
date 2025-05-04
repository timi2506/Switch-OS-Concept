//
//  SwitchStorage.swift
//   SwitchOS
//
//  Created by Tim on 02.05.25.
//

import SwiftUI
let settingsApp = SwitchGame(
    imageURL: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKbVH43z9uLGoXnokhT1dPtD1huxuzNGo_g3GRK7uzJGPDdtHN9_Kwc6nXWoN2tTneYis&usqp=CAU")!,
    name: "Settings",
    content: .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: "Settings")))
)
let defaultProfile = SwitchProfile(name: "Default", games: [
    SwitchGame(imageURL: URL(string: "https://github.com/timi2506/RAW-files-i-need-for-stuff/blob/main/YouTube%20TV.png?raw=true")!, name: "YouTube TV", content: .url(URL(string: "https://youtube.com/tv")!), userAgent: nintendoSwitchUserAgent),
    SwitchGame(imageURL: URL(string: "https://static-00.iconduck.com/assets.00/console-controller-icon-2048x2048-pmmusn7m.png")!, name: "Controller Test", content: .url(URL(string: "https://gpadtester.com")!), userAgent: nintendoSwitchUserAgent),
    SwitchGame(
        imageURL: URL(string: "https://github.com/timi2506/RAW-files-i-need-for-stuff/blob/main/Store.png?raw=true")!,
        name: "Store",
        content: .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: "Store")))
    )
], userIcon: .url(URL(string: "https://cdn.accounts.nintendo.com/icons/v1/5cc02a33-f5d1-48e4-b14b-7dd6a5eddb90.png?width=270&bgColor=DFDFDFFF")!))

class SwitchStorage: ObservableObject {
    static let shared = SwitchStorage()
    private init() {
        if let data = UserDefaults.standard.data(forKey: "profileData"), let decoded = try? JSONDecoder().decode([SwitchProfile].self, from: data) {
            self.selectedProfile = decoded.first ?? defaultProfile
            self.profiles = decoded
            print("Loaded Saved Profiles")
        } else {
            self.selectedProfile = defaultProfile
            self.profiles = [defaultProfile]
            print("Loaded Default Profiles")

        }
        
    }
    @Published var selectedProfile: SwitchProfile
    @Published var profiles: [SwitchProfile] {
        didSet {
            if !profiles.contains(selectedProfile) {
                if let firstProfile = profiles.first {
                    selectedProfile = firstProfile
                }
            }
            for index in profiles.indices {
                if !profiles[index].games.contains(where: { $0.content == .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: "Store"))) }) {
                    profiles[index].games.append(
                        SwitchGame(
                            imageURL: URL(string: "https://github.com/timi2506/RAW-files-i-need-for-stuff/blob/main/Store.png?raw=true")!,
                            name: "Store",
                            content: .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: "Store")))
                        )
                    )
                }
            }
            if let newProfileData = try? JSONEncoder().encode(profiles) {
                UserDefaults.standard.set(newProfileData, forKey: "profileData")
                print("Saved Profiles")
            }
        }
    }
    func reset() {
        selectedProfile = defaultProfile
        profiles = [defaultProfile]
        if let newProfileData = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(newProfileData, forKey: "profileData")
            print("Reset Data")
        }
    }
    func addUser(_ name: String, iconData: Data) {
        profiles.append(
            SwitchProfile(name: name, games: [
                SwitchGame(
                    imageURL: URL(string: "https://github.com/timi2506/RAW-files-i-need-for-stuff/blob/main/Store.png?raw=true")!,
                    name: "Store",
                    content: .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: "Store")))
                )
            ], userIcon: .data(iconData))
        )
    }
}
