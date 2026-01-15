//
//  SongListItem.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct SongListItem: View {
    let song: Song
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Cover Image
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

                // Song Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .fontWeight(isPlaying ? .semibold : .regular)
                        .foregroundColor(isPlaying ? .primaryBlue : .primary)
                        .lineLimit(1)

                    if !song.artist.isEmpty {
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Playing indicator
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.primaryBlue)
                }

                // Liked indicator
                if song.liked {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.primaryBlue)
                        .font(.caption)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isPlaying ? Color.primaryBlue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        SongListItem(
            song: Song(title: "Test Song", audioPath: "test.mp3", artist: "Test Artist"),
            isPlaying: false,
            onTap: {}
        )
        SongListItem(
            song: Song(title: "Playing Song", audioPath: "test.mp3", artist: "Test Artist", liked: true),
            isPlaying: true,
            onTap: {}
        )
    }
    .padding()
}
