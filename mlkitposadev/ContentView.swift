//
//  ContentView.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 20/11/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
        
    @State private var mlKitManager = MLKitManager()

    var body: some View {
        VStack {
            Text(mlKitManager.visibleText)
            Text(mlKitManager.imageLabel)
            CameraView(onFrameCaptured: { image in
                mlKitManager.recognizeText(from: image)
                mlKitManager.labelImage(from: image)
            })
        }
    }
}
