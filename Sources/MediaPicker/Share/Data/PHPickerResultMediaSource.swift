//
//  DataMediaSource.swift
//  MediaPicker
//
//  Created by luolingfeng on 12/29/24.
//

import PhotosUI

#if canImport(UIKit)
    import UIKit

#elseif canImport(AppKit)
    import AppKit

#endif

@MainActor
class PHPickerResultMediaSource {
    let phpPickerResult: PHPickerResult

    var delegate: MediaSource? {
        if phpPickerResult.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return PhotoPickerSource(phpPickerResult: phpPickerResult)
        } else if phpPickerResult.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return MoviePickerSource(phpPickerResult: phpPickerResult)
        } else {
            return nil
        }
    }

    init(phpPickerResult: PHPickerResult) {
        self.phpPickerResult = phpPickerResult
    }
}

extension PHPickerResultMediaSource: @preconcurrency MediaSource {
    var mediaType: MediaType? {
        return delegate?.mediaType
    }

    func duration() async throws -> CGFloat? {
        return try await delegate?.duration()
    }

    func getURL() async throws -> URL? {
        return try await delegate?.getURL()
    }

    func getThumbnailURL() async throws -> URL? {
        return try await delegate?.getThumbnailURL()
    }

    func getData() async throws -> Data? {
        return try await delegate?.getData()
    }

    func getThumbnailData() async throws -> Data? {
        return try await delegate?.getThumbnailData()
    }
}

@MainActor
class MoviePickerSource {
    let phpPickerResult: PHPickerResult
    private var loadingTask: Task<URL?, Error>? // Tracks the ongoing loading task

    private var url: URL?

    init(phpPickerResult: PHPickerResult, url: URL? = nil) {
        self.phpPickerResult = phpPickerResult
        self.url = url
    }
}

extension MoviePickerSource: @preconcurrency MediaSource {
    var mediaType: MediaType? {
        if phpPickerResult.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return .image
        } else if phpPickerResult.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return .video
        } else {
            return .file
        }
    }

    func duration() async throws -> CGFloat? {
        guard let mediaType = mediaType, mediaType == .video else { return nil }

        guard let url = try await getURL() else { return nil }

        return CMTimeGetSeconds(AVURLAsset(url: url).duration)
    }

    func getURL() async throws -> URL? {
        // Return the cached URL if it's already available
        if let cachedURL = url {
            return cachedURL
        }

        // If a task is already loading the URL, wait for it
        if let loadingTask = loadingTask {
            return try await loadingTask.value
        }

        // Create a new task to load the URL
        let newTask = Task { [weak self] () -> URL? in
            return try await withCheckedThrowingContinuation { continuation in
                self?.phpPickerResult.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let url = url else {
                        continuation.resume(throwing: TransferError.importFailed)
                        return
                    }

                    // Cache the URL
                    Task { @MainActor in
                        self?.url = url
                        self?.loadingTask = nil
                    }
                    continuation.resume(returning: url)
                }
            }
        }

        // Assign the task to the loadingTask property and await its result
        loadingTask = newTask
        return try await newTask.value
    }

    func getThumbnailURL() async throws -> URL? {
        switch mediaType {
        case .image:
            return url
        case .video:
            guard let url = try await getURL() else {
                return nil
            }
            return await url.getThumbnailURL()
        case .file:
            return url
        case .none:
            return nil
        }
    }

    func getData() async throws -> Data? {
        guard let url = try await getURL() else {
            return nil
        }
        return try Data(contentsOf: url)
    }

    func getThumbnailData() async throws -> Data? {
        guard let url = try await getURL() else {
            return nil
        }

        switch mediaType {
        case .image:
            return try Data(contentsOf: url)
        case .file:
            return nil
        case .video:
            return await url.getThumbnailData()
        case .none:
            return nil
        }
    }
}

@MainActor
class PhotoPickerSource {
    let phpPickerResult: PHPickerResult
    private var loadingTask: Task<Data?, Error>? // Tracks the ongoing loading task

    private var loadingUrlTask: Task<URL?, Error>?

    private var url: URL?
    private var data: Data?

    init(phpPickerResult: PHPickerResult, url: URL? = nil) {
        self.phpPickerResult = phpPickerResult
        self.url = url
    }
}

extension PhotoPickerSource: @preconcurrency MediaSource {
    var mediaType: MediaType? {
        if phpPickerResult.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return .image
        } else if phpPickerResult.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return .video
        } else {
            return .file
        }
    }

    func duration() async throws -> CGFloat? {
        guard let mediaType = mediaType, mediaType == .video else { return nil }

        guard let url = try await getURL() else { return nil }

        return CMTimeGetSeconds(AVURLAsset(url: url).duration)
    }

    func getURL() async throws -> URL? {
        // Return the cached URL if it's already available
        if let cachedURL = url {
            return cachedURL
        }

        // If a URL is being loaded, await the result
        if let loadingUrlTask = loadingUrlTask {
            return try await loadingUrlTask.value
        }

        // Start a new task to load the URL
        let newTask = Task<URL?, Error> { [weak self] in
            guard let self = self else { return nil }

            // Get the image data
            guard let data = try await self.getData() else {
                throw TransferError.importFailed // Make sure data exists
            }

            // Create a temporary file URL to store the JPG file
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

            do {
                // Handle image conversion and saving
                #if canImport(UIKit)
                    // For iOS: UIImage handling
                    guard let uiImage = UIImage(data: data) else {
                        throw TransferError.importFailed
                    }
                    guard let jpegData = uiImage.jpegData(compressionQuality: 1.0) else {
                        throw TransferError.importFailed
                    }
                    try jpegData.write(to: fileURL)
                #elseif canImport(AppKit)
                    // For macOS: NSImage handling
                    guard let nsImage = NSImage(data: data) else {
                        throw TransferError.importFailed
                    }

                    // Directly convert NSImage to JPEG data
                    guard let jpegData = nsImage.jpegData() else {
                        throw TransferError.importFailed
                    }
                    try jpegData.write(to: fileURL)
                #endif
            } catch {
                // If anything fails during the image processing, throw an error
                throw TransferError.importFailed
            }

            // Cache the URL and return it
            self.url = fileURL
            return fileURL
        }

        // Store the task and return its value
        loadingUrlTask = newTask
        return try await newTask.value
    }

    func getThumbnailURL() async throws -> URL? {
        guard let mediaType = mediaType, mediaType == .image else {
            return nil
        }

        return try await getURL()
    }

    func getData() async throws -> Data? {
        guard let mediaType = mediaType, mediaType == .image else {
            return nil
        }

        // If a task is already loading the URL, wait for it
        if let loadingTask = loadingTask {
            return try await loadingTask.value
        }

        let newTask = Task<Data?, Error> {
            try await withCheckedThrowingContinuation { [weak self] continuation in
                self?.phpPickerResult.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let data = data else {
                        continuation.resume(throwing: TransferError.importFailed)
                        return
                    }

                    // Cache the URL
                    Task { @MainActor in
                        self?.data = data
                        self?.loadingTask = nil
                    }
                    continuation.resume(returning: data)
                }
            }
        }

        loadingTask = newTask
        return try await newTask.value
    }

    func getThumbnailData() async throws -> Data? {
        guard let mediaType = mediaType, mediaType == .image else {
            return nil
        }
        return try await getData()
    }
}