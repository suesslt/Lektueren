# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

This is an Xcode project (no SPM). Build and test via Xcode or:
```bash
# Ensure Xcode is selected (not CommandLineTools)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Build
xcodebuild build -project Lektueren.xcodeproj -scheme Lektueren -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -quiet

# Run tests
xcodebuild test -project Lektueren.xcodeproj -scheme Lektueren -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -quiet
```

No external dependencies — pure Apple frameworks only (SwiftUI, SwiftData, PDFKit, CryptoKit).

## Architecture

SwiftUI + SwiftData app for importing, organizing, and AI-analyzing PDF files. German-language UI ("Lektüren" = "Readings").

**Data flow:** Import PDFs → SHA256 dedup check → extract PDF metadata → copy to iCloud → create SwiftData model → async AI extraction via Claude API → update model.

### Layers

- **Views** (`TripleColumnLayout`, `PDFDetailView`, `TreeContentView`, etc.) — SwiftUI views parameterized by `<VM: TreeViewModel>` protocol for genericity
- **View Model** (`PDFTreeViewModel`) — `@Observable @MainActor`, manages folder/item state, search filtering, import logic, deletion, AI extraction coordination
- **Services** — `ClaudeService` (singleton, Claude API with model fallback) and `PDFCloudStorage` (static utility for iCloud Documents)
- **Models** — `PDFItem` and `PDFFolder` as `@Model` (SwiftData) implementing `TreeItem`/`TreeFolder` protocols

### Key Protocols

`TreeViewModel`, `TreeItem`, `TreeFolder` — generic tree-structure protocols that `PDFTreeViewModel`, `PDFItem`, and `PDFFolder` conform to. Views use `<VM: TreeViewModel>` so they're decoupled from concrete types.

### Data Models

**PDFItem** stores both PDF header metadata (author, pageCount, creator, etc.) and AI-extracted metadata (`aiExtractedTitle`, `aiSummary`, `aiKeywords`, etc.) as separate fields. File references use `pdfRelativePath` (relative to iCloud container) with `pdfUrl` computed at runtime.

**PDFFolder** supports hierarchy via `parent`/`storedSubfolders` relationships. A virtual "All Readings" folder (UUID `00000000-0000-0000-0000-000000000001`) aggregates all items across folders.

### Claude AI Integration

`ClaudeService` sends first 3 pages of PDF text (max 15K chars) to the Claude API. It uses a model fallback system — tries multiple model IDs and caches the working one in UserDefaults. Extraction is async and non-blocking; items appear immediately, metadata fills in later. API key is configured in Settings.

### iCloud Storage

PDFs are copied to iCloud Documents container (`iCloud.com.suessli.Lektueren`) with UUID-prefixed filenames for deduplication. `PDFCloudStorage.ensureDownloaded()` triggers download of cloud-only files before viewing.

## Conventions

- German UI strings and comments throughout
- `@MainActor` on view models and services that touch UI state
- `async/await` for all background work (no Combine)
- Structured logging with emoji prefixes in console output
- Error enums implement `LocalizedError` with descriptive messages
- AI-extracted fields prefixed with `ai` (e.g., `aiSummary`, `aiKeywords`)
- SwiftData enums stored as raw values with `@Transient` computed typed accessors

## Score Package — Shared Base Classes

The [Score](../score) package (`import Score` / `import ScoreUI`) is a shared local SPM library providing financial and utility base types used across sibling projects. While this project does not currently depend on Score, the following types are available:

| Type | Module | Description |
|------|--------|-------------|
| `Money` | Score | Currency-safe monetary amounts with `Decimal` precision. Arithmetic enforces matching currencies. |
| `Currency` | Score | ISO 4217 enum with 180+ currencies, decimal places, and localized names. |
| `Percent` | Score | Percentage as factor (e.g. `0.10` = 10%). |
| `FXRate` | Score | Bid/ask exchange rates with conversion methods. |
| `VATCalculation` | Score | VAT split (net/gross) with inclusive/exclusive handling. |
| `YearMonth` | Score | Year-month value type for monthly periods. |
| `DayCountRule` | Score | Financial day count conventions (ACT/360, ACT/365, 30/360). |
| `ServicePipeline` | Score | Async middleware chain for service operations. |
| `ServiceError` | Score | Typed errors (notFound, validation, businessRule, etc.). |
| `CSVExportable` | Score | Protocol for CSV row export. |
| `IBANValidator` | Score | ISO 13616 IBAN validation. |
| `SCORReferenceGenerator` | Score | ISO 11649 creditor reference with Mod 97. |
| `ErrorHandler` | ScoreUI | Observable error state management for SwiftUI. |
| `PDFRenderer` | ScoreUI | UIKit-based PDF generation. |
| `.errorAlert()` | ScoreUI | SwiftUI modifier for error alert presentation. |

To add Score as a dependency, add a local package reference to `../score` in Xcode.
