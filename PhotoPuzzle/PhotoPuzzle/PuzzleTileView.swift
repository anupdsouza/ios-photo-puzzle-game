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
            if tile.isSpareTile {
                Color.white
            } else {
                Image(uiImage: tile.image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .overlay {
            Rectangle()
                .stroke(.black, lineWidth: 1.0)
        }
    }
}
