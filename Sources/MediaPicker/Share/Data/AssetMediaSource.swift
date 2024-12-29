//
//  Created by Alex.M on 27.05.2022.
//

import Foundation
import Photos

struct AssetMediaSource {
    let asset: PHAsset
}

extension AssetMediaSource: MediaSource {
    var mediaType: MediaType? {
        switch asset.mediaType {
        case .image:
            return .image
        case .video:
            return .video
        default:
            return .file
        }
    }

    func duration() async throws -> CGFloat? {
        return CGFloat(asset.duration)
    }

    func getURL() async -> URL? {
        await asset.getURL()
    }

    func getThumbnailURL() async -> URL? {
        await asset.getThumbnailURL()
    }

    func getData() async throws -> Data? {
        try await asset.getData()
    }

    func getThumbnailData() async -> Data? {
        await asset.getThumbnailData()
    }
}

extension AssetMediaSource: Identifiable {
    var id: String {
        asset.localIdentifier
    }
}

extension AssetMediaSource: Equatable {
    static func ==(lhs: AssetMediaSource, rhs: AssetMediaSource) -> Bool {
        lhs.id == rhs.id
    }
}
