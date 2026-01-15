//
//  NowPlayingView.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    let onToggleLike: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    // Playlist selection
    @State private var showPlaylistSheet = false
    @State private var playlists: [Playlist] = []
    @State private var isLoadingPlaylists = false
    @State private var showAddedAlert = false
    @State private var addedPlaylistName = ""

    // Dynamic colors from cover
    @State private var dominantColor: Color = Color.primaryBlue
    @State private var secondaryColor: Color = Color.black

    var body: some View {
        ZStack {
            // Background gradient with dynamic colors
            LinearGradient(
                colors: [dominantColor.opacity(0.9), secondaryColor, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: dominantColor)

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Reproduciendo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    // Placeholder for symmetry
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 60)

                Spacer()

                // Cover Image
                if let song = audioPlayer.currentSong {
                    ZStack {
                        if let image = song.coverImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white.opacity(0.5))
                                )
                        }
                    }
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 20)

                    Spacer()

                    // Song Info
                    VStack(spacing: 8) {
                        Text(song.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(song.artist.isEmpty ? AppConstants.unknownArtist : song.artist)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)

                        if !song.album.isEmpty {
                            Text(song.album)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Progress Slider
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { isDragging ? dragProgress : audioPlayer.currentTime },
                                set: { newValue in
                                    dragProgress = newValue
                                    isDragging = true
                                }
                            ),
                            in: 0...max(audioPlayer.duration, 1),
                            onEditingChanged: { editing in
                                if !editing {
                                    audioPlayer.seek(to: dragProgress)
                                    isDragging = false
                                }
                            }
                        )
                        .tint(.white)

                        HStack {
                            Text(audioPlayer.formatTime(isDragging ? dragProgress : audioPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()

                            Text(audioPlayer.formatTime(audioPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 32)

                    // Controls
                    HStack(spacing: 32) {
                        // Shuffle
                        Button {
                            audioPlayer.toggleShuffle()
                        } label: {
                            Image(systemName: "shuffle")
                                .font(.title2)
                                .foregroundColor(audioPlayer.isShuffleOn ? .white : .white.opacity(0.5))
                        }

                        // Previous
                        Button {
                            audioPlayer.previous()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }

                        // Play/Pause
                        Button {
                            audioPlayer.togglePlayPause()
                        } label: {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(.white)
                        }

                        // Next
                        Button {
                            audioPlayer.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }

                        // Repeat
                        Button {
                            audioPlayer.toggleRepeat()
                        } label: {
                            Image(systemName: audioPlayer.repeatMode.icon)
                                .font(.title2)
                                .foregroundColor(audioPlayer.repeatMode != .none ? .white : .white.opacity(0.5))
                        }
                    }
                    .padding(.top, 16)

                    // Like and Add to Playlist buttons
                    HStack(spacing: 16) {
                        // Like button
                        Button {
                            onToggleLike()
                        } label: {
                            HStack {
                                Image(systemName: song.liked ? "heart.fill" : "heart")
                                Text(song.liked ? "Te gusta" : "Me gusta")
                            }
                            .font(.subheadline)
                            .foregroundColor(song.liked ? .primaryBlue : .white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(song.liked ? Color.white : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        // Add to Playlist button
                        Button {
                            loadPlaylistsAndShow()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Playlist")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 16)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showPlaylistSheet) {
            PlaylistSelectionSheet(
                playlists: playlists,
                isLoading: isLoadingPlaylists,
                onSelect: { playlist in
                    addToPlaylist(playlist)
                }
            )
            .presentationDetents([.medium])
        }
        .alert("Añadida", isPresented: $showAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Cancion añadida a \(addedPlaylistName)")
        }
        .onAppear {
            extractColorsFromCover()
        }
        .onChange(of: audioPlayer.currentSong?.id) { _, _ in
            extractColorsFromCover()
        }
    }

    // MARK: - Extract Colors from Cover
    private func extractColorsFromCover() {
        guard let image = audioPlayer.currentSong?.coverImage else {
            // Reset to default colors if no cover
            dominantColor = Color.primaryBlue
            secondaryColor = Color.black
            return
        }

        // Extract colors in background
        Task {
            let colors = await extractColors(from: image)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    dominantColor = colors.dominant
                    secondaryColor = colors.secondary
                }
            }
        }
    }

    private func extractColors(from image: UIImage) async -> (dominant: Color, secondary: Color) {
        guard let cgImage = image.cgImage else {
            return (Color.primaryBlue, Color.black)
        }

        let width = 50
        let height = 50

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (Color.primaryBlue, Color.black)
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else {
            return (Color.primaryBlue, Color.black)
        }

        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var colorCounts: [String: (count: Int, r: Int, g: Int, b: Int)] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = Int(pointer[offset])
                let g = Int(pointer[offset + 1])
                let b = Int(pointer[offset + 2])

                // Skip very dark or very light colors
                let brightness = (r + g + b) / 3
                if brightness < 30 || brightness > 225 { continue }

                // Quantize colors to reduce variations
                let qr = (r / 32) * 32
                let qg = (g / 32) * 32
                let qb = (b / 32) * 32
                let key = "\(qr),\(qg),\(qb)"

                if let existing = colorCounts[key] {
                    colorCounts[key] = (existing.count + 1, qr, qg, qb)
                } else {
                    colorCounts[key] = (1, qr, qg, qb)
                }
            }
        }

        // Sort by count and get top colors
        let sortedColors = colorCounts.values.sorted { $0.count > $1.count }

        let dominant: Color
        let secondary: Color

        if let first = sortedColors.first {
            dominant = Color(
                red: Double(first.r) / 255.0,
                green: Double(first.g) / 255.0,
                blue: Double(first.b) / 255.0
            )
        } else {
            dominant = Color.primaryBlue
        }

        if sortedColors.count > 1 {
            let second = sortedColors[1]
            secondary = Color(
                red: Double(second.r) / 255.0,
                green: Double(second.g) / 255.0,
                blue: Double(second.b) / 255.0
            ).opacity(0.7)
        } else {
            secondary = dominant.opacity(0.5)
        }

        return (dominant, secondary)
    }

    private func loadPlaylistsAndShow() {
        showPlaylistSheet = true
        isLoadingPlaylists = true

        Task {
            do {
                playlists = try await OnlineRepository.shared.fetchPlaylists()
            } catch {
                print("Error loading playlists: \(error)")
            }
            isLoadingPlaylists = false
        }
    }

    private func addToPlaylist(_ playlist: Playlist) {
        guard let song = audioPlayer.currentSong else { return }

        Task {
            do {
                try await OnlineRepository.shared.addSongToPlaylist(
                    songTitle: song.title,
                    playlistId: playlist.id
                )
                addedPlaylistName = playlist.name
                showPlaylistSheet = false
                showAddedAlert = true
            } catch {
                print("Error adding to playlist: \(error)")
            }
        }
    }
}

// MARK: - Playlist Selection Sheet
struct PlaylistSelectionSheet: View {
    let playlists: [Playlist]
    let isLoading: Bool
    let onSelect: (Playlist) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Cargando playlists...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if playlists.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No hay playlists")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(playlists) { playlist in
                        Button {
                            onSelect(playlist)
                        } label: {
                            HStack(spacing: 12) {
                                // Cover
                                ZStack {
                                    if let image = playlist.coverImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "music.note.list")
                                                    .foregroundColor(.primaryBlue)
                                            )
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(playlist.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("\(playlist.songCount) canciones")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Añadir a playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NowPlayingView(
        audioPlayer: AudioPlayer.shared,
        onToggleLike: {}
    )
}
