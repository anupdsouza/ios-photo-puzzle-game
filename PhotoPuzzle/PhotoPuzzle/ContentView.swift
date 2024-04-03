//
//  ContentView.swift
//  PhotoPuzzle
//
//  Created by Anup D'Souza on 02/04/24.
//

import SwiftUI
import PhotosUI

struct Tile {
    let image: UIImage
    let vIndex: Int
    let hIndex: Int
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var croppedImage: UIImage?
    @State private var orderedTiles: [[Tile]]?
    @State private var unorderedTiles: [[Tile]]?
    private let tileSpacing = 5.0
    
    var body: some View {
        VStack {
            if let image = croppedImage {
                Text("Visual Hint")
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
            
            if let orderedTiles {
                GeometryReader { geometry in
                    VStack(spacing: tileSpacing) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: tileSpacing) {
                                ForEach(0..<3, id: \.self) { column in
                                    Image(uiImage: orderedTiles[row][column].image)
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
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.stack.fill")
                    .font(.largeTitle)
            }
            .onChange(of: selectedItem, loadImage)
        }
        .padding()
    }
    
    private func resetUI() {
        croppedImage = nil
        orderedTiles = nil
    }

    private func loadImage() {
        Task {
            resetUI()
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }

            await MainActor.run {
                
                cropImageForPuzzle(image: inputImage)

                if let croppedImage {
                    orderedTiles = tilesFromImage(image: croppedImage, size: CGSize(width: croppedImage.size.width/3, height: croppedImage.size.height/3))
                }
            }
        }
    }
    
    private func cropImageForPuzzle(image: UIImage) {
        let minLength = min(image.size.width, image.size.height)
        let x = image.size.width / 2 - minLength / 2
        let y = image.size.height / 2 - minLength / 2
        let croppingRect = CGRect(x: x, y: y, width: minLength, height: minLength)
        
        if let croppedCGImage = image.cgImage?.cropping(to: croppingRect) {
            croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        }
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
                        tiles[vIndex].append(Tile(image: emptyTileImage, vIndex: vIndex, hIndex: hIndex))
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

    private func scrambleTiles() {

    }

    private func tappedTile(row: Int, column: Int) {
        
    }
}

#Preview {
    ContentView()
}
