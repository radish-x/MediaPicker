//
//  OrientationTransformationExtensions.swift
//
//
//  Created by Alexandra Afonasova on 18.10.2022.
//

import AVFoundation

#if canImport(UIKit)
import UIKit

extension UIImage.Orientation {
    init(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .landscapeLeft: self = .up
        case .landscapeRight: self = .down
        case .portraitUpsideDown: self = .left
        default: self = .right
        }
    }

    static var `default`: UIImage.Orientation { .right }
}

extension AVCaptureVideoOrientation {
    init(_ orientation: UIDeviceOrientation) {
        switch orientation {
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: self = .portrait
        }
    }
}

#elseif canImport(AppKit)
import AppKit

#endif
