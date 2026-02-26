//
//  PDFDetailView.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import PDFKit

struct PDFDetailView: View {
    let item: PDFItem

    @State private var isInspectorPresented: Bool = true
    @State private var cloudError: String? = nil
    @State private var isVisible: Bool = true

    var body: some View {
        PDFKitView(url: item.pdfUrl)
            .opacity(isVisible ? 1 : 0)
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: item.id) { _, _ in
                isVisible = false
                withAnimation(.easeIn(duration: 0.15)) {
                    isVisible = true
                }
            }
            .navigationTitle(item.title ?? item.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            isInspectorPresented.toggle()
                        }
                    } label: {
                        Label(
                            isInspectorPresented ? "Informationen ausblenden" : "Informationen anzeigen",
                            systemImage: "sidebar.right"
                        )
                    }
                }
            }
            .inspector(isPresented: $isInspectorPresented) {
                PDFInspectorView(item: item)
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 400)
            }
            .alert("iCloud-Fehler", isPresented: Binding(
                get: { cloudError != nil },
                set: { if !$0 { cloudError = nil } }
            )) {
                Button("OK", role: .cancel) { cloudError = nil }
            } message: {
                Text(cloudError ?? "")
            }
            .task(id: item.id) {
                // Sicherstellen, dass die iCloud-Datei lokal heruntergeladen ist.
                guard let url = item.pdfUrl, PDFCloudStorage.isCloudURL(url) else { return }
                do {
                    try PDFCloudStorage.ensureDownloaded(at: url)
                } catch {
                    cloudError = error.localizedDescription
                }
            }
    }
}

// MARK: - PDFKit View (UIViewRepresentable / NSViewRepresentable)

private struct PDFKitView: View {
    let url: URL?

    var body: some View {
        if let url {
            iOSPDFView(url: url)
        } else {
            ContentUnavailableView(
                "Keine Datei",
                systemImage: "doc.richtext",
                description: Text("Der Pfad zur PDF-Datei ist nicht verfügbar.")
            )
        }
    }
}

private struct iOSPDFView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.usePageViewController(true)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        guard uiView.document?.documentURL != url else { return }
        let targetURL = url
        context.coordinator.currentURL = targetURL
        uiView.document = nil
        Task.detached {
            let doc = PDFDocument(url: targetURL)
            await MainActor.run {
                guard context.coordinator.currentURL == targetURL else { return }
                uiView.document = doc
            }
        }
    }

    class Coordinator {
        var currentURL: URL?
    }
}

// MARK: - Inspector Panel

private struct PDFInspectorView: View {
    let item: PDFItem

    var body: some View {
        List {
            // MARK: Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        PDFThumbnailView(data: item.thumbnailData)
                            .frame(width: 72, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        Text(item.title ?? item.fileName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 6)
            }
            
            // MARK: AI-Extraktion
            if hasAIData {
                Section("AI-Analyse") {
                    if let aiTitle = item.aiExtractedTitle {
                        LabeledContent("Titel (AI)", value: aiTitle)
                    }
                    if let aiAuthor = item.aiExtractedAuthor {
                        LabeledContent("Autor (AI)", value: aiAuthor)
                    }
                    if let aiDate = item.aiExtractedDate {
                        LabeledContent("Erstellt (AI)") {
                            Text(aiDate.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    if let summary = item.aiSummary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Zusammenfassung")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(summary)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                    if !item.aiKeywords.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Keywords (AI)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            FlowLayout(spacing: 6) {
                                ForEach(item.aiKeywords, id: \.self) { keyword in
                                    Text(keyword)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // MARK: Propositionen
            if let propositions = item.propositions, !propositions.isEmpty {
                Section("Propositionen (\(propositions.count))") {
                    ForEach(propositions.sorted(by: { $0.subject < $1.subject })) { prop in
                        VStack(alignment: .leading, spacing: 6) {
                            // Kategorie-Tag
                            HStack(spacing: 4) {
                                Image(systemName: prop.subjectIcon)
                                    .font(.caption2)
                                Text(prop.subject)
                                    .font(.caption)
                            }
                            .foregroundStyle(prop.subjectColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(prop.subjectColor.opacity(0.12), in: Capsule())

                            // Kernaussage
                            Text(prop.keyMessage)
                                .font(.subheadline)

                            // Quelle und Datum
                            HStack(spacing: 6) {
                                if !prop.source.isEmpty {
                                    Text(prop.source)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if let date = prop.dateOfProposition {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // MARK: Allgemein
            Section("Allgemein") {
                if let author = item.author, !author.isEmpty {
                    LabeledContent("Autor", value: author)
                }
                if let subject = item.subject, !subject.isEmpty {
                    LabeledContent("Thema", value: subject)
                }
                if !item.keywords.isEmpty {
                    LabeledContent("Stichwörter", value: item.keywords.joined(separator: ", "))
                }
                if !item.fileName.isEmpty {
                    LabeledContent("Dateiname", value: item.fileName)
                }
                LabeledContent("Seitenanzahl", value: item.pageCount, format: .number)
                LabeledContent("Größe", value: item.fileSize)
                if item.isEncrypted {
                    LabeledContent("Verschlüsselt", value: "Ja")
                }
            }

            // MARK: Seitenformat
            if let width = item.pageWidth, let height = item.pageHeight {
                Section("Seitenformat") {
                    LabeledContent("Breite", value: width, format: .number.precision(.fractionLength(1)))
                    LabeledContent("Höhe", value: height, format: .number.precision(.fractionLength(1)))
                    if let rotation = item.pageRotation, rotation != 0 {
                        LabeledContent("Rotation", value: "\(rotation)°")
                    }
                }
            }

            // MARK: Datum
            Section("Datum") {
                if let creationDate = item.pdfCreationDate {
                    LabeledContent("Erstellt (PDF)") {
                        Text(creationDate.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                if let modDate = item.pdfModificationDate {
                    LabeledContent("Geändert (PDF)") {
                        Text(modDate.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                LabeledContent("Geändert (Datei)") {
                    Text(item.lastModified.formatted(date: .abbreviated, time: .shortened))
                }
            }

            // MARK: Werkzeuge
            Section("Werkzeuge") {
                if let creator = item.creator, !creator.isEmpty {
                    LabeledContent("Erstellt mit", value: creator)
                }
                if let producer = item.producer, !producer.isEmpty {
                    LabeledContent("PDF-Bibliothek", value: producer)
                }
            }

            // MARK: Speicherort
            Section("Speicherort") {
                if let folder = item.folder {
                    LabeledContent("Ordner", value: folder.name ?? "–")
                }
                if let url = item.pdfUrl {
                    LabeledContent("Pfad", value: url.path(percentEncoded: false))
                        .truncationMode(.middle)
                }
            }

            // MARK: Technisch
            Section("Technisch") {
                LabeledContent("ID", value: item.id.uuidString)
                    .font(.caption)
                if !item.contentHash.isEmpty {
                    LabeledContent("Hash", value: item.contentHash)
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Informationen")
    }
    
    private var hasAIData: Bool {
        item.aiExtractedTitle != nil ||
        item.aiExtractedAuthor != nil ||
        item.aiExtractedDate != nil ||
        item.aiSummary != nil ||
        !item.aiKeywords.isEmpty
    }
}
// MARK: - FlowLayout

/// Einfaches Flow-Layout für Keywords (wrapped horizontal)
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, 
                                     y: bounds.minY + result.frames[index].minY), 
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

