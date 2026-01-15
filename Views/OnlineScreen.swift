//
//  OnlineScreen.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct OnlineScreen: View {
    @StateObject private var viewModel = MusicViewModel()
    @State private var showViewModeMenu = false

    // Create Playlist
    @State private var showCreatePlaylistAlert = false
    @State private var newPlaylistName = ""

    // Cover Upload
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var uploadingCoverFor: (item: Any, type: OnlineRepository.CoverType)?
    @State private var isUploadingCover = false
    @State private var showUploadSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Top Bar
                    topBar

                    // Search Bar
                    searchBar

                    // Filter Buttons
                    if viewModel.screenMode == .random || viewModel.screenMode == .pickFilter {
                        FilterButtonsView(
                            selectedFilter: viewModel.filterMode,
                            onFilterSelected: { filter in
                                switch filter {
                                case .liked:
                                    viewModel.loadLikedSongs()
                                case .new:
                                    viewModel.loadNewSongs()
                                default:
                                    viewModel.loadBrowseItems(for: filter)
                                }
                            }
                        )
                        .padding(.vertical, 8)
                    }

                    // Content
                    content

                    // Playback Bar
                    PlaybackBar(
                        audioPlayer: viewModel.audioPlayer,
                        onToggleLike: {
                            if let song = viewModel.audioPlayer.currentSong {
                                viewModel.toggleLike(for: song)
                            }
                        }
                    )
                }

                // Loading overlay
                if viewModel.isLoading && viewModel.songs.isEmpty && viewModel.browseItems.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadRandomSongs()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                uploadCoverImage(image)
            }
        }
        .alert("Cover actualizada", isPresented: $showUploadSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("La imagen se ha subido correctamente")
        }
        .overlay {
            if isUploadingCover {
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Subiendo imagen...")
                            .foregroundColor(.white)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            // Home button
            Button {
                viewModel.goHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.primaryBlue)
            }

            // Back button
            if viewModel.canGoBack {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primaryBlue)
                }
            }

            Spacer()

            // Title
            if viewModel.screenMode == .filterResults {
                Text(viewModel.filterValue)
                    .font(.headline)
                    .lineLimit(1)
            } else if viewModel.screenMode == .pickFilter {
                if viewModel.isShowingGenresForSource {
                    Text("Seleccionar Genero")
                        .font(.headline)
                } else if viewModel.filterMode == .source && !viewModel.filterValue.isEmpty {
                    Text("Sources: \(viewModel.filterValue)")
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text(viewModel.filterMode.displayName)
                        .font(.headline)
                }
            }

            Spacer()

            // NEW button
            Button {
                viewModel.loadNewSongs()
            } label: {
                Text("NEW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryBlue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            // View Mode Menu
            Menu {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.setViewMode(mode)
                    } label: {
                        Label(mode.displayName, systemImage: mode.icon)
                        if viewModel.viewMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Image(systemName: viewModel.viewMode.icon)
                    .font(.title2)
                    .foregroundColor(.primaryBlue)
            }

            // Playlists
            Button {
                viewModel.loadPlaylists()
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title2)
                    .foregroundColor(.primaryBlue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Buscar por titulo", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.performSearch()
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        switch viewModel.screenMode {
        case .random, .filterResults:
            songsContent
        case .pickFilter:
            filterItemsContent
        case .playlists:
            playlistsContent
        }
    }

    // MARK: - Songs Content
    private var songsContent: some View {
        Group {
            if viewModel.viewMode == .list {
                songsList
            } else {
                songsGrid
            }
        }
    }

    private var songsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.songs) { song in
                    SongListItem(
                        song: song,
                        isPlaying: viewModel.audioPlayer.currentSong?.id == song.id,
                        onTap: {
                            viewModel.playSong(song)
                        }
                    )
                }

                // Load more trigger
                if viewModel.screenMode == .random {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            viewModel.loadMoreSongs()
                        }
                }

                // Bottom padding for playback bar
                Color.clear.frame(height: 80)
            }
            .padding(.horizontal, 4)
        }
    }

    private var songsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: viewModel.viewMode.columns),
                spacing: 16
            ) {
                ForEach(viewModel.songs) { song in
                    SongGridItem(
                        song: song,
                        isPlaying: viewModel.audioPlayer.currentSong?.id == song.id,
                        onTap: {
                            viewModel.playSong(song)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Load more trigger
            if viewModel.screenMode == .random {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        viewModel.loadMoreSongs()
                    }
            }

            // Bottom padding for playback bar
            Color.clear.frame(height: 80)
        }
    }

    // MARK: - Filter Items Content
    private var filterItemsContent: some View {
        Group {
            if viewModel.viewMode == .list {
                filterItemsList
            } else {
                filterItemsGrid
            }
        }
    }

    private var filterItemsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.browseItems) { item in
                    FilterItemListView(
                        item: item,
                        onTap: {
                            handleFilterItemTap(item)
                        },
                        onLongPress: {
                            handleFilterItemLongPress(item)
                        }
                    )
                }

                Color.clear.frame(height: 80)
            }
            .padding(.horizontal, 4)
        }
    }

    private var filterItemsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: viewModel.viewMode.columns),
                spacing: 16
            ) {
                ForEach(viewModel.browseItems) { item in
                    FilterItemView(
                        item: item,
                        onTap: {
                            handleFilterItemTap(item)
                        },
                        onLongPress: {
                            handleFilterItemLongPress(item)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Color.clear.frame(height: 80)
        }
    }

    // MARK: - Handle Filter Item Tap
    private func handleFilterItemTap(_ item: CountItem) {
        if viewModel.isShowingGenresForSource {
            // Estamos en el flujo Source: el usuario seleccionó un género, cargar sources de ese género
            viewModel.loadSourcesByGenre(item.key)
        } else {
            // Flujo normal: cargar canciones filtradas
            viewModel.loadFilteredSongs(filter: viewModel.filterMode, value: item.key)
        }
    }

    // MARK: - Handle Filter Item Long Press (Upload Cover)
    private func handleFilterItemLongPress(_ item: CountItem) {
        let coverType: OnlineRepository.CoverType

        switch viewModel.filterMode {
        case .artist:
            coverType = .artist
        case .album:
            coverType = .album
        case .year:
            coverType = .year
        case .genre:
            coverType = .genre
        case .source:
            coverType = .source
        default:
            return
        }

        uploadingCoverFor = (item, coverType)
        showImagePicker = true
    }

    // MARK: - Playlists Content
    private var playlistsContent: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: 16
            ) {
                // Create Playlist Card
                CreatePlaylistCard {
                    showCreatePlaylistAlert = true
                }

                ForEach(viewModel.playlists) { playlist in
                    PlaylistItemView(
                        playlist: playlist,
                        onTap: {
                            viewModel.loadPlaylistSongs(playlist)
                        },
                        onLongPress: {
                            uploadingCoverFor = (playlist, .playlist)
                            showImagePicker = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Color.clear.frame(height: 80)
        }
        .alert("Nueva Playlist", isPresented: $showCreatePlaylistAlert) {
            TextField("Nombre de la playlist", text: $newPlaylistName)
            Button("Cancelar", role: .cancel) {
                newPlaylistName = ""
            }
            Button("Crear") {
                createNewPlaylist()
            }
            .disabled(newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Introduce el nombre para la nueva playlist")
        }
    }

    private func createNewPlaylist() {
        let name = newPlaylistName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        Task {
            let success = await viewModel.createPlaylist(name: name)
            if success {
                newPlaylistName = ""
            }
        }
    }

    private func uploadCoverImage(_ image: UIImage) {
        guard let (item, coverType) = uploadingCoverFor else { return }

        isUploadingCover = true
        selectedImage = nil

        Task {
            do {
                if let countItem = item as? CountItem {
                    _ = try await OnlineRepository.shared.uploadCoverImage(
                        image: image,
                        type: coverType,
                        itemName: countItem.key,
                        documentId: countItem.id
                    )

                    // Update local image
                    if let index = viewModel.browseItems.firstIndex(where: { $0.id == countItem.id }) {
                        viewModel.browseItems[index].coverImage = image
                    }
                } else if let playlist = item as? Playlist {
                    _ = try await OnlineRepository.shared.uploadCoverImage(
                        image: image,
                        type: .playlist,
                        itemName: playlist.name,
                        documentId: playlist.id
                    )

                    // Update local image
                    if let index = viewModel.playlists.firstIndex(where: { $0.id == playlist.id }) {
                        viewModel.playlists[index].coverImage = image
                    }
                }

                showUploadSuccessAlert = true
            } catch {
                print("Error uploading cover: \(error)")
            }

            isUploadingCover = false
            uploadingCoverFor = nil
        }
    }
}

// MARK: - Create Playlist Card
struct CreatePlaylistCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Rectangle()
                        .fill(Color.primaryBlue.opacity(0.15))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.primaryBlue)
                                Text("Crear")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primaryBlue)
                            }
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primaryBlue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )

                Text("Nueva Playlist")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primaryBlue)

                Text("")
                    .font(.caption2)
                    .foregroundColor(.clear)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Playlist Item View
struct PlaylistItemView: View {
    let playlist: Playlist
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = playlist.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.title)
                                .foregroundColor(.primaryBlue)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(playlist.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)

            Text("\(playlist.songCount) canciones")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress?()
        }
    }
}

#Preview {
    OnlineScreen()
}
