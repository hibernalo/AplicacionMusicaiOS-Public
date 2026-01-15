//
//  MusicViewModel.swift
//  AplicacionMusicaiOS
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class MusicViewModel: ObservableObject {
    // MARK: - Screen State
    @Published var screenMode: ScreenMode = .random
    @Published var filterMode: FilterMode = .none
    @Published var filterValue: String = ""
    @Published var viewMode: ViewMode = .grid4

    // MARK: - Data
    @Published var songs: [Song] = []
    @Published var browseItems: [CountItem] = []
    @Published var playlists: [Playlist] = []

    // MARK: - Loading State
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""

    // MARK: - Source Flow (Genre -> Source -> Songs)
    @Published var isShowingGenresForSource: Bool = false
    private var selectedGenreIdForSource: String?

    // MARK: - Navigation Stack
    private var navigationStack: [NavigationState] = []

    // MARK: - Pagination
    private var lastDocument: DocumentSnapshot?
    private var canLoadMore: Bool = true

    // MARK: - Cache
    private var originalSongsCache: [Song] = []
    private var originalBrowseItemsCache: [CountItem] = []

    // MARK: - Search Debounce
    private var searchTask: Task<Void, Never>?

    // MARK: - Audio Player Reference
    let audioPlayer = AudioPlayer.shared
    let repository = OnlineRepository.shared

    init() {
        loadViewModeFromPrefs()
    }

    // MARK: - View Mode Persistence
    func loadViewModeFromPrefs() {
        if let saved = UserDefaults.standard.string(forKey: "viewMode"),
           let mode = ViewMode(rawValue: saved) {
            viewMode = mode
        }
    }

    func saveViewModeToPrefs() {
        UserDefaults.standard.set(viewMode.rawValue, forKey: "viewMode")
    }

    func setViewMode(_ mode: ViewMode) {
        viewMode = mode
        saveViewModeToPrefs()
    }

    // MARK: - Navigation
    func pushNavigationState() {
        let state = NavigationState(
            screenMode: screenMode,
            filterMode: filterMode,
            filterValue: filterValue,
            browseItems: browseItems,
            browseSongs: songs,
            scrollPosition: nil
        )
        navigationStack.append(state)
    }

    func popNavigationState() -> Bool {
        guard let state = navigationStack.popLast() else { return false }

        screenMode = state.screenMode
        filterMode = state.filterMode
        filterValue = state.filterValue ?? ""
        browseItems = state.browseItems
        songs = state.browseSongs
        searchQuery = ""

        return true
    }

    var canGoBack: Bool {
        !navigationStack.isEmpty
    }

    func goBack() {
        _ = popNavigationState()
    }

    func goHome() {
        navigationStack.removeAll()
        screenMode = .random
        filterMode = .none
        filterValue = ""
        searchQuery = ""
        loadRandomSongs()
    }

    // MARK: - Load Random Songs
    func loadRandomSongs() {
        Task {
            isLoading = true
            songs = []
            canLoadMore = true

            do {
                // Cargar canciones aleatorias usando el campo rand
                let randomSongs = try await repository.fetchRandomSongs(limit: 50)
                songs = randomSongs
                originalSongsCache = randomSongs

                // Load covers in background
                loadCoversForSongs()
            } catch {
                print("Error loading songs: \(error)")
            }

            isLoading = false
        }
    }

    func loadMoreSongs() {
        guard !isLoading && canLoadMore else { return }

        Task {
            isLoading = true

            do {
                // Cargar más canciones aleatorias
                let moreSongs = try await repository.fetchRandomSongs(limit: 50)

                // Filtrar canciones que ya tenemos para evitar duplicados
                let existingIds = Set(songs.map { $0.id })
                let newSongs = moreSongs.filter { !existingIds.contains($0.id) }

                if newSongs.isEmpty {
                    canLoadMore = false
                } else {
                    songs.append(contentsOf: newSongs)
                    originalSongsCache = songs
                    loadCoversForSongs()
                }
            } catch {
                print("Error loading more songs: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load Browse Items (Filters)
    func loadBrowseItems(for filter: FilterMode) {
        pushNavigationState()
        screenMode = .pickFilter
        filterMode = filter
        browseItems = []
        isShowingGenresForSource = false

        Task {
            isLoading = true

            do {
                switch filter {
                case .artist:
                    browseItems = try await repository.fetchArtistsWithCounts()
                case .album:
                    browseItems = try await repository.fetchAlbumsWithCounts()
                case .year:
                    browseItems = try await repository.fetchYearsWithCounts()
                case .genre:
                    browseItems = try await repository.fetchGenresList()
                case .source:
                    // Para source, primero mostramos los géneros
                    isShowingGenresForSource = true
                    browseItems = try await repository.fetchGenresList()
                default:
                    break
                }
                originalBrowseItemsCache = browseItems

                // Load covers
                loadCoversForItems()
            } catch {
                print("Error loading browse items: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load Sources by Genre
    func loadSourcesByGenre(_ genreName: String) {
        pushNavigationState()
        screenMode = .pickFilter
        filterMode = .source
        filterValue = genreName
        browseItems = []
        isShowingGenresForSource = false

        Task {
            isLoading = true

            do {
                // Obtener el genreId por nombre
                if let genreId = try await repository.getGenreIdByName(genreName) {
                    selectedGenreIdForSource = genreId
                    browseItems = try await repository.fetchSourcesByGenreId(genreId)
                } else {
                    // Si no encontramos el género por nombre, usar el nombre como ID
                    browseItems = try await repository.fetchSourcesByGenreId(genreName)
                }
                originalBrowseItemsCache = browseItems
                loadCoversForItems()
            } catch {
                print("Error loading sources by genre: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load Filtered Songs
    func loadFilteredSongs(filter: FilterMode, value: String) {
        pushNavigationState()
        screenMode = .filterResults
        filterMode = filter
        filterValue = value
        songs = []
        lastDocument = nil
        canLoadMore = true

        Task {
            isLoading = true

            do {
                let result: (songs: [Song], lastDoc: DocumentSnapshot?)

                switch filter {
                case .artist:
                    result = try await repository.fetchSongsByArtist(value)
                case .album:
                    result = try await repository.fetchSongsByAlbum(value)
                case .year:
                    result = try await repository.fetchSongsByYear(Int(value) ?? 0)
                case .genre:
                    result = try await repository.fetchSongsByGenre(value)
                case .source:
                    result = try await repository.fetchSongsBySource(value)
                case .liked:
                    result = try await repository.fetchLikedSongs()
                case .new:
                    result = try await repository.fetchNewSongs()
                default:
                    result = ([], nil)
                }

                songs = result.songs
                originalSongsCache = result.songs
                lastDocument = result.lastDoc
                canLoadMore = result.lastDoc != nil

                loadCoversForSongs()
            } catch {
                print("Error loading filtered songs: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load Liked Songs
    func loadLikedSongs() {
        pushNavigationState()
        screenMode = .filterResults
        filterMode = .liked
        filterValue = "LIKED"
        songs = []

        Task {
            isLoading = true

            do {
                let result = try await repository.fetchLikedSongs(limit: 100)
                songs = result.songs
                originalSongsCache = result.songs
                loadCoversForSongs()
            } catch {
                print("Error loading liked songs: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load New Songs
    func loadNewSongs() {
        pushNavigationState()
        screenMode = .filterResults
        filterMode = .new
        filterValue = "NEW"
        songs = []

        Task {
            isLoading = true

            do {
                let result = try await repository.fetchNewSongs(limit: 50)
                songs = result.songs
                originalSongsCache = result.songs
                loadCoversForSongs()
            } catch {
                print("Error loading new songs: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load Playlists
    func loadPlaylists() {
        pushNavigationState()
        screenMode = .playlists

        Task {
            isLoading = true

            do {
                playlists = try await repository.fetchPlaylists()
                loadCoversForPlaylists()
            } catch {
                print("Error loading playlists: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Load Playlist Songs
    func loadPlaylistSongs(_ playlist: Playlist) {
        pushNavigationState()
        screenMode = .filterResults
        filterMode = .none
        filterValue = playlist.name
        songs = []

        Task {
            isLoading = true

            do {
                songs = try await repository.fetchPlaylistSongs(playlist.id)
                originalSongsCache = songs
                loadCoversForSongs()
            } catch {
                print("Error loading playlist songs: \(error)")
            }

            isLoading = false
        }
    }

    // MARK: - Cover Loading for Playlists
    private func loadCoversForPlaylists() {
        let playlistsSnapshot = playlists
        Task {
            for playlist in playlistsSnapshot {
                guard let coverPath = playlist.coverPath else { continue }

                do {
                    let image = try await repository.downloadCoverImage(for: coverPath)
                    if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
                        playlists[index].coverImage = image
                    }
                } catch {
                    print("Error loading playlist cover: \(error)")
                }
            }
        }
    }

    // MARK: - Create New Playlist
    func createPlaylist(name: String) async -> Bool {
        do {
            let newPlaylist = try await repository.createPlaylist(name: name)
            playlists.insert(newPlaylist, at: 0)
            return true
        } catch {
            print("Error creating playlist: \(error)")
            return false
        }
    }

    // MARK: - Search
    func performSearch() {
        searchTask?.cancel()

        // If empty, restore cache
        if searchQuery.isEmpty {
            if screenMode == .pickFilter {
                browseItems = originalBrowseItemsCache
            } else {
                songs = originalSongsCache
            }
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(AppConstants.searchDelayMs) * 1_000_000)

            if Task.isCancelled { return }

            let query = searchQuery.lowercased()

            if screenMode == .pickFilter {
                // Filter browse items locally
                browseItems = originalBrowseItemsCache.filter {
                    $0.key.lowercased().contains(query)
                }
            } else if filterMode == .liked || screenMode == .filterResults {
                // Filter songs locally
                songs = originalSongsCache.filter {
                    $0.title.lowercased().contains(query) ||
                    $0.artist.lowercased().contains(query)
                }
            } else {
                // Search in Firestore by title
                do {
                    let result = try await repository.fetchSongsByTitle(query)
                    songs = result.songs
                    loadCoversForSongs()
                } catch {
                    print("Error searching: \(error)")
                }
            }
        }
    }

    // MARK: - Playback
    func playSong(_ song: Song, from queue: [Song]? = nil) {
        let playQueue = queue ?? songs
        guard let index = playQueue.firstIndex(where: { $0.id == song.id }) else { return }

        Task {
            await audioPlayer.play(song: song, queue: playQueue, index: index)
        }
    }

    func toggleLike(for song: Song) {
        Task {
            do {
                try await repository.toggleLiked(songId: song.id, liked: !song.liked)

                // Update local state
                if let index = songs.firstIndex(where: { $0.id == song.id }) {
                    songs[index].liked.toggle()
                }

                // Update audio player if current song
                if audioPlayer.currentSong?.id == song.id {
                    audioPlayer.currentSong?.liked.toggle()
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }

    // MARK: - Cover Loading
    private func loadCoversForSongs() {
        let songsSnapshot = songs
        Task {
            for song in songsSnapshot {
                guard let coverPath = song.coverPath else { continue }

                do {
                    let image = try await repository.downloadCoverImage(for: coverPath)
                    // Find and update by ID to avoid index issues
                    if let index = songs.firstIndex(where: { $0.id == song.id }) {
                        songs[index].coverImage = image
                    }
                } catch {
                    // Silently fail for cover loading
                }
            }
        }
    }

    private func loadCoversForItems() {
        let itemsSnapshot = browseItems
        Task {
            for item in itemsSnapshot {
                guard let coverPath = item.coverPath else { continue }

                do {
                    let image = try await repository.downloadCoverImage(for: coverPath)
                    // Find and update by ID to avoid index issues
                    if let index = browseItems.firstIndex(where: { $0.id == item.id }) {
                        browseItems[index].coverImage = image
                    }
                } catch {
                    // Silently fail for cover loading
                }
            }
        }
    }
}
