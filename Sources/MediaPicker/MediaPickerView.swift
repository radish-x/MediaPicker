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
    let pickerFilters: [MediaType]

    public init(selectedMedias: Binding<[Media]>, pickerFilters: [MediaType]) {
        self._selectedMedias = selectedMedias
        self.pickerFilters = pickerFilters
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // 0 for unlimited selection

        let pickerFilters = pickerFilters.map { mediaType in
            switch mediaType {
            case .image:
                PHPickerFilter.images
            case .video:
                PHPickerFilter.videos
            case .file:
                PHPickerFilter.images
            }
        }

        configuration.filter = .any(of: pickerFilters) // Allows picking images and videos

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
