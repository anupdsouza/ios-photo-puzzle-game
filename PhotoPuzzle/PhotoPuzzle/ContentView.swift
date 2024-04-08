//
//  ContentView.swift
//  PhotoPuzzle
//
//  Created by Anup D'Souza on 02/04/24.
//

import SwiftUI
import PhotosUI

struct Tile: Equatable {
    let image: UIImage
    var isSpareTile = false
}

enum Direction {
    case up, down, left, right
}

struct ContentView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var puzzleImage: UIImage?
    @State private var orderedTiles: [[Tile]]?
    @State private var shuffledTiles: [[Tile]]?
    @State private var userWon = false
    @State private var loadingImage = false
    @State private var loadedPuzzle = false
    @State private var moveCount = 0
    private let tileSpacing = 5.0
    
    var body: some View {
        VStack {
            
            if loadedPuzzle {
                if let shuffledTiles, let puzzleImage {
                    if userWon {
                        Text("YOU WON")
                            .font(.largeTitle).bold()
                    } else {
                        Text("Visual Hint")
                    }
                    
                    Image(uiImage: puzzleImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    
                    GeometryReader { geometry in
                        VStack(spacing: tileSpacing) {
                            ForEach(0..<3, id: \.self) { row in
                                HStack(spacing: tileSpacing) {
                                    ForEach(0..<3, id: \.self) { column in
                                        Image(uiImage: shuffledTiles[row][column].image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: (geometry.size.width - (tileSpacing*2)) / 3, height: (geometry.size.width - (tileSpacing*2)) / 3)
                                            .clipped()
                                            .onTapGesture {
                                                tappedTile(row: row, column: column)
                                            }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    footerView()
                    
                }
            }
            else {
                emptyPuzzleView()
            }
        }
        .padding()
    }
    
    private func reset() {
        moveCount = 0
        userWon = false
        loadedPuzzle = false
        puzzleImage = nil
        orderedTiles = nil
        shuffledTiles = nil
    }
    
    @ViewBuilder private func emptyPuzzleView() -> some View {
        VStack {
            if loadingImage {
                Text("Loading...")
                    .bold()
            } else {
                ContentUnavailableView(label: {
                    Text("No Image Selected")
                        .bold()
                }, description: {
                    Text("Click the button below to pick one")
                }, actions: {
                    photoPickerView()
                })
            }
        }
    }
    
    @ViewBuilder private func photoPickerView() -> some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            VStack(spacing: 20) {
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                
            }
            .tint(.primary)
        }
        .onChange(of: selectedPhotoItem, { _, _ in
            Task {
                if let selectedPhotoItem {
                    reset()
                    loadingImage = true
                    loadedPuzzle = false
                    
                    do {
                        
                        let (image, tiles) = try await PuzzleLoader().loadPuzzleFromItem(selectedPhotoItem)
                        puzzleImage = image
                        orderedTiles = tiles.0
                        shuffledTiles = tiles.1
                        
                        loadedPuzzle = true
                    }
                    catch {
                        loadedPuzzle = false
                        print(error.localizedDescription)
                    }
                    
                    loadingImage = false
                }
            }
        })
    }
    
    @ViewBuilder private func footerView() -> some View {
        Group {
            Text("Moves: \(moveCount)")
            HStack(spacing: 15) {
                Text("Change image")
                photoPickerView()
            }
        }
    }
    
    private func tappedTile(row: Int, column: Int) {
        guard var shuffledTiles = shuffledTiles else { return }
        guard shuffledTiles[row][column].isSpareTile == false else { return }
        
        // Check if there is a black tile adjacent to the tapped tile
        if let blackTileIndex = findAdjacentBlackTile(to: (row, column)) {
            // Swap the positions of the tapped tile and the black tile
            moveCount += 1
            let tappedTile = shuffledTiles[row][column]
            shuffledTiles[row][column] = shuffledTiles[blackTileIndex.0][blackTileIndex.1]
            shuffledTiles[blackTileIndex.0][blackTileIndex.1] = tappedTile
            
            self.shuffledTiles = shuffledTiles
            userWon = self.shuffledTiles == orderedTiles
        }
    }
    
    // Find the index of the black tile adjacent to the given tile
    func findAdjacentBlackTile(to tileIndex: (Int, Int)) -> (Int, Int)? {
        let directions: [Direction] = [.up, .down, .left, .right]
        
        for direction in directions {
            let adjacentTileIndex = getAdjacentTileIndex(from: tileIndex, direction: direction)
            if isValidIndex(adjacentTileIndex), shuffledTiles?[adjacentTileIndex.0][adjacentTileIndex.1].isSpareTile ?? false {
                return adjacentTileIndex
            }
        }
        
        return nil
    }

    // Get the index of the tile adjacent to the given tile in the specified direction
    func getAdjacentTileIndex(from tileIndex: (Int, Int), direction: Direction) -> (Int, Int) {
        switch direction {
        case .up:
            return (tileIndex.0 - 1, tileIndex.1)
        case .down:
            return (tileIndex.0 + 1, tileIndex.1)
        case .left:
            return (tileIndex.0, tileIndex.1 - 1)
        case .right:
            return (tileIndex.0, tileIndex.1 + 1)
        }
    }

    // Check if the given tile index is valid
    func isValidIndex(_ tileIndex: (Int, Int)) -> Bool {
        guard let shuffledTiles = shuffledTiles else { return false }
        return tileIndex.0 >= 0 && tileIndex.0 < shuffledTiles.count &&
        tileIndex.1 >= 0 && tileIndex.1 < shuffledTiles[tileIndex.0].count
    }
}

#Preview {
    ContentView()
}
