//
//  FilterMode.swift
//  AplicacionMusicaiOS
//

import Foundation

// MARK: - Screen Mode
enum ScreenMode: String, CaseIterable {
    case random = "RANDOM"
    case pickFilter = "PICK_FILTER"
    case filterResults = "FILTER_RESULTS"
    case playlists = "PLAYLISTS"
}

// MARK: - Filter Mode
enum FilterMode: String, CaseIterable {
    case none = "NONE"
    case artist = "ARTIST"
    case album = "ALBUM"
    case year = "YEAR"
    case genre = "GENRE"
    case source = "SOURCE"
    case liked = "LIKED"
    case new = "NEW"

    var displayName: String {
        switch self {
        case .none: return "Todos"
        case .artist: return "Artista"
        case .album: return "Album"
        case .year: return "Ano"
        case .genre: return "Genero"
        case .source: return "Source"
        case .liked: return "Liked"
        case .new: return "Nuevas"
        }
    }

    var icon: String {
        switch self {
        case .none: return "music.note.list"
        case .artist: return "person.fill"
        case .album: return "square.stack.fill"
        case .year: return "calendar"
        case .genre: return "music.mic"
        case .source: return "folder.fill"
        case .liked: return "heart.fill"
        case .new: return "sparkles"
        }
    }
}

// MARK: - View Mode
enum ViewMode: String, CaseIterable {
    case grid2 = "GRID_2"
    case grid4 = "GRID_4"
    case grid6 = "GRID_6"
    case list = "LIST"

    var columns: Int {
        switch self {
        case .grid2: return 2
        case .grid4: return 4
        case .grid6: return 6
        case .list: return 1
        }
    }

    var displayName: String {
        switch self {
        case .grid2: return "Grid 2"
        case .grid4: return "Grid 4"
        case .grid6: return "Grid 6"
        case .list: return "Lista"
        }
    }

    var icon: String {
        switch self {
        case .grid2: return "square.grid.2x2"
        case .grid4: return "square.grid.3x3"
        case .grid6: return "square.grid.4x3.fill"
        case .list: return "list.bullet"
        }
    }
}

// MARK: - Repeat Mode
enum RepeatMode: String, CaseIterable {
    case none = "NONE"
    case one = "ONE"
    case all = "ALL"

    var icon: String {
        switch self {
        case .none: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    func next() -> RepeatMode {
        switch self {
        case .none: return .one
        case .one: return .all
        case .all: return .none
        }
    }
}

// MARK: - Navigation State
struct NavigationState {
    let screenMode: ScreenMode
    let filterMode: FilterMode
    let filterValue: String?
    let browseItems: [CountItem]
    let browseSongs: [Song]
    let scrollPosition: String?
}

// MARK: - App Constants
struct AppConstants {
    static let primaryBlue = 0x1E88E5
    static let noTitle = "Sin titulo"
    static let unknownArtist = "Artista desconocido"
    static let defaultPageSize = 50
    static let searchDelayMs = 500
    static let coverSizeSmall: CGFloat = 56
    static let coverSizeMedium: CGFloat = 75
    static let coverSizeLarge: CGFloat = 320
}
