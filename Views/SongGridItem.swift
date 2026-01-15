//
//  SongGridItem.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct SongGridItem: View {
    let song: Song
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Cover Image
                ZStack {
                    if let image = song.coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.title)
                                    .foregroundColor(.primaryBlue)
                            )
                    }

                    // Playing indicator
                    if isPlaying {
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Title
                Text(song.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                // Artist
                if !song.artist.isEmpty {
                    Text(song.artist)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SongGridItem(
        song: Song(title: "Test Song", audioPath: "test.mp3", artist: "Test Artist"),
        isPlaying: false,
        onTap: {}
    )
    .frame(width: 150)
    .padding()
}
