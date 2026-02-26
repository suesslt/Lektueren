//
//  PropositionRowView.swift
//  Lektüren
//
//  Kompakte Zeile für die Proposition-Liste mit Kategorie-Farbe und Icon.
//

import SwiftUI

struct PropositionRowView: View {
    let proposition: Proposition

    var body: some View {
        HStack(spacing: 12) {
            // Kategorie-Icon
            Image(systemName: proposition.subjectIcon)
                .font(.title3)
                .foregroundStyle(proposition.subjectColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                // Kernaussage
                Text(proposition.keyMessage)
                    .font(.body)
                    .lineLimit(3)

                // Kategorie als Tag
                Text(proposition.subject)
                    .font(.caption)
                    .foregroundStyle(proposition.subjectColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(proposition.subjectColor.opacity(0.12), in: Capsule())

                // Quelle und Datum
                HStack(spacing: 8) {
                    if !proposition.source.isEmpty {
                        Text(proposition.source)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let date = proposition.dateOfProposition {
                        if !proposition.source.isEmpty {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
