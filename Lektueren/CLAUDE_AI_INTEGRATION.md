# Claude AI Integration für PDF-Metadaten-Extraktion

## Übersicht

Die Lektüren-App nutzt Claude AI (Anthropic) zur automatischen Extraktion von Metadaten aus importierten PDFs.

## Was wird extrahiert?

Bei jedem PDF-Import werden folgende Informationen automatisch von Claude AI analysiert:

- **Titel** - Der Haupttitel des Dokuments
- **Autor** - Name des Autors, Organisation oder Institution
- **Erstellungsdatum** - Das Datum, an dem das Dokument erstellt wurde
- **Zusammenfassung** - Eine prägnante Zusammenfassung in maximal 240 Wörtern
- **Keywords/Tags** - 5-10 Schlagwörter, die die Hauptthemen beschreiben

## Einrichtung

### 1. Claude API-Key erhalten

1. Besuchen Sie [https://console.anthropic.com/](https://console.anthropic.com/)
2. Erstellen Sie ein Konto oder melden Sie sich an
3. Navigieren Sie zu "API Keys"
4. Erstellen Sie einen neuen API-Key
5. Kopieren Sie den Key (Sie sehen ihn nur einmal!)

### 2. API-Key in der App konfigurieren

1. Öffnen Sie die Lektüren-App
2. Klicken Sie auf das **Zahnrad-Symbol** (⚙️) in der Toolbar
3. Fügen Sie Ihren API-Key im Feld "Claude API" ein
4. Optional: Testen Sie die Verbindung mit "Verbindung testen"
5. Klicken Sie auf "Fertig"

### 3. AI-Extraktion aktivieren/deaktivieren

In den Einstellungen können Sie:
- Die AI-Extraktion komplett aktivieren/deaktivieren
- Den API-Key ändern oder entfernen

## Verwendung

### Beim Import

Sobald Sie PDFs importieren:
1. Die Datei wird normal importiert (sofort verfügbar)
2. Im Hintergrund startet die AI-Analyse
3. Die extrahierten Daten erscheinen im Inspector (rechte Sidebar)
4. Die Analyse wird in der Konsole protokolliert:
   - `🤖 Starte AI-Extraktion für: [Dateiname]`
   - `✅ AI-Extraktion erfolgreich für: [Dateiname]`
   - `❌ AI-Extraktion fehlgeschlagen für: [Dateiname]` (bei Fehler)

### Anzeige der extrahierten Daten

1. Öffnen Sie ein PDF in der Detail-Ansicht
2. Der Inspector (rechts) zeigt eine neue Sektion "AI-Analyse"
3. Alle extrahierten Informationen werden dort angezeigt:
   - Titel (AI)
   - Autor (AI)
   - Erstellt (AI)
   - Zusammenfassung
   - Keywords (als farbige Tags)

## Technische Details

### Dateien

- **`ClaudeService.swift`** - Service für die API-Kommunikation
- **`SettingsView.swift`** - Einstellungen-UI
- **`PDFItem.swift`** - Erweitert um AI-Felder:
  - `aiExtractedTitle: String?`
  - `aiExtractedAuthor: String?`
  - `aiExtractedDate: Date?`
  - `aiSummary: String?`
  - `aiKeywords: [String]`
- **`PDFTreeViewModel.swift`** - Import-Logik mit AI-Integration
- **`PDFDetailView.swift`** - Anzeige der AI-Daten im Inspector

### API-Nutzung

- **Modell**: `claude-3-5-sonnet-20241022`
- **Max Tokens**: 1024 pro Request
- **PDF-Text**: Die ersten 3 Seiten (max. 15.000 Zeichen)
- **Asynchron**: Die Extraktion läuft im Hintergrund, blockiert nicht den Import

### Fehlerbehandlung

Falls die AI-Extraktion fehlschlägt:
- Das PDF ist trotzdem verfügbar (Import unabhängig von AI)
- Fehler werden in der Konsole protokolliert
- Standard-Metadaten (aus PDF-Header) bleiben verfügbar

### Datenschutz

- Der API-Key wird lokal in `UserDefaults` gespeichert
- PDFs werden nur an Anthropic gesendet, wenn explizit aktiviert
- Keine Daten werden dauerhaft bei Anthropic gespeichert

## Kosten

Die Claude API ist kostenpflichtig:
- Preise variieren je nach Modell und Nutzung
- Siehe: [https://www.anthropic.com/pricing](https://www.anthropic.com/pricing)
- Pro PDF: ca. 0,01-0,05 USD (abhängig vom Umfang)

## Fehlerbehebung

### "API-Fehler (401)"
→ Ungültiger API-Key. Überprüfen Sie den Key in den Einstellungen.

### "API-Fehler (429)"
→ Rate-Limit erreicht. Warten Sie einige Minuten und versuchen Sie es erneut.

### "Aus dem PDF konnte kein Text extrahiert werden"
→ Das PDF enthält möglicherweise nur Bilder (gescannte Dokumente). OCR ist nicht enthalten.

### "Die JSON-Antwort konnte nicht geparst werden"
→ Claude hat eine unerwartete Antwort geliefert. Normalerweise selten, einfach erneut importieren.

## Deaktivierung

Um die AI-Extraktion zu deaktivieren:
1. Öffnen Sie die Einstellungen (⚙️)
2. Deaktivieren Sie "AI-Metadaten-Extraktion aktivieren"
3. Optional: Entfernen Sie den API-Key

## Support

Bei Problemen:
1. Prüfen Sie die Konsole auf Fehlermeldungen
2. Testen Sie die API-Verbindung in den Einstellungen
3. Stellen Sie sicher, dass Ihr API-Key noch gültig ist
