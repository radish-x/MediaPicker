// The Swift Programming Language
// https://docs.swift.org/swift-book

import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif

public struct MediaPickerView: UIViewControllerRepresentable {
    @Binding var selectedMedias: [Media]

    public init(selectedMedias: Binding<[Media]>) {
        self._selectedMedias = selectedMedias
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // 0 for unlimited selection
        configuration.filter = .any(of: [.images, .videos]) // Allows picking images and videos

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPickerView

        init(_ parent: MediaPickerView) {
            self.parent = parent
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            parent.selectedMedias = results.map { phpickerResult in
                Media(source: PHPickerResultMediaSource(phpPickerResult: phpickerResult))
            }
        }
    }
}
