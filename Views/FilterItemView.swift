//
//  FilterItemView.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct FilterItemView: View {
    let item: CountItem
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Cover Image
            ZStack {
                if let image = item.coverImage {
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

            // Name
            Text(item.key)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)

            // Count
            Text("\(item.count) canciones")
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

struct FilterItemListView: View {
    let item: CountItem
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            ZStack {
                if let image = item.coverImage {
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
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.key)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(item.count) canciones")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
    VStack {
        FilterItemView(
            item: CountItem(key: "Artist Name", count: 15),
            onTap: {}
        )
        .frame(width: 150)

        FilterItemListView(
            item: CountItem(key: "Album Name", count: 10),
            onTap: {}
        )
    }
    .padding()
}
