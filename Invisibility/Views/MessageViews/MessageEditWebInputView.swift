import SwiftUI
import WebKit

struct EditWebInputView: View {
    @ObservedObject private var branchManagerModel = BranchManagerModel.shared

    var body: some View {
        EditWebInputRepresentable()
            .frame(height: branchManagerModel.editViewHeight)
    }
}

struct EditWebInputRepresentable: NSViewRepresentable {
    @ObservedObject private var branchManagerModel = BranchManagerModel.shared

    func makeNSView(context: Context) -> WKWebView {
        let webView = CustomWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        webView.setValue(false, forKey: "drawsBackground")

        let contentController = webView.configuration.userContentController
        contentController.add(context.coordinator, name: "textChanged")
        contentController.add(context.coordinator, name: "heightChanged")
        contentController.add(context.coordinator, name: "submit")

        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context _: Context) {
        nsView.evaluateJavaScript("updateEditorContent(`\(branchManagerModel.editText.escapedForJS)`)", completionHandler: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        var parent: EditWebInputRepresentable

        init(_ parent: EditWebInputRepresentable) {
            self.parent = parent
        }

        func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "textChanged":
                if let text = message.body as? String {
                    DispatchQueue.main.async {
                        self.parent.branchManagerModel.editText = text
                    }
                }
            case "heightChanged":
                if let height = message.body as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.branchManagerModel.editViewHeight = height
                    }
                }
            case "submit":
                 DispatchQueue.main.async {
                     Task {
                         await MessageViewModel.shared.sendFromChat(editMode: true)
                     }
                 }
            default:
                break
            }
        }
    }

    private var htmlContent: String {
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
                    font-size: 10pt;
                    line-height: 1.5;
                }

                body::-webkit-scrollbar {
                    display: none !important;
                }

                #editor {
                    min-height: 20px;
                    outline: none;
                    word-wrap: break-word;
                    overflow-y: hidden;
                    background-color: transparent;
                    white-space: pre-wrap;
                    padding: 0;
                    margin: 0;
                }
                input, textarea, div[contenteditable] {
                    caret-color: \(accentColorStr);
                }
            </style>
        </head>
        <body>
            <div id="editor" contenteditable="true">\(branchManagerModel.editText.escapedForHTML)</div>
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

                editor.addEventListener('input', function() {
                    webkit.messageHandlers.textChanged.postMessage(editor.innerText);
                    updateHeight();
                });

                editor.addEventListener('paste', function(e) {
                    e.preventDefault();
                    const text = e.clipboardData.getData('text/plain');
                    document.execCommand('insertText', false, text);
                });
        
                editor.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        webkit.messageHandlers.submit.postMessage('');
                    } else if (e.key === 'Enter' && e.shiftKey) {
                        e.preventDefault();
                        document.execCommand('insertLineBreak');
                        updateHeight();
                    }
                });
        
                // ensure caret is always visible
                function scrollCaretIntoView() {
                    const selection = window.getSelection();
                    if (selection.rangeCount > 0) {
                        const range = selection.getRangeAt(0);
                        const rect = range.getBoundingClientRect();
                        if (rect.bottom > window.innerHeight) {
                            window.scrollTo(0, window.pageYOffset + rect.bottom - window.innerHeight + 20);
                        }
                    }
                }

                new MutationObserver(function() {
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

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
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
}

extension String {
    var escapedForJS: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
                   .replacingOccurrences(of: "'", with: "\\'")
                   .replacingOccurrences(of: "\"", with: "\\\"")
                   .replacingOccurrences(of: "\n", with: "\\n")
                   .replacingOccurrences(of: "\r", with: "\\r")
                   .replacingOccurrences(of: "\t", with: "\\t")
                   .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
                   .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }
    
    var escapedForHTML: String {
        return self.replacingOccurrences(of: "&", with: "&amp;")
                   .replacingOccurrences(of: "<", with: "&lt;")
                   .replacingOccurrences(of: ">", with: "&gt;")
                   .replacingOccurrences(of: "\"", with: "&quot;")
                   .replacingOccurrences(of: "'", with: "&#39;")
    }
}
