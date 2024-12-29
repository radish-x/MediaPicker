//
//  SwiftUIView.swift
//
//
//  Created by Alisa Mylnikova on 12.07.2022.
//

import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct URLMediaSource {
    let url: URL
}

extension URLMediaSource: MediaSource {
    var mediaType: MediaType? {
        if url.isImageFile {
            return .image
        }
        if url.isVideoFile {
            return .video
        }
        return nil
    }

    func duration() async -> CGFloat? {
        return CMTimeGetSeconds(AVURLAsset(url: url).duration)
    }

    func getURL() async -> URL? {
        url
    }

    func getThumbnailURL() async -> URL? {
        switch mediaType {
        case .image:
            return url
        case .video:
            return await url.getThumbnailURL()
        case .file:
            return url
        case .none:
            return nil
        }
    }

    func getData() async throws -> Data? {
        try? Data(contentsOf: url)
    }

    func getThumbnailData() async -> Data? {
        switch mediaType {
        case .image:
            return try? Data(contentsOf: url)
        case .file:
            return nil
        case .video:
            return await url.getThumbnailData()
        case .none:
            return nil
        }
    }
}

extension URLMediaSource: Identifiable {
    var id: String {
        url.absoluteString
    }
}

extension URLMediaSource: Equatable {
    static func ==(lhs: URLMediaSource, rhs: URLMediaSource) -> Bool {
        lhs.id == rhs.id
    }
}
