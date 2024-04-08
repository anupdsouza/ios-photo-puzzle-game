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
            } else {
                Color.white
            }
        }
        .overlay {
            Rectangle()
                .stroke(.black, lineWidth: 1.0)
        }
    }
}
