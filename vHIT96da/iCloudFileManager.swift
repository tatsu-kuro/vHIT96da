//
//  iCloudFileManager.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2025/01/29.
//  Copyright © 2025 tatsuaki.kuroda. All rights reserved.
//

import Foundation

class iCloudFileManager {
    
    /// iCloudのコンテナURLを取得
    private func getUbiquityURL() -> URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    /// iCloudにテキストファイルを保存
    func saveTextFile(fileName: String, content: String, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let iCloudURL = self.getUbiquityURL() else {
                completion(false, NSError(domain: "iCloudError", code: 1, userInfo: [NSLocalizedDescriptionKey: "iCloudが有効ではありません。"]))
                return
            }
            
            let fileURL = iCloudURL.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }
    
    /// iCloudからテキストファイルを読み込む
    func loadTextFile(fileName: String, completion: @escaping (String?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let iCloudURL = self.getUbiquityURL() else {
                completion(nil, NSError(domain: "iCloudError", code: 1, userInfo: [NSLocalizedDescriptionKey: "iCloudが有効ではありません。"]))
                return
            }
            
            let fileURL = iCloudURL.appendingPathComponent(fileName)
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                completion(content, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    /// iCloud内のファイル一覧を取得
     func listFiles(completion: @escaping ([String]?, Error?) -> Void) {
         DispatchQueue.global(qos: .background).async {
             guard let iCloudURL = self.getUbiquityURL() else {
                 completion(nil, NSError(domain: "iCloudError", code: 1, userInfo: [NSLocalizedDescriptionKey: "iCloudが有効ではありません。"]))
                 return
             }
             
             do {
                 let fileList = try FileManager.default.contentsOfDirectory(atPath: iCloudURL.path)
                 completion(fileList, nil)
             } catch {
                 completion(nil, error)
             }
         }
     }
     
     /// iCloudからファイルを削除
     func deleteFile(fileName: String, completion: @escaping (Bool, Error?) -> Void) {
         DispatchQueue.global(qos: .background).async {
             guard let iCloudURL = self.getUbiquityURL() else {
                 completion(false, NSError(domain: "iCloudError", code: 1, userInfo: [NSLocalizedDescriptionKey: "iCloudが有効ではありません。"]))
                 return
             }
             
             let fileURL = iCloudURL.appendingPathComponent(fileName)
             
             do {
                 try FileManager.default.removeItem(at: fileURL)
                 completion(true, nil)
             } catch {
                 completion(false, error)
             }
         }
     }
}

