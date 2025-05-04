//
//  GameContent.swift
//   SwitchOS
//
//  Created by Tim on 02.05.25.
//

import SwiftUI
import WebKit

struct HTMLView: UIViewRepresentable {
    let html: String
    var userAgent: String?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.customUserAgent = userAgent
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let fileURL = FileManager().temporaryDirectory.appendingPathComponent("index.html", conformingTo: .html)
        print(fileURL.absoluteString)
        try? html.write(to: fileURL, atomically: true, encoding: .utf8)
        guard let htmlString = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        webView.customUserAgent = userAgent
        webView.loadHTMLString(htmlString, baseURL: fileURL)
    }
}

struct WebsiteView: UIViewRepresentable {
    let url: URL
    var userAgent: String?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.customUserAgent = userAgent
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.customUserAgent = userAgent
        webView.load(URLRequest(url: url))
    }
}

struct GameContentView: View {
    @Binding var item: SwitchGame?
    var game: SwitchGame
    var body: some View {
        switch game.content {
        case .url(let url):
            WebsiteView(url: url, userAgent: game.userAgent)
        case .html(let htmlString):
            HTMLView(html: htmlString, userAgent: game.userAgent)
        case .swiftUI(let swiftUIViewWrapper):
            swiftUIViewWrapper.view
        case .none:
            Text("Error Loading Game Content")
                .onAppear {
                    item = nil
                    showAlert("Error Loading Game Content", subtitle: "Please check if the JSON Format is valid")
                }
        }
    }
}

struct TestDivided: View {
    @State var height = UIScreen.main.bounds.height / 2
    var body: some View {
        VStack {
            HTMLView(html: """
    <div>Testing html lmao<div>
    <div>Testing html lmao<div>
    <div>Testing html lmao<div
    <div>Testing html lmao<div>
    <div>Testing html lmao<div>
    <div>Testing html lmao<div>
    <div>Testing html lmao<div>
    <div>Testing html lmao<div>
    <div>Testing html lmao<div>
    
    """)
            .frame(height: height)
            ZStack {
                Divider()
                Menu(content: {
                    Button("Reset Height") {
                        height = UIScreen.main.bounds.height / 2
                    }
                }) {
                    Image(systemName: "ellipsis")
                        .padding(5)
                }
                .highPriorityGesture(
                    LongPressGesture()
                        .onEnded { _ in
                            
                        }
                )
                .background(
                    Capsule()
                        .foregroundStyle(.ultraThinMaterial)
                )
            }
            .highPriorityGesture(
                DragGesture()
                    .onChanged { value in
                        height += value.translation.height
                    }
            )
            WebsiteView(url: URL(string: "https://beta.chirpsocial.net")!)
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    TestDivided()
}


public func showAlert(_ title: String? = nil, subtitle: String, buttonLabel: String? = "OK") {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first?.rootViewController else {
        return
    }
    
    let alert = UIAlertController(
        title: title ?? "Confirm Action",
        message: subtitle,
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: buttonLabel, style: .cancel) { _ in
        alert.dismiss(animated: true)
    })
    
    root.presentedViewController?.present(alert, animated: true)
    ?? root.present(alert, animated: true)
}
