//
//  Playlist.swift
//  AplicacionMusicaiOS
//

import Foundation
import SwiftUI

struct Playlist: Identifiable, Equatable {
    let id: String
    let name: String
    let coverPath: String?
    let songCount: Int

    var coverImage: UIImage?

    init(
        id: String,
        name: String,
        coverPath: String? = nil,
        songCount: Int = 0,
        coverImage: UIImage? = nil
    ) {
        self.id = id
        self.name = name
        self.coverPath = coverPath
        self.songCount = songCount
        self.coverImage = coverImage
    }

    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}
