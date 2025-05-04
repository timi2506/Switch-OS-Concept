//
//  ContentView.swift
//   SwitchOS
//
//  Created by Tim on 01.05.25.
//
 
import SwiftUI
import CodableAppStorage
import GameControllerKit
import BatteryView

let nintendoSwitchUserAgent = "Mozilla/5.0 (Nintendo Switch; WebApplet) AppleWebKit/609.4 (KHTML, like Gecko) NF/6.0.2.20.5 NintendoBrowser/5.1.0.22023 Dalvik/2.1.0 (Linux; U; Android 5.1.1; AEOBC Build/LVY48f)"

struct ContentView: View {
    @State var direction = ""
    @StateObject private var switchStorage = SwitchStorage.shared
    let profiles = SwitchStorage.shared.profiles
    @State var launchGame: SwitchGame?
    @State var selectedGame = 0
    @State var gameController = GameControllerKit(logger: nil)
    @State var switchingProfile = false
    @State var leftTimeout = false
    @State var rightTimeout = false
    @State var scrollProxy: ScrollViewProxy?
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollViewReader { proxy in
                    if !switchingProfile {
                        ScrollView(.horizontal) {
                            Spacer()
                                .frame(width: 25, height: 1)
                            HomeScrollView(selectedProfile: $switchStorage.selectedProfile, selectedGame: $selectedGame)
                        }
                        .scrollIndicators(.never)
                        .scrollDisabled(true)
                        .frame(height: 550)
                        .onAppear {
                            scrollProxy = proxy
                        }
                        .highPriorityGesture(
                            DragGesture()
                                .onChanged { value in
                                    let translation = value.translation
                                    
                                    if abs(translation.width) > abs(translation.height) {
                                        direction = translation.width > 0 ? "Right" : "Left"
                                    }
                                }
                                .onEnded { _ in
                                    if direction == "Right" {
                                        left(proxy)
                                    } else if direction == "Left" {
                                        right(proxy)
                                    }
                                }
                        )
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded {
                                    withAnimation() {
                                        launchGame = SwitchStorage.shared.selectedProfile.games[selectedGame]
                                    }
                                }
                        )
                        //                            .controllerInput { key in
                        //                                switch key {
                        //                                case .left:
                        //                                    left(proxy)
                        //                                case .right:
                        //                                    right(proxy)
                        //                                case .home:
                        //                                    launchGame = nil
                        //                                case .a:
                        //                                    withAnimation() {
                        //                                        launchGame = games[selectedGame]
                        //                                    }
                        //                                }
                        //                            }
                    } else {
                        VStack {
                            UserIconView(icon: SwitchStorage.shared.selectedProfile.userIcon, frame: Frame(width: 200, height: 200))
                                .bounceReplace(binding: $switchStorage.selectedProfile, time: 0.10)
                                .frame(width: 200, height: 200)
                            Text(SwitchStorage.shared.selectedProfile.name)
                                .bounceReplace(binding: $switchStorage.selectedProfile, time: 0.10)
                                .font(.system(size: 50, weight: .bold))
                            ProgressView()
                                .scaleEffect(2.5)
                                .frame(width: 50, height: 50)
                        }
                    }
                    
                    
                }
                HStack {
                    ProfilePicker(selectedProfile: Binding(get: {
                        switchStorage.selectedProfile
                    }, set: { newValue in
                        switchStorage.selectedProfile = newValue
                    }), profiles: $switchStorage.profiles, selectedGame: $selectedGame, switchingProfile: $switchingProfile)
                    .allowsHitTesting(!switchingProfile)
                    
                    .onChange(of: SwitchStorage.shared.selectedProfile) { newProfile in
                        selectedGame = 0
                    }
                    Spacer()
                    Button(action: {
                        launchGame = settingsApp
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }
                    .padding(.horizontal)
                    SystemBattery()
                        .frame(width: 50, height: 25)
                }
                .padding(25)
                .frame(maxHeight: .infinity, alignment: .top)
                .fullScreenCover(item: $launchGame) { game in
                    ZStack {
                        GameContentView(item: $launchGame, game: game)
                            .onAppear {
                                gameController.set(handler: homeOnlyHandler(action:pressed:controller:))
                            }
                            .onDisappear {
                                gameController.set(handler: handler(action:pressed:controller:))
                            }
                        Image(systemName: "house.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .foregroundStyle(.tint)
                            )
                            .onTapGesture {
                                launchGame = nil
                            }
                            .movable()
                    }
                }
                .onChange(of: SwitchStorage.shared.selectedProfile) { _ in
                    switchingProfile = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        switchingProfile = false
                    }
                }
            }
            .onAppear {
                gameController.set(handler: handler(action:pressed:controller:))
            }
        }
    }
    func right(_ proxy: ScrollViewProxy) {
        print("Right")
        if SwitchStorage.shared.selectedProfile.games.indices.contains(selectedGame + 1) {
            withAnimation() {
                selectedGame = selectedGame + 1
                proxy.scrollTo(selectedGame, anchor: .leading)
            }
        } else {
            withAnimation() {
                selectedGame = SwitchStorage.shared.selectedProfile.games.indices.first!
                proxy.scrollTo(SwitchStorage.shared.selectedProfile.games.indices.first, anchor: .topLeading)
            }
        }
    }
    func left(_ proxy: ScrollViewProxy) {
        print("Left")
        if SwitchStorage.shared.selectedProfile.games.indices.contains(selectedGame - 1) {
            withAnimation() {
                selectedGame = selectedGame - 1
                proxy.scrollTo(selectedGame, anchor: .leading)
            }
        } else {
            withAnimation() {
                selectedGame = SwitchStorage.shared.selectedProfile.games.indices.last!
                proxy.scrollTo(SwitchStorage.shared.selectedProfile.games.indices.last, anchor: .topLeading)
            }
        }
    }
    func viewToImage<V: View>(placeholder: UIImage? = nil, content: () -> V) -> UIImage? {
        if let uiImage = ImageRenderer(content: content()).uiImage {
            return uiImage
        } else {
            return placeholder
        }
    }
    public func handler(
        action: GCKAction,
        pressed: Bool,
        controller: GCKController
    ) {
        if action == .buttonA && pressed {
            withAnimation() {
                launchGame = SwitchStorage.shared.selectedProfile.games[selectedGame]
            }
            print("A PRESSED")
        }
        if action == .dpadLeft && pressed {
            controllerLeft(scrollProxy)
            print("DPAD LEFT PRESSED")
        }
        if action == .dpadRight && pressed {
            controllerRight(scrollProxy)
            print("DPAD RIGHT PRESSED")
        }
        if action.thumbStickAction {
            switch action.position {
            case .up:
                print("up")
            case .upRight:
                if !rightTimeout {
                    rightTimeout = true
                    print("upRight")
                    controllerRight(scrollProxy)
                    runDelayed(0.5) {
                        rightTimeout = false
                    }
                }
            case .right:
                if !rightTimeout {
                    rightTimeout = true
                    print("right")
                    controllerRight(scrollProxy)
                    runDelayed(0.5) {
                        rightTimeout = false
                    }
                }
            case .downRight:
                if !rightTimeout {
                    rightTimeout = true
                    print("downRight")
                    controllerRight(scrollProxy)
                    runDelayed(0.5) {
                        rightTimeout = false
                    }
                }
            case .down:
                return
                //                print("down")
            case .downLeft:
                if !leftTimeout {
                    leftTimeout = true
                    print("downLeft")
                    controllerLeft(scrollProxy)
                    runDelayed(0.5) {
                        leftTimeout = false
                    }
                }
            case .left:
                if !leftTimeout {
                    leftTimeout = true
                    print("left")
                    controllerLeft(scrollProxy)
                    runDelayed(0.5) {
                        leftTimeout = false
                    }
                }
            case .upLeft:
                if !leftTimeout {
                    leftTimeout = true
                    print("upLeft")
                    controllerLeft(scrollProxy)
                    runDelayed(0.5) {
                        leftTimeout = false
                    }
                }
            case .centered:
                return
                //                print("Centered")
            case .unknown:
                return
                //                print("Unknown")
            }
        }
        if action == .leftThumbstick(x: -1, y: 0) {
            print(1010)
        }
    }
    public func homeOnlyHandler(
        action: GCKAction,
        pressed: Bool,
        controller: GCKController
    ) {
        if action == .buttonMenu && pressed {
            launchGame = nil
        }
    }
    func controllerLeft(_ proxy: ScrollViewProxy?) {
        if let proxy {
            left(proxy)
        }
    }
    func controllerRight(_ proxy: ScrollViewProxy?) {
        if let proxy {
            right(proxy)
        }
    }
}
func runDelayed(_ time: CGFloat, action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + time) {
        action()
    }
}
struct HomeScrollView: View {
    @Binding var selectedProfile: SwitchProfile
    @Binding var selectedGame: Int
    var body: some View {
        HStack(spacing: 15) {
            Spacer()
                .frame(width: 25)
            ForEach(selectedProfile.games.indices, id: \.self) { index in
                ZStack {
                    AsyncImage(url: selectedProfile.games[index].imageURL, content: { image in
                        image.resizable().scaledToFill()
                    }, placeholder: {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.25))
                            .overlay {
                                ProgressView()
                                    .controlSize(.large)
                            }
                    })
                    .frame(width: 300, height: 300)
                    .cornerRadius(35)
                    .overlay {
                        if selectedGame == index {
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(.red, lineWidth: 5)
                                .frame(width: 315, height: 315)
                        } else {
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(.primary.opacity(0.5), lineWidth: 1.5)
                        }
                    }
                    .scaleEffect(selectedGame == index ? 1.15 : 1)
                    .padding(.horizontal, selectedGame == index ? 15 : 0)
                    .padding(.horizontal, 20)
                    if selectedGame == index {
                        HStack {
                            Image(systemName: "lanyardcard.fill")
                            Text(selectedProfile.games[index].name)
                                .bold()
                                .fontDesign(.rounded)
                        }
                        .font(.title)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
                
                .id(index)
            }
        }
        .padding()
    }
}
struct SettingsView: View {
    let views: [String: () -> AnyView] = [
        "Data Management": {
            AnyView(DataManagement())
        },
        "Create App/Game": {
            AnyView(CreateGameView())
        }
    ]
    @State var selectedView = "Data Management"
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "gear")
                Text("System Settings")
                Spacer()
            }
            .font(.title)
            .padding()
            Divider()
            NavigationSplitView(sidebar: {
                ScrollView(.vertical) {
                    VStack {
                        ForEach(Array(views.keys), id: \.self) { key in
                            HStack {
                                Rectangle()
                                    .frame(width: 2.5, height: 35)
                                    .foregroundStyle(selectedView == key ? Color.accentColor : Color.clear)
                                Text(key)
                                Spacer()
                            }
                            .foregroundStyle(selectedView == key ? Color.accentColor : Color.primary)
                            .padding(5)
                            .background(
                                Color(uiColor: .secondarySystemBackground).opacity(selectedView == key ? 1 : 0)
                            )
                            .background(
                                Rectangle()
                                    .stroke(selectedView == key ? .teal : .clear, lineWidth: 2.5)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.smooth) {
                                    selectedView = key
                                }
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.never)
            }) {
                views[selectedView]?()
            }
        }
    }
}

struct CreateGameView: View {
    @StateObject var switchStorage = SwitchStorage.shared
    @State var name = "" {
        didSet {
            generateNewJSON()
        }
    }
    @State var imageURL = "" {
        didSet {
            generateNewJSON()
        }
    }
    @State var contentType: GameContent.ContentType = .url {
        didSet {
            generateNewJSON()
        }
    }
    @State var content = "" {
        didSet {
            generateNewJSON()
        }
    }
    @State var userAgent: String? {
        didSet {
            generateNewJSON()
        }
    }
    @State var json: String?
    @State var generatedGame: SwitchGame?
    var body: some View {
        Form {
            Section("Required") {
                TextField("Name of the App/Game", text: $name, onCommit: {
                    generateNewJSON()
                })
                TextField("Icon URL", text: $imageURL, onCommit: {
                    generateNewJSON()
                })
                Picker("Content Type", selection: $contentType) {
                    Text("Website URL")
                        .tag(GameContent.ContentType.url)
                    Text("HTML")
                        .tag(GameContent.ContentType.html)
                }
                if contentType == .url {
                    TextField("Website URL", text: $content, onCommit: {
                        generateNewJSON()
                    })
                } else if contentType == .html {
                    TextEditor(text: $content)
                }
            }
            Section(content: {
                TextField("User Agent", text: Binding(get: {
                    userAgent ?? ""
                }, set: { newValue in
                    if newValue.isEmpty {
                        userAgent = nil
                    } else {
                        userAgent = newValue
                    }
                }))
            }, header: { Text("Optional") }, footer: {
                Button(action: {
                    generateNewJSON()
                }) {
                    Text("After entering all required Values, the App/Game JSON should automatically be generated and displayed below. \n\nIf it isn't: Tap here!")
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.gray)
                    .font(.caption)
                }
            })
            
            if let json {
                Section("Generated JSON") {
                    TextEditor(text: .constant(json))
                        .disabled(true)
                    ShareLink(item: json) {
                        Text("Export")
                    }
                    Button("Install Game") {
                        if let generatedGame {
                            installGame(generatedGame)
                        }
                    }
                }
            }
        }
    }
    func installGame(_ game: SwitchGame) {
        chooseUser("Choose User", subtitle: "Choose the user you want to install \"\(game.name)\" to", profiles: SwitchStorage.shared.profiles, completion: { profileIndex in
            if let profileIndex {
                if SwitchStorage.shared.profiles[profileIndex].games.contains(game) {
                    showAlert("Duplicate Found", subtitle: "This Game already exists in your Library")
                } else {
                    SwitchStorage.shared.profiles[profileIndex].games.append(game)
                }
            } else {
                showAlert("App not installed", subtitle: "Installation was cancelled")
            }
        })
    }
    func gameToData(_ game: SwitchGame) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(game)
    }
    func generateNewJSON() {
        json = nil
        var switchGame: SwitchGame?
        var encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let icon = URL(string: imageURL), !name.isEmpty, !content.isEmpty {
            if contentType == .html {
                let gameContent: GameContent = .html(content)
                switchGame = SwitchGame(imageURL: icon, name: name, content: gameContent, userAgent: userAgent)

            }
            else if let url = URL(string: content), contentType == .url {
                let gameContent: GameContent = .url(url)
                switchGame = SwitchGame(imageURL: icon, name: name, content: gameContent, userAgent: userAgent)
            } else {
                switchGame = nil
            }
            if let switchGame {
                generatedGame = switchGame
                if let generatedJSON = try? encoder.encode(switchGame), let jsonString = String(data: generatedJSON, encoding: .utf8) {
                    json = jsonString
                }
            }
        }
    }
}

struct DataManagement: View {
    @StateObject private var switchStorage = SwitchStorage.shared
    @State var addGame = false
    @State var exportGames: SwitchProfile?
    var body: some View {
        List {
            ForEach($switchStorage.profiles) { $profile in
                Section("Apps & Games for \(profile.name) • \(profile.games.count)") {
                    ForEach($profile.games) { $game in
                        HStack {
                            AsyncImage(url: game.imageURL, content: { image in
                                image.resizable().scaledToFill()
                            }, placeholder: {
                                Rectangle()
                                    .foregroundStyle(.gray.opacity(0.25))
                                    .overlay {
                                        ProgressView()
                                            .controlSize(.regular)
                                    }
                            })
                            .frame(width: 35, height: 35)
                            .cornerRadius(5)
                            VStack(alignment: .leading) {
                                Text(game.name)
                                Text(game.id.uuidString)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let deletedGames = offsets.map { profile.games[$0] }
                            for game in deletedGames {
                                if game.content == .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: "Store"))) {
                                    showAlert("Error", subtitle: "The Store App can't be removed", buttonLabel: "Got it!")
                                }
                            }
                        profile.games.remove(atOffsets: offsets)
                    }
                }
            }
            Section("Reset Data") {
                Button("Erase All Profiles and Games", role: .destructive) {
                    switchStorage.reset()
                    showAlert("Erased Successfully", subtitle: "All Games and Profiles have been erased and Reset to Default")
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
            Button(action: {
                chooseUser("Choose User", subtitle: "Choose the User who's Apps & Games you'd like to share", profiles: SwitchStorage.shared.profiles, completion: { profileIndex in
                    if let profileIndex {
                        exportGames = SwitchStorage.shared.profiles[profileIndex]
                    }
                })
            }) {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 20)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            Button(action: {
                addGame.toggle()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .padding(2.5)
                    .frame(width: 25, height: 20)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .fileImporter(isPresented: $addGame, allowedContentTypes: [.json], onCompletion: { result in
            var success = 0
            var skipped = 0
            if let file = try? result.get() {
                print(file.startAccessingSecurityScopedResource())
                if let decoded = try? JSONDecoder().decode(SwitchGame.self, from: Data(contentsOf: file)) {
                    chooseUser("Choose Profile", subtitle: "Choose a Profile to add your Games to", profiles: switchStorage.profiles) { profile in
                        if let profile {
                            if !SwitchStorage.shared.profiles[profile].games.contains(where: { $0.content == decoded.content }) {
                                SwitchStorage.shared.profiles[profile].games.append(decoded)
                                success += 1
                                showAlert("Done!", subtitle: "Imported \(success) Game(s)\n\nSkipped \(skipped) Duplicate(s)")
                            } else {
                                skipped += 1
                            }
                        }
                    }
                } else if let decoded = try? JSONDecoder().decode([SwitchGame].self, from: Data(contentsOf: file)) {
                    chooseUser("Choose Profile", subtitle: "Choose a Profile to add your Games to", profiles: switchStorage.profiles) { profile in
                        if let profile {
                            for game in decoded {
                                if !SwitchStorage.shared.profiles[profile].games.contains(where: { $0.content == game.content }) {
                                    success += 1
                                    SwitchStorage.shared.profiles[profile].games.append(game)
                                } else {
                                    skipped += 1
                                }
                            }
                            showAlert("Done!", subtitle: "Imported \(success) Game(s)\n\nSkipped \(skipped) Duplicate(s)")
                        }
                    }
                } else {
                    showAlert("Error decoding File", subtitle: "Make sure the selected Game-File is valid", buttonLabel: "Got it!")
                }
            }
        })
        .sheet(item: $exportGames) { profile in
            VStack(spacing: 25) {
                UserIconView(icon: profile.userIcon, frame: Frame(width: 100, height: 100))
                Text("Export Apps & Games from \(profile.name)")
                    .font(.title)
                    .bold()
                Form {
                    Section("This Includes") {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text(profile.games.count.description)
                                .bold()
                            if profile.games.count == 1 {
                                Text("App or Game")
                                    .foregroundStyle(.primary.opacity(0.75))
                            } else {
                                Text("Apps & Games")
                                    .foregroundStyle(.primary.opacity(0.75))
                            }
                        }
                    }
                }
                Spacer()
                ShareLink(item: (try? writeDataToTemporaryFile(encodeGames(profile.games))) ?? URL(string: "https://google.com")!) {
                    HStack {
                        Spacer()
                        Text("Export")
                            .bold()
                            .padding(.vertical, 5)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    func encodeGames(_ games: [SwitchGame]) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try! encoder.encode(games)
    }
}

func chooseUser(_ title: String? = nil, subtitle: String, profiles: [SwitchProfile], completion: @escaping (Int?) -> Void) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first?.rootViewController else {
        return
    }
    
    let alert = UIAlertController(
        title: title ?? "Confirm Action",
        message: subtitle,
        preferredStyle: .alert
    )
    for profile in profiles.indices {
        alert.addAction(UIAlertAction(title: SwitchStorage.shared.profiles[profile].name, style: .default) { _ in
            completion(profile)
            alert.dismiss(animated: true)
        })
    }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        completion(nil)
        alert.dismiss(animated: true)
    })
    
    root.presentedViewController?.present(alert, animated: true)
    ?? root.present(alert, animated: true)
}

func exportGames(profile: SwitchProfile) -> URL? {
    let temp = FileManager.default.temporaryDirectory.appendingPathComponent("exported_games.json", conformingTo: .data)
    var encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    var exportURL: URL? = nil
    if let encoded = try? encoder.encode(profile.games) {
        try? encoded.write(to: temp)
        let url = URL(string: "https://designcode.io")
        exportURL = temp
    } else {
        exportURL = nil
    }
    if exportURL == nil {
        showAlert("Error Exporting Games", subtitle: "Sharing Google instead! (to avoid crashing the app)", buttonLabel: "Ok? lol")
        return exportURL

    } else {
        return exportURL
    }
}

struct ProfilePicker: View {
    @Binding var selectedProfile: SwitchProfile
    @Binding var profiles: [SwitchProfile]
    @Binding var selectedGame: Int
    @Binding var switchingProfile: Bool
    @State var picking = false
    @State var addProfile = false
    var body: some View {
        VStack {
            if !picking {
                HStack {
                    UserIconView(icon: selectedProfile.userIcon)
                    Text("\(selectedProfile.name)")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .padding(.horizontal)
                }
            } else {
                HStack {
                    ForEach(profiles) { profile in
                        UserIconView(icon: profile.userIcon)
                            .onTapGesture {
                                switchProfile(to: profile)
                            }
                    }
                    Image(systemName: "plus")
                        .resizable()
                        .foregroundStyle(.gray)
                        .frame(width: 20, height: 20)
                        .padding(15)
                        .background(
                            Circle()
                                .foregroundStyle(.gray.opacity(0.25))
                        )
                        .onTapGesture {
                            addProfile = true
                        }
                }
            }
        }
        .padding(10)
        .background(
            Capsule()
                .foregroundStyle(.ultraThinMaterial)
        )
        .bounceReplace(binding: $picking, blurRadius: 0)

        .onTapGesture {
            withAnimation(.linear(duration: 0.15)) {
                picking.toggle()
            }
        }
        .sheet(isPresented: $addProfile) {
            CreateProfileView()
        }
    }
    func switchProfile(to newProfile: SwitchProfile) {
        withAnimation() {
            picking = false
            switchingProfile = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation() {
                selectedProfile = newProfile
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation() {
                    switchingProfile = false
                }
            }
        }
    }
}

struct SwitchGame: Codable, Hashable, Identifiable {
    var id = UUID()
    let imageURL: URL
    let name: String
    var content: GameContent?
    var userAgent: String?
}

struct SwitchProfile: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var games: [SwitchGame]
    var userIcon: UserIcon
}

enum GameContent: Hashable {
    case url(URL)
    case html(String)
    case swiftUI(SwiftUIViewWrapper)
}

extension GameContent: Codable {
    public enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    public enum ContentType: String, Codable {
        case url
        case html
        case swiftUIView
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .url(let url):
            try container.encode(ContentType.url, forKey: .type)
            try container.encode(url, forKey: .value)

        case .html(let html):
            try container.encode(ContentType.html, forKey: .type)
            try container.encode(html, forKey: .value)

        case .swiftUI(let wrapper):
            try container.encode(ContentType.swiftUIView, forKey: .type)
            try container.encode(wrapper.extractAppID(), forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .url:
            let url = try container.decode(URL.self, forKey: .value)
            self = .url(url)

        case .html:
            let html = try container.decode(String.self, forKey: .value)
            self = .html(html)

        case .swiftUIView:
            let appID = try container.decode(String.self, forKey: .value)
            self = .swiftUI(SwiftUIViewWrapper(DefaultInternalView(appID: appID)))
        }
    }
}


enum UserIcon: Codable, Hashable {
    case data(Data)
    case url(URL)
}

struct UserIconView: View {
    var icon: UserIcon
    var frame: Frame = Frame(width: 50, height: 50)
    var body: some View {
        VStack {
            switch icon {
            case .data(let data):
                Image(uiImage: UIImage(data: data) ?? UIImage(systemName: "questionmark")!).resizable().scaledToFill()
            case .url(let url):
                AsyncImage(url: url, content: { image in
                    image.resizable().scaledToFill()
                }, placeholder: {
                    Rectangle()
                        .overlay {
                            ProgressView()
                                .foregroundStyle(.gray.opacity(0.25))
                                .controlSize(.large)
                        }
                })
            }
        }
        .frame(width: frame.width, height: frame.height)
        .clipShape(.circle)
    }
}

extension View {
    func bounceReplace<T: Equatable>(binding: Binding<T>, blurRadius: CGFloat? = nil, time: CGFloat? = nil) -> some View {
        self.modifier(BouncyReplace(binding: binding, blurRadius: blurRadius, time: time))
    }
    func movable() -> some View {
        self.modifier(Movable())
    }
}

let defaultOffset = CGSize(width: UIScreen.main.bounds.insetBy(dx: 25, dy: 25).width, height: UIScreen.main.bounds.height - 75)

struct Movable: ViewModifier {
    @State private var offset: CGSize = defaultOffset
    @State private var lastOffset: CGSize = defaultOffset
    // Get the screen bounds and inset by 15 for padding.
    private var allowedBounds: CGRect {
        UIScreen.main.bounds.insetBy(dx: 50, dy: 75)
    }
    
    func body(content: Content) -> some View {
        content
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        let currentPoint = CGPoint(x: offset.width, y: offset.height)
                        
                        if !allowedBounds.contains(currentPoint) {
                            var newX = offset.width
                            var newY = offset.height
                            
                            if currentPoint.x < allowedBounds.minX {
                                newX = allowedBounds.minX
                            } else if currentPoint.x > allowedBounds.maxX {
                                newX = allowedBounds.maxX
                            }
                            
                            if currentPoint.y < allowedBounds.minY {
                                newY = allowedBounds.minY
                            } else if currentPoint.y > allowedBounds.maxY {
                                newY = allowedBounds.maxY
                            }
                            
                            withAnimation(.spring()) {
                                offset = CGSize(width: newX, height: newY)
                                lastOffset = offset
                            }
                        } else {
                            lastOffset = offset
                        }
                    }
            )
    }
}


struct BouncyReplace<T: Equatable>: ViewModifier {
    @Binding var binding: T
    @State var oldValue: T?
    init(binding: Binding<T>, blurRadius: CGFloat?, time: CGFloat?) {
        self.blurRadius = blurRadius ?? 10
        _binding = binding
        self.time = time ?? 0.15
    }
    let blurRadius: CGFloat
    @State var runningChanges = 0
    @State var blur = false
    @State var scale = false
    var time: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: blur ? blurRadius : 0)
            .scaleEffect(scale ? 1.075 : 1)
            .onChange(of: binding) { newValue in
                runningChanges += 1
                let currentChanges = runningChanges
                if newValue != oldValue {
                    withAnimation(.linear(duration: time + 0.20)) {
                        blur = true
                        scale = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                        if currentChanges == 1 {
                            withAnimation(.linear(duration: time + 0.20)) {
                                blur = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + time + 0.10) {
                                withAnimation(.bouncy(duration: time + 0.10, extraBounce: 0.35)) {
                                    scale = false
                                }
                            }
                        }
                    }
                }
                runningChanges -= 1
                oldValue? = newValue
            }
    }
}

struct Frame {
    let width: CGFloat
    let height: CGFloat
}

#Preview {
    ContentView()
}

import SwiftUI

struct DefaultInternalView: View, Hashable {
    let appID: String

    var body: some View {
        switch appID {
        case "Store" :
            StoreView()
        case "Settings" :
            SettingsView()
        default:
            Text("Error Launching App")
        }
    }

    static func == (lhs: DefaultInternalView, rhs: DefaultInternalView) -> Bool {
        lhs.appID == rhs.appID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appID)
    }
}

struct SwiftUIViewWrapper: Hashable {
    let view: AnyView
    private let appID: String

    init(_ view: DefaultInternalView) {
        self.view = AnyView(view)
        self.appID = view.appID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appID)
    }

    static func == (lhs: SwiftUIViewWrapper, rhs: SwiftUIViewWrapper) -> Bool {
        lhs.appID == rhs.appID
    }

    func extractAppID() -> String {
        return appID
    }
}
