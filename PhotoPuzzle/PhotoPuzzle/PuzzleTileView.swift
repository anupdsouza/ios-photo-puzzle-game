//
//  PuzzleTileView.swift
//  PhotoPuzzle
//
//  Created by Anup D'Souza on 08/04/24.
//

import SwiftUI

struct PuzzleTileView: View {
    let tile: PuzzleTile
    var body: some View {
        VStack {
            if let image = tile.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            else {
                Color.colorYellow
            }
        }
        .overlay(content: {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.colorYellow, lineWidth: 2)
        })
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    PuzzleTileView(tile: PuzzleTile(image: nil, isSpareTile: true))
}
