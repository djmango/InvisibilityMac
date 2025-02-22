//
//  ChatWebInputView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Combine
import SwiftUI
import WebKit

// TODO: fix scrollbars on this, currently they are disabled due to white background bug

struct ChatWebInputView: View {
    @ObservedObject private var viewModel = ChatWebInputViewModel.shared

    static let minTextHeight: CGFloat = 40
    static let maxTextHeight: CGFloat = 500

    var body: some View {
        let _ = Self._printChanges()
        ChatWebInputViewRepresentable()
            .frame(height: max(ChatWebInputView.minTextHeight, min(viewModel.height, ChatWebInputView.maxTextHeight)))
    }
}

struct ChatWebInputViewRepresentable: NSViewRepresentable {
    private var messageViewModel = MessageViewModel.shared
    private var viewModel = ChatWebInputViewModel.shared
    private var voiceRecorder: VoiceRecorder = .shared

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

        // Observe changes to transcribedText
        voiceRecorder.$transcribedText.sink { newText in
            DispatchQueue.main.async {
                self.viewModel.text = newText
                webView.evaluateJavaScript("updateEditorContent(`\(newText.replacingOccurrences(of: "`", with: "\\`"))`)", completionHandler: nil)
            }
        }.store(in: &context.coordinator.cancellables)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context _: Context) {
        nsView.evaluateJavaScript("updateEditorContent(`\(viewModel.text.replacingOccurrences(of: "`", with: "\\`"))`)", completionHandler: nil)
    }

    private func setFocus(_ webView: WKWebView) {
        webView.evaluateJavaScript("document.getElementById('editor').focus();", completionHandler: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        var parent: ChatWebInputViewRepresentable
        var cancellables = Set<AnyCancellable>()

        init(_ parent: ChatWebInputViewRepresentable) {
            self.parent = parent
        }

        func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "textChanged":
                if let text = message.body as? String {
                    DispatchQueue.main.async {
                        self.parent.viewModel.text = text
                    }
                }
            case "heightChanged":
                if let height = message.body as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.viewModel.height = height
                    }
                }
            case "submit":
                DispatchQueue.main.async {
                    Task {
                        await self.parent.messageViewModel.sendFromChat()
                        await self.parent.voiceRecorder.stop(shouldClearText: true)
                    }
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
                :root {
                    color-scheme: light dark !important;
                }

                body, html {
                    margin: 0;
                    padding: 0;
                    height: 100%;
                    background-color: transparent;
                    color: -apple-system-label;
                    font-family: system-ui;
                    font-size: 11pt;
                    line-height: 1.5;
                }

                body::-webkit-scrollbar {
                    display: none !important;
                }

                #editor {
                    min-height: 20px;
                    padding: 10px;
                    outline: none;
                    word-wrap: break-word;
                    overflow-y: hidden;
                    background-color: transparent;
                    white-space: pre-wrap;
                }
                #editor:empty:before {
                    content: attr(placeholder);
                    color: gray;
                    pointer-events: none;
                }
                input, textarea, div[contenteditable] {
                    caret-color: \(accentColorStr);
                }
            </style>
        </head>
        <body>
            <div id="editor" contenteditable="true" placeholder="Message Invisibility"></div>
            <script>
            const editor = document.getElementById('editor');
            let lastHeight = 0;

            function updateHeight() {
                const newHeight = editor.scrollHeight;
                if (newHeight !== lastHeight) {
                    lastHeight = newHeight;
                    webkit.messageHandlers.heightChanged.postMessage(newHeight);
                }
            }

            function updateEditorContent(content) {
                if (editor.innerText !== content) {
                    editor.innerText = content;
                    updateHeight();
                    placeCaretAtEnd();
                }
            }

            function placeCaretAtEnd() {
                const range = document.createRange();
                const selection = window.getSelection();
                range.selectNodeContents(editor);
                range.collapse(false);
                selection.removeAllRanges();
                selection.addRange(range);
                editor.focus();
            }

            function resetEditor() {
                editor.innerText = '';
                updateHeight();
            }

            editor.addEventListener('input', function() {
                if (editor.innerHTML === '<br>') {
                    editor.innerHTML = '';
                }
                webkit.messageHandlers.textChanged.postMessage(editor.innerText);
                updateHeight();
            });

            editor.addEventListener('paste', function(e) {
                e.preventDefault();
                const text = e.clipboardData.getData('text/plain');
                document.execCommand('insertText', false, text);
                webkit.messageHandlers.textChanged.postMessage(editor.innerText);
                updateHeight();
            });

            editor.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault(); // Prevent default more aggressively
                    if (!e.shiftKey) {
                        webkit.messageHandlers.submit.postMessage('');
                        resetEditor();
                    } else {
                        document.execCommand('insertLineBreak');
                        updateHeight();
                    }
                }
            });

            // Ensure editor always has content
            editor.addEventListener('blur', function() {
                if (editor.innerHTML === '') {
                    editor.innerHTML = '<br>';
                }
            });

            new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList') {
                        const br = editor.querySelector('br');
                        if (br && br.parentNode === editor) {
                            br.remove();
                        }
                    }
                });
                updateHeight();
            }).observe(editor, {
                attributes: true,
                childList: true,
                subtree: true,
                characterData: true
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

        // Command forwarding
        override func flagsChanged(with event: NSEvent) {
            super.flagsChanged(with: event)

            // Forward the event to the window
            if let window = self.window {
                window.flagsChanged(with: event)
            }

            // Post notification for command key state
            NotificationCenter.default.post(name: .commandKeyPressed, object: nil, userInfo: ["isPressed": event.modifierFlags.contains(.command)])
        }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if event.modifierFlags.contains(.command) {
                NotificationCenter.default.post(name: .commandKeyPressed, object: nil, userInfo: ["isPressed": false])

                // Forward the event to the window
                if let window = self.window {
                    window.flagsChanged(with: event)
                }

                switch event.charactersIgnoringModifiers {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSStandardKeyBindingResponding.selectAll(_:)), to: nil, from: self) { return true }
                default:
                    break
                }
            }
            return super.performKeyEquivalent(with: event)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeKey), name: NSWindow.didBecomeKeyNotification, object: nil)
        }

        @objc private func windowDidBecomeKey() {
            self.evaluateJavaScript("document.getElementById('editor').focus();", completionHandler: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

extension Notification.Name {
    static let commandKeyPressed = Notification.Name("commandKeyPressed")
}
