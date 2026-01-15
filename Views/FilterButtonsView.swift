//
//  FilterButtonsView.swift
//  AplicacionMusicaiOS
//

import SwiftUI

struct FilterButtonsView: View {
    let selectedFilter: FilterMode
    let onFilterSelected: (FilterMode) -> Void

    private let filters: [FilterMode] = [.liked, .genre, .artist, .album, .year, .source]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        onTap: { onFilterSelected(filter) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct FilterButton: View {
    let filter: FilterMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: filter.icon)
                    .font(.caption)

                if filter != .liked {
                    Text(filter.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryBlue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        FilterButtonsView(
            selectedFilter: .artist,
            onFilterSelected: { _ in }
        )
    }
    .padding()
}
