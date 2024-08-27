//
//  PuzzleTileView.swift
//  PhotoPuzzle
//
//  Created by Anup D'Souza on 08/04/24.
//  🕸️ https://www.anupdsouza.com
//  🔗 https://twitter.com/swift_odyssey
//  👨🏻‍💻 https://github.com/anupdsouza
//  ☕️ https://www.buymeacoffee.com/adsouza
//  🫶🏼 https://patreon.com/adsouza
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
