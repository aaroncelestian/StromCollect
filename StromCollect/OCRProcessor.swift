import SwiftUI
import SwiftData
import Vision

// MARK: - OCR Processor
class OCRProcessor: ObservableObject {
    @Published var ocrResult: OCRResult?
    @Published var isProcessing = false
    
    func processSpecimenLabel(_ image: UIImage) {
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    print("OCR Error: \(error)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                let confidence = observations.first?.topCandidates(1).first?.confidence ?? 0.0
                
                self?.ocrResult = OCRResult(
                    text: recognizedText,
                    confidence: confidence,
                    needsVerification: confidence < 0.8
                )
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
