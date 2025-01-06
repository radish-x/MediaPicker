//
//  SwiftUIView.swift
//
//
//  Created by luolingfeng on 12/29/24.
//

import SwiftUI

@MainActor
public protocol MediaSource {
    var mediaType: MediaType? { get }

    func duration() async throws -> CGFloat?
    func getURL() async throws -> URL?
    func getThumbnailURL() async throws -> URL?

    func getData() async throws -> Data?
    func getThumbnailData() async throws -> Data?

    func getSize() async throws -> CGSize?

    func getBytes() async throws -> Int
}
