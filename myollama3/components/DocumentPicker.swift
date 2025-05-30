//
//  DocumentPicker.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PDFKit

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedPDFText: String?
    @Binding var selectedTXTText: String?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.pdf,
            UTType.text,
            UTType.plainText,
            UTType.rtf,
            UTType.image,
            UTType.jpeg,
            UTType.png
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        private func resizeImage(_ image: UIImage, targetWidth: CGFloat = 800) -> UIImage {
            let size = image.size
            
            if size.width <= targetWidth {
                return image
            }
            
            let widthRatio = targetWidth / size.width
            let newHeight = size.height * widthRatio
            let newSize = CGSize(width: targetWidth, height: newHeight)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            
            return resizedImage
        }
        
        private func extractTextFromPDF(url: URL) -> String? {
            guard let pdfDocument = PDFDocument(url: url) else {
                print("Failed to create PDF document from URL")
                return nil
            }
            
            var extractedText = ""
            let pageCount = pdfDocument.pageCount
            
            for pageIndex in 0..<pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                if let pageText = page.string {
                    extractedText += pageText + "\n"
                }
            }
            
            return extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : extractedText
        }
        
        private func extractTextFromFile(url: URL) -> String? {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : content
            } catch {
                print("Failed to read text file: \(error.localizedDescription)")
                do {
                    let content = try String(contentsOf: url, encoding: .utf16)
                    return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : content
                } catch {
                    print("Failed to read text file with UTF-16: \(error.localizedDescription)")
                    return nil
                }
            }
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            print("file name: \(url.lastPathComponent)")
            print("file type: \(url.pathExtension)")
            
            let fileExtension = url.pathExtension.lowercased()
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
                        
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource")
                parent.dismiss()
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            if imageExtensions.contains(fileExtension) {
                
                if let imageData = try? Data(contentsOf: url),
                   let image = UIImage(data: imageData) {
                    let resizedImage = resizeImage(image)
                    DispatchQueue.main.async {
                        self.parent.selectedImage = resizedImage
                    }
                } else {
                    print("Failed to load image data or create UIImage")
                }
            } else if fileExtension == "pdf" {
                
                if let extractedText = extractTextFromPDF(url: url) {
                    DispatchQueue.main.async {
                        self.parent.selectedPDFText = extractedText
                    }
                } else {
                    print("Failed to extract text from PDF")
                }
            } else if fileExtension == "txt" {
                
                if let extractedText = extractTextFromFile(url: url) {
                    DispatchQueue.main.async {
                        self.parent.selectedTXTText = extractedText
                    }
                } else {
                    print("Failed to read text from TXT file")
                }
            } else {
                print("Not a supported file type")
            }
            
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
