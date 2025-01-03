//
//  Created by luolingfeng on 12/29/24.
//

import Combine
import CoreTransferable
import Foundation
import SwiftUICore

#if canImport(UIKit)
    import UIKit

#elseif canImport(AppKit)
    import AppKit

#endif

public enum MediaType: Sendable {
    case image
    case video
    case file
}

@MainActor
public struct Media: Identifiable, Equatable, Sendable {
    public let id = UUID()
    let source: MediaSource

    public nonisolated static func == (lhs: Media, rhs: Media) -> Bool {
        lhs.id == rhs.id
    }
}

public extension Media {
    var type: MediaType {
        source.mediaType ?? .file
    }

    func getSize() async throws -> CGSize? {
        return try await source.getSize()
    }

    func getBytes() async throws -> Int {
        return try await source.getBytes()
    }

    func duration() async throws -> CGFloat? {
        return try await source.duration()
    }

    func getURL() async throws -> URL? {
        return try await source.getURL()
    }

    func getThumbnailURL() async throws -> URL? {
        return try await source.getThumbnailURL()
    }

    func getData() async throws -> Data? {
        return try await source.getData()
    }

    func getThumbnailData() async throws -> Data? {
        return try await source.getThumbnailData()
    }
}

enum TransferError: Error {
    case importFailed
    case unsupportedPlatform
}

@available(iOS 16.0, macOS 13.0, *)
struct Movie: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { receivedData in
            let fileName = receivedData.file.lastPathComponent
            let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: receivedData.file, to: copy)
            return .init(url: copy)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct Photo: Transferable, Sendable {
    let image: Image

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            #if canImport(AppKit)
                guard let nsImage = NSImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(nsImage: nsImage)
                return Photo(image: image)
            #elseif canImport(UIKit)
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(uiImage: uiImage)
                return Photo(image: image)
            #else
                throw TransferError.importFailed
            #endif
        }
    }
}
