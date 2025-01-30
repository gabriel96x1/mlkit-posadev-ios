//
//  CameraState.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 07/12/24.
//

import Foundation
import UIKit

@Observable class CameraState : NSObject {
    public var capturedImage : UIImage?
    public var capturedImageError : Error?
}
