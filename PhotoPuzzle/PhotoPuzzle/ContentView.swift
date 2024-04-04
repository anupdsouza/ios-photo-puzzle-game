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
    let vIndex: Int
    let hIndex: Int
    var isSpareTile = false
}

enum Direction {
    case up, down, left, right
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var puzzleImage: UIImage?
    @State private var orderedTiles: [[Tile]]?
    @State private var shuffledTiles: [[Tile]]?
    @State private var userWon = false
    @State private var loadingImage = false
    @State private var moveCount = 0
    private let tileSpacing = 5.0
    
    var body: some View {
        VStack {
            if let puzzleImage {
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
                
                if let shuffledTiles {
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
                }
                
                Spacer()
                
                footerView()
                
            } else {
                emptyPuzzleView()
            }
            
            
        }
        .padding()
    }
    
    private func reset() {
        moveCount = 0
        userWon = false
        puzzleImage = nil
        orderedTiles = nil
        shuffledTiles = nil
    }
    
    @ViewBuilder private func emptyPuzzleView() -> some View {
        VStack {
            ContentUnavailableView(label: {
                Group {
                    if loadingImage {
                        HStack(spacing: 15) {
                            Text(loadingImage ? "Loading..." : "")
                            ProgressView()
                        }
                    } else {
                        Text("No Image Selected")
                    }
                }
                .bold()
            }, description: {
                Text("Click the button below to pick one")
            }, actions: {
                photoPickerView()
            })
        }
    }
    
    @ViewBuilder private func photoPickerView() -> some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            VStack(spacing: 20) {
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                
            }
            .tint(.primary)
        }
        .onChange(of: selectedItem, { _, _ in
            reset()
            loadImage()
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

    private func loadImage() {
        
        loadingImage = true
        
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self),
                  let inputImage = UIImage(data: imageData),
                  let croppedImage = cropImageForPuzzle(image: inputImage) else {
                loadingImage = false
                return
            }
            
            await MainActor.run {
                puzzleImage = croppedImage
                orderedTiles = tilesFromImage(image: croppedImage,
                                              size: CGSize(width: croppedImage.size.width/3, height: croppedImage.size.height/3))
                shuffledTiles = shuffledPuzzleTiles()
                loadingImage = false
            }
        }
    }
    
    private func cropImageForPuzzle(image: UIImage) -> UIImage? {
        let minLength = min(image.size.width, image.size.height)
        let x = image.size.width / 2 - minLength / 2
        let y = image.size.height / 2 - minLength / 2
        let croppingRect = CGRect(x: x, y: y, width: minLength, height: minLength)
        
        if let croppedCGImage = image.cgImage?.cropping(to: croppingRect) {
            return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return nil
    }
    
    private func tilesFromImage(image: UIImage, size: CGSize) -> [[Tile]] {
        let hRowCount = Int(image.size.width / size.width)
        let vRowCount = Int(image.size.height / size.height)
        let tileSideLength = size.width
        
        var tiles = [[Tile]](repeating: [], count: vRowCount)
        for vIndex in 0..<vRowCount {
            for hIndex in 0..<hRowCount {
                if vIndex == vRowCount - 1 && hIndex == hRowCount - 1 { // skip last tile with blank one
                    if let emptyTileImage = UIImage(named: "black") {
                        tiles[vIndex].append(Tile(image: emptyTileImage, vIndex: vIndex, hIndex: hIndex, isSpareTile: true))
                    }
                } else {
                    let imagePoint = CGPoint(x: CGFloat(hIndex) * tileSideLength * -1, y: CGFloat(vIndex) * tileSideLength * -1)
                    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                    image.draw(at: imagePoint)
                    if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                        tiles[vIndex].append(Tile(image: newImage, vIndex: vIndex, hIndex: hIndex))
                    }
                    UIGraphicsEndImageContext()
                }
            }
        }
        
        return tiles
    }

    private func shuffledPuzzleTiles() -> [[Tile]]? {
        if let orderedTiles {
            var iterator = orderedTiles.joined().shuffled().makeIterator()
            return orderedTiles.map { $0.compactMap { _ in iterator.next() }}
        }
        return nil
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
