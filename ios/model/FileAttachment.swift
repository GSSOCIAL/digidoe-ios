//
//  FileAttachment.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

final class FileAttachment: Identifiable{
    var data: Data
    var url: URL?
    
    var fileName: String?
    var fileType: mimeTypesLabel?
    
    public var uploaded: Bool = false
    public var documentType: UploadIdentityView.DocumentType? = nil
    public var key: String = ""
    public var documentId: String? = nil
    
    enum mimeType:String, CaseIterable{
        case png = "image/png"
        case jpg =  "image/jpg"
        case jpeg = "image/jpeg"
        case pdf = "application/pdf"
        case txt = "text/plain"
        case stream = "application/octet-stream"
        case gif = "image/gif"
        case tiff = "image/tiff"
        case vnd = "application/vnd"
        case empty = ""
        
        static func withLabel(_ label: String) -> FileAttachment.mimeType? {
            return self.allCases.first{ "\($0)" == label }
        }
    }
    
    enum mimeTypesLabel: String, CaseIterable{
        case png
        case jpg
        case jpeg
        case pdf
        case txt
        case stream
        case gif
        case tiff
        case vnd
        case empty
        
        static func withLabel(_ label: String) -> FileAttachment.mimeTypesLabel? {
            return self.allCases.first{ "\($0)" == label }
        }
    }
    
    init(data: Data){
        self.data = data
        self.fileType = self.mimeTypeForData(for: self.data)
    }
    
    init(url: URL){
        self.url = url
        self.data = Data()
        self.fileName = url.lastPathComponent
        do{
            url.startAccessingSecurityScopedResource()
            self.data = try Data(contentsOf: url)
            //self.fileType = self.mimeTypeForData(for: self.data)
            self.fileType = self.mimeTypeFromUrl(for: url)
        }catch(let error){
            #if DEBUG
            print("Unable to parse image from url")
            #endif
        }
    }
    
    init(filename: String){
        self.data = Data()
        self.fileName = filename
        self.fileType = .empty
    }
    
    func mimeTypeForData(for data: Data) -> FileAttachment.mimeTypesLabel?{
        var b: UInt8 = 0
        data.copyBytes(to: &b, count: 1)
        
        switch b {
        case 0xFF:
            return .jpeg
        case 0x89:
            return .png
        case 0x25:
            return .pdf
        case 0x46:
            return .txt
        default:
            return .stream
        }
    }
    
    func mimeTypeFromUrl(for url: URL) -> FileAttachment.mimeTypesLabel?{
        var pathExtension: String? = url.pathExtension
        
        switch(pathExtension){
            case "pdf":
                return .pdf
            case "jpeg", "jpg":
                return .jpeg
            case "png":
                return .png
            default:
                break
        }
        return nil
    }
}
