//
//  MarkdownPDFRenderer.swift
//  Lektüren
//
//  Konvertiert Markdown zu PDF über: Markdown → HTML → WKWebView → PDF Data.
//  Verwendet reine Apple-Frameworks (WebKit).
//

import Foundation
import WebKit
import UIKit

@MainActor
struct MarkdownPDFRenderer {

    /// Rendert Markdown-Inhalt in PDF-Daten.
    /// - Parameters:
    ///   - markdown: Der Markdown-String
    ///   - topic: Das Berichtsthema (wird als Titel verwendet)
    /// - Returns: PDF-Daten, oder nil falls Rendering fehlschlägt
    static func renderToPDF(markdown: String, topic: String) async -> Data? {
        let html = markdownToHTML(markdown, topic: topic)

        // Offscreen WKWebView erstellen (A4-Format: 595 x 842 Punkte)
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842), configuration: config)

        return await withCheckedContinuation { continuation in
            let delegate = PDFWebViewDelegate { [webView] in
                Task { @MainActor in
                    do {
                        // Kein rect setzen → WKWebView paginiert den gesamten Content
                        // automatisch auf mehrere A4-Seiten basierend auf der Frame-Breite
                        let pdfConfig = WKPDFConfiguration()
                        let data = try await webView.pdf(configuration: pdfConfig)
                        print("✅ [PDF Renderer] PDF erstellt, Größe: \(data.count) Bytes")
                        continuation.resume(returning: data)
                    } catch {
                        print("❌ [PDF Renderer] PDF-Erstellung fehlgeschlagen: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
            }
            // Referenz halten damit der Delegate nicht freigegeben wird
            _currentDelegate = delegate
            webView.navigationDelegate = delegate
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    /// Hält eine Referenz auf den aktuellen Delegate während des Renderings.
    private static var _currentDelegate: PDFWebViewDelegate?

    // MARK: - Markdown → HTML

    /// Einfacher regex-basierter Markdown-zu-HTML-Konverter.
    /// Unterstützt: Überschriften, Fett, Kursiv, Listen, Absätze, Trennlinien.
    static func markdownToHTML(_ markdown: String, topic: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var htmlLines: [String] = []
        var inList = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Leere Zeile
            if trimmed.isEmpty {
                if inList {
                    htmlLines.append("</ul>")
                    inList = false
                }
                htmlLines.append("")
                continue
            }

            // Überschriften
            if trimmed.hasPrefix("### ") {
                if inList { htmlLines.append("</ul>"); inList = false }
                let text = applyInlineFormatting(String(trimmed.dropFirst(4)))
                htmlLines.append("<h3>\(text)</h3>")
                continue
            }
            if trimmed.hasPrefix("## ") {
                if inList { htmlLines.append("</ul>"); inList = false }
                let text = applyInlineFormatting(String(trimmed.dropFirst(3)))
                htmlLines.append("<h2>\(text)</h2>")
                continue
            }
            if trimmed.hasPrefix("# ") {
                if inList { htmlLines.append("</ul>"); inList = false }
                let text = applyInlineFormatting(String(trimmed.dropFirst(2)))
                htmlLines.append("<h1>\(text)</h1>")
                continue
            }

            // Trennlinie
            if trimmed.hasPrefix("---") && trimmed.allSatisfy({ $0 == "-" || $0 == " " }) {
                if inList { htmlLines.append("</ul>"); inList = false }
                htmlLines.append("<hr>")
                continue
            }

            // Listenpunkte
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !inList {
                    htmlLines.append("<ul>")
                    inList = true
                }
                let text = applyInlineFormatting(String(trimmed.dropFirst(2)))
                htmlLines.append("<li>\(text)</li>")
                continue
            }

            // Nummerierte Listen
            if let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                if !inList {
                    htmlLines.append("<ol>")
                    inList = true
                }
                let text = applyInlineFormatting(String(trimmed[range.upperBound...]))
                htmlLines.append("<li>\(text)</li>")
                continue
            }

            // Absatz
            if inList { htmlLines.append("</ul>"); inList = false }
            let text = applyInlineFormatting(trimmed)
            htmlLines.append("<p>\(text)</p>")
        }

        if inList {
            htmlLines.append("</ul>")
        }

        let bodyHTML = htmlLines.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escapeHTML(topic))</title>
        <style>
            @page {
                size: A4;
                margin: 2cm;
            }
            body {
                font-family: -apple-system, 'Helvetica Neue', Helvetica, sans-serif;
                font-size: 11pt;
                line-height: 1.6;
                color: #1a1a1a;
                margin: 40px;
                max-width: 100%;
            }
            h1 {
                font-size: 18pt;
                color: #0a3d62;
                border-bottom: 2px solid #0a3d62;
                padding-bottom: 6px;
                margin-top: 24px;
                margin-bottom: 12px;
            }
            h2 {
                font-size: 14pt;
                color: #1e5f8a;
                margin-top: 20px;
                margin-bottom: 8px;
                border-bottom: 1px solid #ddd;
                padding-bottom: 4px;
            }
            h3 {
                font-size: 12pt;
                color: #2c7fb8;
                margin-top: 16px;
                margin-bottom: 6px;
            }
            p {
                margin: 6px 0;
                text-align: justify;
            }
            ul, ol {
                padding-left: 24px;
                margin: 8px 0;
            }
            li {
                margin: 4px 0;
            }
            hr {
                border: none;
                border-top: 1px solid #ccc;
                margin: 20px 0;
            }
            strong {
                color: #0a3d62;
            }
            em {
                font-style: italic;
            }
            .header {
                text-align: center;
                margin-bottom: 30px;
                padding-bottom: 16px;
                border-bottom: 3px solid #0a3d62;
            }
            .header h1 {
                border: none;
                margin-bottom: 4px;
            }
            .header .topic {
                font-size: 14pt;
                color: #333;
                font-weight: 600;
            }
            .header .date {
                font-size: 9pt;
                color: #888;
                margin-top: 8px;
            }
            .footer {
                text-align: center;
                font-size: 8pt;
                color: #aaa;
                margin-top: 40px;
                padding-top: 10px;
                border-top: 1px solid #eee;
            }
        </style>
        </head>
        <body>
        <div class="header">
            <h1>Erkenntnisbericht</h1>
            <p class="topic">\(escapeHTML(topic))</p>
            <p class="date">Erstellt am \(dateString())</p>
        </div>
        \(bodyHTML)
        <div class="footer">
            Generiert mit Lektüren App
        </div>
        </body>
        </html>
        """
    }

    // MARK: - Inline Formatting

    /// Wendet Inline-Formatierung an (Fett, Kursiv).
    private static func applyInlineFormatting(_ text: String) -> String {
        var result = text

        // Fett: **text**
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        // Kursiv: *text*
        result = result.replacingOccurrences(
            of: #"\*(.+?)\*"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )

        return result
    }

    /// HTML-Sonderzeichen escapen.
    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Formatiertes Datum für den Bericht.
    private static func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "de_CH")
        return formatter.string(from: Date())
    }
}

// MARK: - WKNavigationDelegate für PDF-Generierung

private class PDFWebViewDelegate: NSObject, WKNavigationDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Kurze Verzögerung um sicherzustellen, dass das Rendering abgeschlossen ist
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onFinish()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [PDF Renderer] WebView-Navigation fehlgeschlagen: \(error)")
        onFinish()
    }
}
