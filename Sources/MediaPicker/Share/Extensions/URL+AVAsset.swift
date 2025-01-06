//
//  SwiftUIView.swift
//
//
//  Created by Alisa Mylnikova on 21.04.2023.
//

import Photos
import SwiftUI

extension URL {
    func getThumbnailURL() async -> URL? {
        let asset = AVAsset(url: self)
        if let thumbnailData = asset.generateThumbnail() {
            return FileManager.storeToTempDir(data: thumbnailData)
        }
        return nil
    }

    func getThumbnailData() async -> Data? {
        let asset = AVAsset(url: self)
        return asset.generateThumbnail()
    }

    var isImageFile: Bool {
        UTType(filenameExtension: pathExtension)?.conforms(to: .image) ?? false
    }

    var isVideoFile: Bool {
        UTType(filenameExtension: pathExtension)?.conforms(to: .audiovisualContent) ?? false
    }

    func getVideoSize(completion: @escaping (CGSize?) -> Void) {
        // 创建 AVURLAsset
        let asset = AVURLAsset(url: self)

        // 异步加载视频轨道
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)

            DispatchQueue.main.async {
                if status == .loaded {
                    // 获取视频轨道
                    if let track = asset.tracks(withMediaType: .video).first {
                        // 获取视频尺寸
                        let size = track.naturalSize
                        completion(size)
                    } else {
                        print("No video track found")
                        completion(nil)
                    }
                } else {
                    print("Failed to load tracks: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        }
    }

    func getVideoSizeAsync() async -> CGSize? {
        let size = await withCheckedContinuation { continuation in
            self.getVideoSize(completion: { size in
                continuation.resume(returning: size)
            })
        }
        return size
    }
}
