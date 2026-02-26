//
//  FindingsReportRowView.swift
//  Lektüren
//
//  Zeilenansicht für einen Erkenntnisbericht in der Liste.
//

import SwiftUI

struct FindingsReportRowView: View {
    let report: FindingsReport

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.topic)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if report.pdfData != nil {
                Image(systemName: "doc.richtext")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
