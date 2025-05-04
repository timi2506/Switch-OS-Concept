//
//  Store.swift
//   SwitchOS
//
//  Created by Tim on 04.05.25.
//

import SwiftUI

struct StoreView: View {
    @State var games: [SwitchGame] = []
    @State var detailGame: SwitchGame?
    @State var isLoading = false
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                }
                else if games.isEmpty {
                    Text("No Games yet")
                        .font(.title)
                        .bold()
                    Text("Try Reloading")
                        .font(.headline)
                        .foregroundStyle(.gray)
                } else {
                    List(games) { game in
                        HStack {
                            AsyncImage(url: game.imageURL, content: { image in
                                image.resizable().scaledToFill()
                            }, placeholder: {
                                Rectangle()
                                    .foregroundStyle(.gray.opacity(0.25))
                                    .overlay {
                                        ProgressView()
                                    }
                            })
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                            VStack(alignment: .leading) {
                                Text(game.name)
                                Text(game.id.uuidString)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Button("Details") {
                                detailGame = game
                            }
                            .padding(.horizontal)
                            .buttonStyle(.borderless)
                            Button("Install") {
                                installGame(game)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await loadGames()
                    }
                    .sheet(item: $detailGame) { game in
                        if let gameContent = game.content {
                            Form {
                                Section("About") {
                                    DetailView(key: "Name", value: game.name)
                                    DetailView(key: "Icon URL", value: game.imageURL.absoluteString)
                                    DetailView(key: "ID", value: game.id.uuidString)
                                    DetailView(key: "Custom User Agent", value: game.userAgent ?? "None")
                                    DetailView(key: "Content Type", value: gameContentType(from: gameContent))
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                Button(action: {
                    Task {
                        isLoading = true
                        await loadGames()
                        isLoading = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .onAppear {
                Task {
                    isLoading = true
                    await loadGames()
                    isLoading = false
                }
            }
        }
    }
    func gameContentType(from gameContent: GameContent) -> String {
        switch gameContent {
        case .url(let url):
            "Website URL"
        case .html(let html):
            "HTML"
        case .swiftUI(let wrapper):
            "Internal SwiftUI View"
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
    func loadGames() async {
        do {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let urls = try await fetchGitHubRawFileURLs()
            games = await decodeGames(from: urls)
        } catch {
            print("Failed to load games:", error)
            games = []
        }
    }
    
    func fetchGitHubRawFileURLs() async throws -> [URL] {
        let owner = "timi2506"
        let repo = "ConceptOS-Store"
        let branch = "main"
        
        let apiURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/git/trees/\(branch)")!
        
        let (data, _) = try await URLSession.shared.data(from: apiURL)
        let decoded = try JSONDecoder().decode(GitTreeResponse.self, from: data)
        
        let rawURLs = decoded.tree
            .filter { $0.type == "blob" }
            .compactMap {
                URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\($0.path)")
            }
        
        return rawURLs
    }
    
    func decodeGames(from urls: [URL]) async -> [SwitchGame] {
        var games: [SwitchGame] = []
        
        for url in urls {
            if !url.absoluteString.lowercased().contains("readme.md") {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let game = try JSONDecoder().decode(SwitchGame.self, from: data)
                    games.append(game)
                } catch {
                    print("Failed to decode \(url):", error)
                }
            }
        }
        
        return games
    }
}

struct DetailView: View {
    let key: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(key)
            Spacer()
            Menu(content: {
                Button("Copy") {
                    UIPasteboard.general.string = value
                }
            }) {
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.gray)
                    .textSelection(.enabled)
            }
        }
    }
}

import Foundation

struct GitTreeResponse: Codable {
    let sha: String?
    let url: String
    let tree: [GitTreeEntry]
    let truncated: Bool?
}

struct GitTreeEntry: Codable {
    let path: String
    let mode: String?
    let type: String?
    let sha: String?
    let size: Int?
    let url: String
}
