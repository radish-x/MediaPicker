//
//  DataMediaSource.swift
//  MediaPicker
//
//  Created by luolingfeng on 12/29/24.
//

import PhotosUI

@MainActor
class PHPickerResultMediaSource {
    let phpPickerResult: PHPickerResult
    private var loadingTask: Task<URL?, Error>? // Tracks the ongoing loading task

    private var url: URL?

    init(phpPickerResult: PHPickerResult, url: URL? = nil) {
        self.phpPickerResult = phpPickerResult
        self.url = url
    }
}

extension PHPickerResultMediaSource: @preconcurrency MediaSource {
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
