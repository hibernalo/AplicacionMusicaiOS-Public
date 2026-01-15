//
//  OnlineRepository.swift
//  AplicacionMusicaiOS
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

@MainActor
class OnlineRepository {
    static let shared = OnlineRepository()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Helper: Document to Song
    private func docToSong(_ doc: DocumentSnapshot) -> Song? {
        guard let data = doc.data(),
              let title = data["title"] as? String,
              let audioPath = data["audioPath"] as? String else {
            return nil
        }

        let coverPath = data["coverPath"] as? String
        let artist = data["artist"] as? String ?? ""
        let album = data["album"] as? String ?? ""
        let year = (data["year"] as? Int) ?? 0
        let genre = data["genre"] as? String ?? ""
        let source = data["source"] as? String ?? ""
        let liked = data["liked"] as? Bool ?? false
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

        return Song(
            id: doc.documentID,
            title: title,
            audioPath: audioPath,
            coverPath: coverPath,
            artist: artist,
            album: album,
            year: year,
            genre: genre,
            source: source,
            liked: liked,
            createdAt: createdAt
        )
    }

    // MARK: - Fetch Random Songs (using rand field)
    func fetchRandomSongs(limit: Int = 50) async throws -> [Song] {
        let randomValue = Double.random(in: 0...1)

        // First query: rand >= randomValue
        let queryGreater = db.collection("songs")
            .whereField("rand", isGreaterThanOrEqualTo: randomValue)
            .order(by: "rand")
            .limit(to: limit)

        var snapshot = try await queryGreater.getDocuments()
        var songs = snapshot.documents.compactMap { docToSong($0) }

        // If we don't have enough songs, query rand < randomValue
        if songs.count < limit {
            let remaining = limit - songs.count
            let queryLess = db.collection("songs")
                .whereField("rand", isLessThan: randomValue)
                .order(by: "rand", descending: true)
                .limit(to: remaining)

            let snapshotLess = try await queryLess.getDocuments()
            let moreSongs = snapshotLess.documents.compactMap { docToSong($0) }
            songs.append(contentsOf: moreSongs)
        }

        // Shuffle the results for extra randomness
        return songs.shuffled()
    }

    // MARK: - Fetch All Songs (sequential, for pagination)
    func fetchAllSongs(limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .order(by: "rand")
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Artists with Counts
    func fetchArtistsWithCounts(minCount: Int = 2) async throws -> [CountItem] {
        let artistsSnap = try await db.collection("artistas").getDocuments()
        let songsSnap = try await db.collection("songs").getDocuments()

        // Count songs per artist
        var artistCounts: [String: Int] = [:]
        for doc in songsSnap.documents {
            if let artist = doc.data()["artist"] as? String, !artist.isEmpty {
                artistCounts[artist, default: 0] += 1
            }
        }

        var items: [CountItem] = []
        for doc in artistsSnap.documents {
            let name = (doc.data()["name"] as? String) ?? doc.documentID
            let coverPath = doc.data()["coverPath"] as? String
            let count = artistCounts[name] ?? 0

            if count >= minCount {
                items.append(CountItem(
                    id: doc.documentID,
                    key: name,
                    count: count,
                    coverPath: coverPath
                ))
            }
        }

        return items.sorted { ($0.count, $1.key.lowercased()) > ($1.count, $0.key.lowercased()) }
    }

    // MARK: - Fetch Albums with Counts
    func fetchAlbumsWithCounts(minCount: Int = 2) async throws -> [CountItem] {
        let songsSnap = try await db.collection("songs").getDocuments()

        var albumsMap: [String: (count: Int, coverPath: String?)] = [:]

        for doc in songsSnap.documents {
            guard let album = doc.data()["album"] as? String, !album.isEmpty else { continue }
            let coverPath = doc.data()["coverPath"] as? String

            if let existing = albumsMap[album] {
                albumsMap[album] = (existing.count + 1, existing.coverPath ?? coverPath)
            } else {
                albumsMap[album] = (1, coverPath)
            }
        }

        var items: [CountItem] = []
        for (album, data) in albumsMap where data.count >= minCount {
            items.append(CountItem(
                key: album,
                count: data.count,
                coverPath: data.coverPath
            ))
        }

        return items.sorted { $0.count > $1.count }
    }

    // MARK: - Fetch Years with Counts
    func fetchYearsWithCounts() async throws -> [CountItem] {
        let songsSnap = try await db.collection("songs").getDocuments()

        var yearCounts: [Int: Int] = [:]
        for doc in songsSnap.documents {
            if let year = doc.data()["year"] as? Int, year > 0 {
                yearCounts[year, default: 0] += 1
            }
        }

        return yearCounts.map { CountItem(key: String($0.key), count: $0.value) }
            .sorted { (Int($0.key) ?? 0) > (Int($1.key) ?? 0) }
    }

    // MARK: - Fetch Genres with Counts
    func fetchGenresList() async throws -> [CountItem] {
        let genresSnap = try await db.collection("genres").getDocuments()
        let songsSnap = try await db.collection("songs").getDocuments()

        var genreCounts: [String: Int] = [:]
        for doc in songsSnap.documents {
            if let genre = doc.data()["genre"] as? String, !genre.isEmpty {
                genreCounts[genre, default: 0] += 1
            }
        }

        var items: [CountItem] = []
        for doc in genresSnap.documents {
            let name = (doc.data()["name"] as? String) ?? doc.documentID
            let coverPath = doc.data()["coverPath"] as? String
            let count = genreCounts[name] ?? 0

            items.append(CountItem(
                id: doc.documentID,
                key: name,
                count: count,
                coverPath: coverPath
            ))
        }

        return items.sorted { ($0.count, $1.key.lowercased()) > ($1.count, $0.key.lowercased()) }
    }

    // MARK: - Fetch Sources with Counts
    func fetchSourcesList() async throws -> [CountItem] {
        let sourcesSnap = try await db.collection("sources").getDocuments()
        let songsSnap = try await db.collection("songs").getDocuments()

        var sourceCounts: [String: Int] = [:]
        for doc in songsSnap.documents {
            if let source = doc.data()["source"] as? String, !source.isEmpty {
                sourceCounts[source, default: 0] += 1
            }
        }

        var items: [CountItem] = []
        for doc in sourcesSnap.documents {
            let name = (doc.data()["name"] as? String) ?? doc.documentID
            let coverPath = doc.data()["coverPath"] as? String
            let count = sourceCounts[name] ?? 0

            items.append(CountItem(
                id: doc.documentID,
                key: name,
                count: count,
                coverPath: coverPath
            ))
        }

        return items.sorted { ($0.count, $1.key.lowercased()) > ($1.count, $0.key.lowercased()) }
    }

    // MARK: - Fetch Sources by Genre
    func fetchSourcesByGenreId(_ genreId: String) async throws -> [CountItem] {
        let sourcesSnap = try await db.collection("sources")
            .whereField("genreId", isEqualTo: genreId)
            .getDocuments()

        let songsSnap = try await db.collection("songs").getDocuments()

        var sourceCounts: [String: Int] = [:]
        for doc in songsSnap.documents {
            if let source = doc.data()["source"] as? String, !source.isEmpty {
                sourceCounts[source, default: 0] += 1
            }
        }

        var items: [CountItem] = []
        for doc in sourcesSnap.documents {
            let name = (doc.data()["name"] as? String) ?? doc.documentID
            let coverPath = doc.data()["coverPath"] as? String
            let count = sourceCounts[name] ?? 0

            items.append(CountItem(
                id: doc.documentID,
                key: name,
                count: count,
                coverPath: coverPath
            ))
        }

        return items.sorted { ($0.count, $1.key.lowercased()) > ($1.count, $0.key.lowercased()) }
    }

    // MARK: - Get Genre ID by Name
    func getGenreIdByName(_ genreName: String) async throws -> String? {
        let snapshot = try await db.collection("genres")
            .whereField("name", isEqualTo: genreName)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first?.documentID
    }

    // MARK: - Fetch Songs by Artist
    func fetchSongsByArtist(_ artist: String, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .whereField("artist", isEqualTo: artist)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Songs by Album
    func fetchSongsByAlbum(_ album: String, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .whereField("album", isEqualTo: album)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Songs by Year
    func fetchSongsByYear(_ year: Int, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .whereField("year", isEqualTo: year)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Songs by Genre
    func fetchSongsByGenre(_ genre: String, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .whereField("genre", isEqualTo: genre)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Songs by Source
    func fetchSongsBySource(_ source: String, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .whereField("source", isEqualTo: source)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Liked Songs
    func fetchLikedSongs(limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        var query: Query = db.collection("songs")
            .whereField("liked", isEqualTo: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch New Songs (last 7 days)
    func fetchNewSongs(limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        var query: Query = db.collection("songs")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: oneWeekAgo))
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Songs by Title (search)
    func fetchSongsByTitle(_ titlePrefix: String, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (songs: [Song], lastDoc: DocumentSnapshot?) {
        let lowercasePrefix = titlePrefix.lowercased()

        var query: Query = db.collection("songs")
            .order(by: "titleMinusculas")
            .start(at: [lowercasePrefix])
            .end(at: [lowercasePrefix + "\u{f8ff}"])
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let songs = snapshot.documents.compactMap { docToSong($0) }

        return (songs, snapshot.documents.last)
    }

    // MARK: - Fetch Playlists
    func fetchPlaylists() async throws -> [Playlist] {
        let snapshot = try await db.collection("playlists").getDocuments()

        var playlists: [Playlist] = []
        for doc in snapshot.documents {
            guard let name = doc.data()["name"] as? String else { continue }
            let coverPath = doc.data()["coverPath"] as? String
            let songsArray = doc.data()["songs"] as? [Any] ?? []

            playlists.append(Playlist(
                id: doc.documentID,
                name: name,
                coverPath: coverPath,
                songCount: songsArray.count
            ))
        }

        return playlists.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // MARK: - Fetch Playlist Songs
    func fetchPlaylistSongs(_ playlistId: String) async throws -> [Song] {
        let playlistDoc = try await db.collection("playlists").document(playlistId).getDocument()

        guard playlistDoc.exists,
              let songTitles = playlistDoc.data()?["songs"] as? [String] else {
            return []
        }

        if songTitles.isEmpty { return [] }

        var allSongs: [Song] = []

        // Firestore whereIn has limit of 10, so batch
        for batch in stride(from: 0, to: songTitles.count, by: 10) {
            let end = min(batch + 10, songTitles.count)
            let batchTitles = Array(songTitles[batch..<end])

            let snapshot = try await db.collection("songs")
                .whereField("title", in: batchTitles)
                .getDocuments()

            let songs = snapshot.documents.compactMap { docToSong($0) }
            allSongs.append(contentsOf: songs)
        }

        // Order by playlist order
        return songTitles.compactMap { title in
            allSongs.first { $0.title == title }
        }
    }

    // MARK: - Toggle Liked Status
    func toggleLiked(songId: String, liked: Bool) async throws {
        try await db.collection("songs").document(songId).updateData([
            "liked": liked
        ])
    }

    // MARK: - Get Audio URL from Storage
    func getAudioURL(for audioPath: String) async throws -> URL {
        let ref = storage.reference().child(audioPath)
        return try await ref.downloadURL()
    }

    // MARK: - Get Cover URL from Storage
    func getCoverURL(for coverPath: String) async throws -> URL {
        let ref = storage.reference().child(coverPath)
        return try await ref.downloadURL()
    }

    // MARK: - Download Cover Image
    func downloadCoverImage(for coverPath: String) async throws -> UIImage? {
        let url = try await getCoverURL(for: coverPath)
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }

    // MARK: - Add Song to Playlist
    func addSongToPlaylist(songTitle: String, playlistId: String) async throws {
        let playlistRef = db.collection("playlists").document(playlistId)
        try await playlistRef.updateData([
            "songs": FieldValue.arrayUnion([songTitle])
        ])
    }

    // MARK: - Remove Song from Playlist
    func removeSongFromPlaylist(songTitle: String, playlistId: String) async throws {
        let playlistRef = db.collection("playlists").document(playlistId)
        try await playlistRef.updateData([
            "songs": FieldValue.arrayRemove([songTitle])
        ])
    }

    // MARK: - Create New Playlist
    func createPlaylist(name: String) async throws -> Playlist {
        let playlistData: [String: Any] = [
            "name": name,
            "songs": [String](),
            "songsId": [String](),
            "coverPath": ""
        ]

        let docRef = try await db.collection("playlists").addDocument(data: playlistData)

        return Playlist(
            id: docRef.documentID,
            name: name,
            coverPath: nil,
            songCount: 0
        )
    }

    // MARK: - Delete Playlist
    func deletePlaylist(playlistId: String) async throws {
        try await db.collection("playlists").document(playlistId).delete()
    }

    // MARK: - Upload Cover Image
    enum CoverType {
        case artist
        case album
        case year
        case genre
        case source
        case playlist

        var storagePath: String {
            switch self {
            case .artist: return "CoverArtistas"
            case .album: return "CoverAlbums"
            case .year: return "CoverAños"
            case .genre: return "CoverGenres"
            case .source: return "CoverSources"
            case .playlist: return "CoverPlaylists"
            }
        }

        var collectionName: String {
            switch self {
            case .artist: return "artistas"
            case .album: return "albums"
            case .year: return "years"
            case .genre: return "genres"
            case .source: return "sources"
            case .playlist: return "playlists"
            }
        }
    }

    func uploadCoverImage(image: UIImage, type: CoverType, itemName: String, documentId: String?) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Create unique filename
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let safeName = itemName.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        let filename = "\(safeName)_\(timestamp).jpg"
        let storagePath = "\(type.storagePath)/\(filename)"

        // Upload to Storage
        let storageRef = storage.reference().child(storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Update Firestore document with coverPath
        if let docId = documentId {
            // Direct document ID provided
            try await db.collection(type.collectionName).document(docId).updateData([
                "coverPath": storagePath
            ])
        } else {
            // Search by name field
            let query = db.collection(type.collectionName).whereField("name", isEqualTo: itemName).limit(to: 1)
            let snapshot = try await query.getDocuments()

            if let doc = snapshot.documents.first {
                try await db.collection(type.collectionName).document(doc.documentID).updateData([
                    "coverPath": storagePath
                ])
            }
        }

        return storagePath
    }

    // Upload cover for year (special case - years might not have a collection)
    func uploadYearCover(image: UIImage, year: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let filename = "\(year)_\(timestamp).jpg"
        let storagePath = "CoverAños/\(filename)"

        let storageRef = storage.reference().child(storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Years typically don't have their own collection, so we just return the path
        // The app should store this locally or handle differently
        return storagePath
    }
}
