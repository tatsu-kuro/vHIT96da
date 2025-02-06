//
//  iCloudFileManager.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2025/01/29.
//  Copyright © 2025 tatsuaki.kuroda. All rights reserved.
//

import Foundation

class iCloudFileManager {
    private let fileManager = FileManager.default
    
    private var iCloudURL: URL? {
        return fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    func saveText(_ text: String, to fileName: String) {
        guard let iCloudURL = iCloudURL else {
            print("iCloud is not available")
            return
        }
        
        let fileURL = iCloudURL.appendingPathComponent(fileName)
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved: \(fileURL)")
        } catch {
            print("Failed to save file: \(error)")
        }
    }
    
    func loadText(from fileName: String) -> String? {
        guard let iCloudURL = iCloudURL else {
            print("iCloud is not available")
            return nil
        }
        
        let fileURL = iCloudURL.appendingPathComponent(fileName)
        do {
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            return text
        } catch {
            print("Failed to load file: \(error)")
            return nil
        }
    }
}
