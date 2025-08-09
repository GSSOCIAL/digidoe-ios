//
//  ShareSheet.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 23.12.2023.
//

import Foundation
import SwiftUI
import LinkPresentation

import LinkPresentation
import UniformTypeIdentifiers

class MyActivityItemSource: NSObject, UIActivityItemSource {
    var title: String
    var subtitle: URL? = nil
    var data: Data
    var filetype: String? = nil
    
    init(
        title: String,
        subtitle: URL?,
        data: Data,
        filetype: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.data = data
        self.filetype = filetype
        
        super.init()
    }
    
    //Retrieve share title
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.title
    }
    
    //IDK
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.data
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()

        //metadata.iconProvider = NSItemProvider(object: UIImage(named: "logo_simple")!)
        metadata.title = title
        
        if let subtitle = subtitle {
            metadata.originalURL = subtitle
        }

        return metadata
    }
    
    //Format type
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        //return UTType.png.identifier
        return self.filetype ?? ""
    }
    
    /*
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .airDrop {
            return self.data
        } else {
            return self.data
        }
    }*/
}

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: []
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}
