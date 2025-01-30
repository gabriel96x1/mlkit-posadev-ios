//
//  ContentView.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 20/11/24.
//

import SwiftUI
import SwiftData
import Vision

struct ContentView: View {
        
    @ObservedObject private var mlKitManager = MLKitManager()
    @ObservedObject private var visionKit = VisionKit()

    var body: some View {
        VStack {
            Text("ML Kit Text: \n \(mlKitManager.visibleText)")
            Text("Vision Kit Text: \(visionKit.visibleText)")
            //Text(mlKitManager.imageLabel)
            CameraView(onFrameCaptured: { image in
                mlKitManager.recognizeText(from: image)
                visionKit.recognizeText(in: image)
                //mlKitManager.labelImage(from: image)
            })
        }
    }
}
