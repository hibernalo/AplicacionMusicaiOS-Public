//
//  CountItem.swift
//  AplicacionMusicaiOS
//

import Foundation
import SwiftUI

struct CountItem: Identifiable, Equatable {
    let id: String
    let key: String
    let count: Int
    let coverPath: String?

    var coverImage: UIImage?

    var label: String {
        "\(key) (\(count))"
    }

    init(
        id: String = UUID().uuidString,
        key: String,
        count: Int,
        coverPath: String? = nil,
        coverImage: UIImage? = nil
    ) {
        self.id = id
        self.key = key
        self.count = count
        self.coverPath = coverPath
        self.coverImage = coverImage
    }

    static func == (lhs: CountItem, rhs: CountItem) -> Bool {
        lhs.id == rhs.id && lhs.key == rhs.key
    }
}
