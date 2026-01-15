//
//  Song.swift
//  AplicacionMusicaiOS
//

import Foundation
import SwiftUI

struct Song: Identifiable, Equatable {
    let id: String
    let title: String
    let audioPath: String
    let coverPath: String?
    let artist: String
    let album: String
    let year: Int
    let genre: String
    let source: String
    var liked: Bool
    let createdAt: Date?

    // Cover image loaded asynchronously
    var coverImage: UIImage?

    init(
        id: String = UUID().uuidString,
        title: String,
        audioPath: String,
        coverPath: String? = nil,
        artist: String = "",
        album: String = "",
        year: Int = 0,
        genre: String = "",
        source: String = "",
        liked: Bool = false,
        createdAt: Date? = nil,
        coverImage: UIImage? = nil
    ) {
        self.id = id
        self.title = title
        self.audioPath = audioPath
        self.coverPath = coverPath
        self.artist = artist
        self.album = album
        self.year = year
        self.genre = genre
        self.source = source
        self.liked = liked
        self.createdAt = createdAt
        self.coverImage = coverImage
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}
