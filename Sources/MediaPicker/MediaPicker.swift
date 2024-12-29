// The Swift Programming Language
// https://docs.swift.org/swift-book

import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif

struct MediaPicker: UIViewControllerRepresentable {
    @Binding var selectedMedias: [Media]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // 0 for unlimited selection
        configuration.filter = .any(of: [.images, .videos]) // Allows picking images and videos

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPicker

        init(_ parent: MediaPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            parent.selectedMedias = results.map { phpickerResult in
                Media(source: PHPickerResultMediaSource(phpPickerResult: phpickerResult))
            }
        }
    }
}
