import SwiftUI
import Combine
import WebKit

struct SoundCloudPlayerView: View {
    let soundCloudUrl: String
    var autoPlay: Bool = false
    var color: String = "ff5500"
    var isController: Bool = false
    @ObservedObject var controller: SoundCloudController
    
    private var embedUrl: String {
        let encodedUrl = soundCloudUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "https://w.soundcloud.com/player/?url=\(encodedUrl)&color=%23\(color)&auto_play=\(autoPlay)&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=false"
    }

    var body: some View {
        SCAudioEngineWebView(url: URL(string: embedUrl)!, scController: controller)
            .frame(height: isController ? 0 : 160)
            .opacity(isController ? 0 : 1)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
    }
}

private struct SCAudioEngineWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var scController: SoundCloudController

    func makeCoordinator() -> SCWebViewCoordinator {
        let coordinator = SCWebViewCoordinator()
        coordinator.engineController = scController
        return coordinator
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "metadataHandler")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        context.coordinator.webView = webView
        
        // Setup control actions
        let scriptHandle = "var widget = SC.Widget(document.getElementById('sc-widget'));"
        scController.playAction = { webView.evaluateJavaScript(scriptHandle + "widget.play()") }
        scController.pauseAction = { webView.evaluateJavaScript(scriptHandle + "widget.pause()") }
        scController.nextAction = { webView.evaluateJavaScript(scriptHandle + "widget.next()") }
        scController.prevAction = { webView.evaluateJavaScript(scriptHandle + "widget.prev()") }
        scController.playAtIndexAction = { index in webView.evaluateJavaScript(scriptHandle + "widget.skip(\(index))") }
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url == nil {
            let html = """
            <html>
            <head>
                <script src="https://w.soundcloud.com/player/api.js" type="text/javascript"></script>
                <style>body,html,iframe { margin:0; padding:0; width:100%; height:100%; border:none; overflow:hidden; }</style>
            </head>
            <body>
                <iframe src="\(url.absoluteString)" id="sc-widget" allow="autoplay"></iframe>
                <script>
                    var widget = SC.Widget(document.getElementById('sc-widget'));
                    widget.bind(SC.Widget.Events.READY, function() {
                        window.webkit.messageHandlers.metadataHandler.postMessage({event: 'ready'});
                        
                        // Fetch Full Playlist
                        widget.getSounds(function(sounds) {
                            var trackList = sounds.map(function(s, index) {
                                return {
                                    id: index,
                                    title: s.title,
                                    user: s.user.username,
                                    artwork: s.artwork_url || s.user.avatar_url
                                };
                            });
                            window.webkit.messageHandlers.metadataHandler.postMessage({
                                event: 'playlist',
                                tracks: trackList
                            });
                        });

                        widget.bind(SC.Widget.Events.PLAY, function() {
                            window.webkit.messageHandlers.metadataHandler.postMessage({event: 'play'});
                        });
                        
                        widget.bind(SC.Widget.Events.PAUSE, function() {
                            window.webkit.messageHandlers.metadataHandler.postMessage({event: 'pause'});
                        });
                        
                        widget.bind(SC.Widget.Events.PLAY_PROGRESS, function(data) {
                            widget.getCurrentSoundIndex(function(index) {
                                window.webkit.messageHandlers.metadataHandler.postMessage({
                                    event: 'indexChange',
                                    index: index
                                });
                            });

                            widget.getCurrentSound(function(sound) {
                                window.webkit.messageHandlers.metadataHandler.postMessage({
                                    event: 'metadata',
                                    title: sound.title,
                                    user: sound.user.username,
                                    artwork: sound.artwork_url || sound.user.avatar_url
                                });
                            });
                        });
                    });
                </script>
            </body>
            </html>
            """
            uiView.loadHTMLString(html, baseURL: URL(string: "https://soundcloud.com"))
        }
    }
}

class SCWebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var webView: WKWebView?
    var engineController: SoundCloudController!

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any], let event = dict["event"] as? String else { return }
        
        DispatchQueue.main.async {
            switch event {
            case "play":
                self.engineController.isPlaying = true
            case "pause":
                self.engineController.isPlaying = false
            case "indexChange":
                if let idx = dict["index"] as? Int {
                    self.engineController.currentIndex = idx
                }
            case "playlist":
                if let trackData = dict["tracks"] as? [[String: Any]] {
                    self.engineController.tracks = trackData.compactMap { d in
                        guard let id = d["id"] as? Int,
                              let title = d["title"] as? String,
                              let user = d["user"] as? String else { return nil }
                        return SoundCloudTrack(id: id, title: title, user: user, artwork: d["artwork"] as? String)
                    }
                }
            case "metadata":
                self.engineController.currentTrackTitle = dict["title"] as? String ?? "Unknown Title"
                self.engineController.currentTrackArtist = dict["user"] as? String ?? "Unknown Artist"
                self.engineController.currentArtworkUrl = dict["artwork"] as? String
            default:
                break
            }
        }
    }
}
