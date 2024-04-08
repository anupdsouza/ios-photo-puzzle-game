//
//  PuzzleLoader.swift
//  PhotoPuzzle
//
//  Created by Anup D'Souza on 08/04/24.
//

import Foundation
import PhotosUI
import SwiftUI

struct PuzzleLoader {
    func loadPuzzleFromItem(_ photoItem: PhotosPickerItem) async throws -> (UIImage, ([[Tile]], [[Tile]])) {
        guard let imageData = try await photoItem.loadTransferable(type: Data.self) else {
            throw NSError(domain: "Error loading photo item from library", code: 0, userInfo: nil)
        }
        
        guard let inputImage = UIImage(data: imageData),
              let croppedImage = cropImageForPuzzle(image: inputImage) else {
            throw NSError(domain: "Error loading image", code: 0, userInfo: nil)
        }

        let tiles = tilesFromImage(image: croppedImage,
                                   size: CGSize(width: croppedImage.size.width/3, height: croppedImage.size.height/3))
        return (croppedImage, tiles)
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
    
    private func tilesFromImage(image: UIImage, size: CGSize) -> ([[Tile]], [[Tile]]) {
        let hRowCount = Int(image.size.width / size.width)
        let vRowCount = Int(image.size.height / size.height)
        let tileSideLength = size.width
        
        var tiles = [[Tile]](repeating: [], count: vRowCount)
        for vIndex in 0..<vRowCount {
            for hIndex in 0..<hRowCount {
                if vIndex == vRowCount - 1 && hIndex == hRowCount - 1 { // skip last tile with blank one
                    if let emptyTileImage = UIImage(named: "black") {
                        tiles[vIndex].append(Tile(image: emptyTileImage, isSpareTile: true))
                    }
                } else {
                    let imagePoint = CGPoint(x: CGFloat(hIndex) * tileSideLength * -1, y: CGFloat(vIndex) * tileSideLength * -1)
                    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                    image.draw(at: imagePoint)
                    if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                        tiles[vIndex].append(Tile(image: newImage))
                    }
                    UIGraphicsEndImageContext()
                }
            }
        }
        
        var iterator = tiles.joined().shuffled().makeIterator()
        let shuffledTiles = tiles.map { $0.compactMap { _ in iterator.next() }}
        return (tiles, shuffledTiles)
    }
}