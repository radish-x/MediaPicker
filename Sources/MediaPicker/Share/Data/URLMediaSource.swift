//
//  URLMediaSource.swift
//  MediaPicker
//
//  Created by luolingfeng on 1/6/25.
//

import AVFoundation
import Foundation

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif

public struct URLMediaSource: MediaSource {
    let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public var mediaType: MediaType? {
        if url.isVideoFile {
            return .video
        } else if url.isImageFile {
            return .image
        } else {
            return .file
        }
    }
    
    public func duration() async throws -> CGFloat? {
        guard url.isVideoFile else { return nil }
        return CMTimeGetSeconds(AVURLAsset(url: url).duration)
    }
    
    public func getURL() async throws -> URL? {
        return url
    }
    
    public func getThumbnailURL() async throws -> URL? {
        guard url.isVideoFile else { return url }
        
        return try await url.getThumbnailURL()
    }
    
    public func getData() async throws -> Data? {
        return try? Data(contentsOf: url)
    }
    
    public func getThumbnailData() async throws -> Data? {
        guard url.isVideoFile else { return try? Data(contentsOf: url) }
        return await url.getThumbnailData()
    }
    
    public func getSize() async throws -> CGSize? {
        if url.isVideoFile {
            return try await url.getVideoSizeAsync()
        } else if url.isImageFile {
            guard let data = try await getData() else { return nil }
#if canImport(UIKit)
            let image = UIImage(data: data)
            return image?.size
#elseif canImport(AppKit)
            let image = NSImage(data: data)
            return image?.size
#endif
        } else {
            return nil
        }
    }
    
    public func getBytes() async throws -> Int {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return resourceValues.fileSize ?? 0 // File size in bytes
    }
}
