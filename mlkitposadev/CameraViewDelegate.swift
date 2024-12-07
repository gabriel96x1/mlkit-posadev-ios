//
//  CameraViewDelegate.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 07/12/24.
//

public protocol CameraViewDelegate {
    func cameraAccessGranted()
    func cameraAccessDenied()
    func noCameraDetected()
    func cameraSessionStarted()
}
