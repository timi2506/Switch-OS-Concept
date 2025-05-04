//
//  Share.swift
//   SwitchOS
//
//  Created by Tim on 03.05.25.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

func writeDataToTemporaryFile(_ data: Data, filename: String = "ExportedGames.json") throws -> URL {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    try data.write(to: tempURL, options: .atomic)
    return tempURL
}
