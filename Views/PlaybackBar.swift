//
//  PlaybackBar.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct PlaybackBar: View {
    @ObservedObject var audioPlayer: AudioPlayer
    let onToggleLike: () -> Void
    @State private var showNowPlaying = false

    var body: some View {
        if let song = audioPlayer.currentSong {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    let progress = audioPlayer.duration > 0
                        ? CGFloat(audioPlayer.currentTime / audioPlayer.duration)
                        : 0

                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)

                        Rectangle()
                            .fill(Color.primaryBlue)
                            .frame(width: geometry.size.width * progress, height: 2)
                    }
                }
                .frame(height: 2)

                // Main content
                HStack(spacing: 12) {
                    // Cover
                    Button {
                        showNowPlaying = true
                    } label: {
                        ZStack {
                            if let image = song.coverImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.primaryBlue)
                                    )
                            }
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    // Title and artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        if !song.artist.isEmpty {
                            Text(song.artist)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Controls
                    HStack(spacing: 4) {
                        // Previous
                        Button {
                            audioPlayer.previous()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title3)
                                .foregroundColor(.primaryBlue)
                        }
                        .frame(width: 36, height: 36)

                        // Play/Pause
                        Button {
                            audioPlayer.togglePlayPause()
                        } label: {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.primaryBlue)
                        }
                        .frame(width: 44, height: 44)

                        // Next
                        Button {
                            audioPlayer.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundColor(.primaryBlue)
                        }
                        .frame(width: 36, height: 36)

                        // Like
                        Button {
                            onToggleLike()
                        } label: {
                            Image(systemName: song.liked ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(song.liked ? .primaryBlue : .secondary)
                        }
                        .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
            .sheet(isPresented: $showNowPlaying) {
                NowPlayingView(audioPlayer: audioPlayer, onToggleLike: onToggleLike)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        PlaybackBar(
            audioPlayer: AudioPlayer.shared,
            onToggleLike: {}
        )
    }
}
