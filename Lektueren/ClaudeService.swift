//
//  ClaudeService.swift
//  Lektüren
//
//  Service für die Kommunikation mit der Claude AI API zur Extraktion von PDF-Metadaten.
//
import Foundation
import PDFKit

// MARK: - Claude API Models

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

// MARK: - Extracted Metadata

struct ExtractedPDFMetadata {
    var title: String?
    var author: String?
    var creationDate: Date?
    var summary: String?
    var keywords: [String]
}

// MARK: - Claude Service

@MainActor
class ClaudeService {
    static let shared = ClaudeService()
    
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    
    // Hole das funktionierende Model aus den UserDefaults (wird beim Verbindungstest gespeichert)
    private var model: String {
        UserDefaults.standard.string(forKey: "workingClaudeModel") ?? "claude-3-sonnet-20240229"
    }
    
    private init() {}
    
    /// Extrahiert Metadaten aus einem PDF mit Claude AI.
    func extractMetadata(from pdfURL: URL, apiKey: String) async throws -> ExtractedPDFMetadata {
        // PDF-Text extrahieren (erste 3 Seiten)
        let pdfText = extractText(from: pdfURL, maxPages: 3)
        
        guard !pdfText.isEmpty else {
            throw ClaudeServiceError.noTextExtracted
        }
        
        // Prompt für Claude erstellen
        let prompt = """
        Analysiere den folgenden PDF-Text und extrahiere die folgenden Informationen im JSON-Format:
        
        {
          "title": "Der Titel des Dokuments",
          "author": "Name des Autors",
          "creationDate": "YYYY-MM-DD (falls erkennbar, sonst null)",
          "summary": "Zusammenfassung in maximal 240 Wörtern",
          "keywords": ["Keyword1", "Keyword2", "Keyword3", ...]
        }
        
        Wichtig:
        - Der Titel sollte der Haupttitel des Dokuments sein
        - Der Autor kann eine Person, Organisation oder Institution sein
        - Das Datum sollte das Erstellungsdatum des Dokuments sein, nicht das heutige Datum
        - Die Zusammenfassung soll maximal 240 Wörter haben und die wichtigsten Inhalte beschreiben
        - Keywords sollten die Hauptthemen und Konzepte des Dokuments beschreiben (5-10 Keywords)
        - Antworte NUR mit dem JSON-Objekt, ohne zusätzlichen Text
        
        PDF-Text:
        
        \(pdfText)
        """
        
        // API-Request vorbereiten
        let request = ClaudeRequest(
            model: model,
            maxTokens: 1024,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )
        
        // HTTP-Request erstellen
        var urlRequest = URLRequest(url: apiURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        print("🤖 [Claude AI] Sende Request an: \(apiURL.absoluteString)")
        print("🤖 [Claude AI] Model: \(model)")
        print("🤖 [Claude AI] Text-Länge: \(pdfText.count) Zeichen")
        
        // Request ausführen
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [Claude AI] Ungültige Response - kein HTTPURLResponse")
            throw ClaudeServiceError.invalidResponse
        }
        
        print("🤖 [Claude AI] Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [Claude AI] API-Fehler (\(httpResponse.statusCode))")
            print("❌ [Claude AI] Response Headers: \(httpResponse.allHeaderFields)")
            print("❌ [Claude AI] Error Body: \(errorMessage)")
            
            // Versuche, strukturierte Fehlermeldung zu extrahieren
            var detailedMessage = errorMessage
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String,
                   let type = error["type"] as? String {
                    detailedMessage = "[\(type)] \(message)"
                    print("❌ [Claude AI] Strukturierter Fehler: \(detailedMessage)")
                }
            }
            
            throw ClaudeServiceError.apiError(statusCode: httpResponse.statusCode, message: detailedMessage)
        }
        
        print("✅ [Claude AI] Erfolgreiche Response erhalten")
        
        // Response parsen
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        
        guard let textContent = claudeResponse.content.first?.text else {
            throw ClaudeServiceError.noContentInResponse
        }
        
        // JSON aus der Antwort extrahieren
        return try parseMetadataJSON(textContent)
    }
    
    /// Extrahiert Text aus einem PDF (erste n Seiten).
    private func extractText(from url: URL, maxPages: Int = 3) -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            return ""
        }
        
        let pageCount = min(pdfDocument.pageCount, maxPages)
        var text = ""
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                text += pageText + "\n\n"
            }
        }
        
        // Text auf maximal 15000 Zeichen begrenzen (um API-Limits zu respektieren)
        if text.count > 15000 {
            text = String(text.prefix(15000))
        }
        
        return text
    }
    
    /// Parst die JSON-Antwort von Claude.
    private func parseMetadataJSON(_ jsonString: String) throws -> ExtractedPDFMetadata {
        // JSON aus dem Text extrahieren (falls zusätzlicher Text vorhanden ist)
        let cleanedJSON: String
        if let startIndex = jsonString.firstIndex(of: "{"),
           let endIndex = jsonString.lastIndex(of: "}") {
            cleanedJSON = String(jsonString[startIndex...endIndex])
        } else {
            cleanedJSON = jsonString
        }
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw ClaudeServiceError.invalidJSON
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json else {
            throw ClaudeServiceError.invalidJSON
        }
        
        // Datum parsen
        var creationDate: Date? = nil
        if let dateString = json["creationDate"] as? String,
           dateString != "null" && !dateString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            creationDate = formatter.date(from: dateString)
        }
        
        // Keywords extrahieren
        var keywords: [String] = []
        if let keywordsArray = json["keywords"] as? [String] {
            keywords = keywordsArray
        }
        
        return ExtractedPDFMetadata(
            title: json["title"] as? String,
            author: json["author"] as? String,
            creationDate: creationDate,
            summary: json["summary"] as? String,
            keywords: keywords
        )
    }
}

// MARK: - Errors

enum ClaudeServiceError: LocalizedError {
    case noTextExtracted
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContentInResponse
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .noTextExtracted:
            return "Aus dem PDF konnte kein Text extrahiert werden."
        case .invalidResponse:
            return "Ungültige Antwort vom Claude API-Server."
        case .apiError(let statusCode, let message):
            return "API-Fehler (\(statusCode)): \(message)"
        case .noContentInResponse:
            return "Die Antwort von Claude enthält keinen Text."
        case .invalidJSON:
            return "Die JSON-Antwort konnte nicht geparst werden."
        }
    }
}
