//
//  VisionKit.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 29/01/25.
//

import Combine
import UIKit
import Vision

class VisionKit: ObservableObject {
    @Published var visibleText: String = "Placeholder 2 VK"

    func recognizeText(in image: UIImage) {
         let request = VNRecognizeTextRequest { (request, error) in
             guard let results = request.results as? [VNRecognizedTextObservation],
                   
                   let _ = results.first?.topCandidates(1).first?.string else { return }
             
             DispatchQueue.main.async {
                 var completeText: String = ""
                 results.forEach({ element in
                     completeText += "\n"
                     completeText += element.topCandidates(1).first?.string ?? ""
                 })
                 self.visibleText = completeText
             }
             
             // Optionally, stop scanning after first detection
             // self.parent.captureSession.stopRunning()
         }
         
        request.recognitionLevel = .accurate
         
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .background).async {
            do {
                try handler.perform([request])
            } catch {
                print("Text recognition failed: \(error)")
            }
        }
     }
}

