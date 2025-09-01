//
//  PDFViewerView.swift
//  MEROT HRS
//
//  Created by Claude on 9/1/25.
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let pdfData: Data
    let title: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            PDFKitView(data: pdfData)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: pdfData, preview: SharePreview(title, image: Image(systemName: "doc.text.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Updates handled automatically
    }
}

#Preview {
    PDFViewerView(pdfData: Data(), title: "Sample PDF")
}