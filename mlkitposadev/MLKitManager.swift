//
//  MLKitManager.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 20/11/24.
//

import Combine
import MLKitTextRecognition
import MLKitTextRecognitionCommon
import MLKitVision
import MLKitImageLabeling
import MLKitImageLabelingCommon
import UIKit

class MLKitManager: ObservableObject {
    @Published var imageLabel: String = ""
    @Published var visibleText: String = ""

    private let textRecognizer: TextRecognizer
    private let imageLabeler: ImageLabeler

    init() {
        let textRecognizerOptions = TextRecognizerOptions()
        self.textRecognizer = TextRecognizer.textRecognizer(options: textRecognizerOptions)

        let imageLabelerOptions = ImageLabelerOptions()
        self.imageLabeler = ImageLabeler.imageLabeler(options: imageLabelerOptions)
    }

    func recognizeText(from image: UIImage) {
        let visionImage = VisionImage(image: image)

        textRecognizer.process(visionImage) { [weak self] result, error in
            guard error == nil, let result = result else { return }

            DispatchQueue.main.async {
                self?.visibleText = result.text
            }
        }
    }

    func labelImage(from image: UIImage) {
        let visionImage = VisionImage(image: image)

        imageLabeler.process(visionImage) { [weak self] labels, error in
            guard error == nil, let labels = labels else { return }

            let labelDescriptions = labels.map { $0.text }.joined(separator: ", ")

            DispatchQueue.main.async {
                self?.imageLabel = labelDescriptions
            }
        }
    }
}
