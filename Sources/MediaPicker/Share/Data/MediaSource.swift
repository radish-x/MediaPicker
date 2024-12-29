//
//  SwiftUIView.swift
//
//
//  Created by Alisa Mylnikova on 21.04.2023.
//

import SwiftUI

protocol MediaSource {
    var mediaType: MediaType? { get }

    func duration() async throws -> CGFloat?
    func getURL() async throws -> URL?
    func getThumbnailURL() async throws -> URL?

    func getData() async throws -> Data?
    func getThumbnailData() async throws -> Data?
}
