//
//  ChatWebInputView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI
import WebKit

struct WebViewChatField: View {
    @ObservedObject private var chatViewModel = ChatViewModel.shared

    static let minTextHeight: CGFloat = 40
    static let maxTextHeight: CGFloat = 500

    var body: some View {
        WebViewChatFieldRepresentable()
            .frame(height: max(ChatEditorView.minTextHeight, min(chatViewModel.textHeight, ChatEditorView.maxTextHeight)))
    }
}

struct WebViewChatFieldRepresentable: NSViewRepresentable {
    private var chatViewModel = ChatViewModel.shared
    @ObservedObject private var textViewModel = TextViewModel.shared

    func makeNSView(context: Context) -> WKWebView {
        let webView = CustomWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Set transparent background
        webView.setValue(false, forKey: "drawsBackground")

        // Add user script message handlers
        let contentController = webView.configuration.userContentController
        contentController.add(context.coordinator, name: "textChanged")
        contentController.add(context.coordinator, name: "heightChanged")
        contentController.add(context.coordinator, name: "submit")

        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context _: Context) {
        nsView.evaluateJavaScript("document.getElementById('editor').innerHTML = `\(textViewModel.text)`", completionHandler: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        var parent: WebViewChatFieldRepresentable

        init(_ parent: WebViewChatFieldRepresentable) {
            self.parent = parent
        }

        func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "textChanged":
                if let text = message.body as? String {
                    DispatchQueue.main.async {
                        self.parent.textViewModel.text = text
                    }
                    print("Text changed: \(text)")
                }

            case "heightChanged":
                if let height = message.body as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.chatViewModel.textHeight = height
                    }
                    print("Height changed: \(height)")
                }

            case "submit":
                DispatchQueue.main.async {
                    // Handle text submission
                    print("Text submitted: \(self.parent.textViewModel.text)")
                    self.parent.textViewModel.text = "" // Clear text after submission
                }

            default:
                break
            }
        }
    }

    private var htmlContent: String {
        // Fetch the system's accent color
        let accentColor = NSColor.controlAccentColor.usingColorSpace(.deviceRGB)
        let accentColorStr = String(format: "rgba(%d, %d, %d, %.2f)", Int(accentColor!.redComponent * 255.0), Int(accentColor!.greenComponent * 255.0), Int(accentColor!.blueComponent * 255.0), accentColor!.alphaComponent)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <style>
                body, html {
                    margin: 0;
                    padding: 0;
                    height: 100%;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    background-color: transparent;
                }
                #editor {
                    min-height: 20px;
                    padding: 10px;
                    outline: none;
                    word-wrap: break-word;
                    overflow-y: hidden;
                    background-color: transparent;
                }
                input, textarea, div[contenteditable] {
                    caret-color: \(accentColorStr);
                }
            </style>
        </head>
        <body>
            <div id="editor" contenteditable="true"></div>
            <script>
                const editor = document.getElementById('editor');

                function updateHeight() {
                    const height = editor.scrollHeight;
                    webkit.messageHandlers.heightChanged.postMessage(height);
                }

                function moveCursorToEnd() {
                    const range = document.createRange();
                    const selection = window.getSelection();
                    range.selectNodeContents(editor);
                    range.collapse(false);
                    selection.removeAllRanges();
                    selection.addRange(range);
                }

                editor.addEventListener('input', function() {
                    webkit.messageHandlers.textChanged.postMessage(editor.innerHTML);
                    updateHeight();
                    moveCursorToEnd();
                });

                editor.addEventListener('paste', function(e) {
                    e.preventDefault();
                    const text = e.clipboardData.getData('text/plain');
                    document.execCommand('insertText', false, text);
                    setTimeout(() => {
                        updateHeight();
                        moveCursorToEnd();
                    }, 10);  // Delay to ensure height is updated
                });

                editor.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        webkit.messageHandlers.submit.postMessage('');
                    }
                });

                editor.addEventListener('keypress', function(e) {
                    if (e.key === 'Enter' && e.shiftKey) {
                        // Allow Shift + Enter for new line
                        e.preventDefault();
                        document.execCommand('insertLineBreak');
                        updateHeight();
                        moveCursorToEnd();
                    }
                });

                editor.addEventListener('keydown', function(e) {
                    // Handle copy, cut, paste via Command keys
                    if ((e.metaKey || e.ctrlKey) && (e.key === 'c' || e.key === 'x' || e.key === 'v')) {
                        document.execCommand(e.key);
                        updateHeight();
                        moveCursorToEnd();
                    } else if ((e.metaKey || e.ctrlKey) && e.key === 'a') {
                        // Command + A: Select All
                        e.preventDefault();
                        document.execCommand('selectAll');
                    } else {
                        // Delay height adjustment to ensure correct rendering
                        setTimeout(() => {
                            updateHeight();
                            moveCursorToEnd();
                        }, 10);
                    }
                });

                new MutationObserver(() => {
                    updateHeight();
                    moveCursorToEnd();
                }).observe(editor, {
                    attributes: true,
                    childList: true,
                    subtree: true
                });

                updateHeight();
            </script>
        </body>
        </html>
        """
    }

    class CustomWebView: WKWebView {
        override var intrinsicContentSize: CGSize {
            .init(width: super.intrinsicContentSize.width, height: .zero)
        }

        override func scrollWheel(with event: NSEvent) {
            super.scrollWheel(with: event)
            nextResponder?.scrollWheel(with: event)
        }

        override func willOpenMenu(_ menu: NSMenu, with _: NSEvent) {
            menu.items.removeAll { $0.identifier == .init("WKMenuItemIdentifierReload") }
        }

        override func keyDown(with event: NSEvent) {
            // Ensure command keys work correctly in macOS
            if event.modifierFlags.contains(.command) {
                nextResponder?.keyDown(with: event)
                return
            }
            super.keyDown(with: event)
        }

        override func keyUp(with event: NSEvent) {
            nextResponder?.keyUp(with: event)
        }

        override func flagsChanged(with event: NSEvent) {
            nextResponder?.flagsChanged(with: event)
        }
    }
}
