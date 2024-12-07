//
//  CameraState.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 07/12/24.
//

import Foundation
import UIKit

public class CameraState : NSObject, ObservableObject {
    @Published public var capturedImage : UIImage?
    @Published public var capturedImageError : Error?
}
