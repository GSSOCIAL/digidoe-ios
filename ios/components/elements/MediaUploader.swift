//
//  MediaUploader.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var isPresented: Bool
    var onImport: (URL)->Void = { url in }
    var onError: (Error)->Void = { error in }
    
    func makeCoordinator() -> ImagePickerViewCoordinator {
        return ImagePickerViewCoordinator(isPresented: $isPresented, onImport:self.onImport,onError:self.onError)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = sourceType
        pickerController.delegate = context.coordinator
        return pickerController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update here
    }

}

class ImagePickerViewCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @Binding var isPresented: Bool
    var onImport: (URL)->Void = { url in }
    var onError: (Error)->Void = { error in }
    
    init(isPresented: Binding<Bool>, onImport: @escaping(URL)->Void, onError: @escaping(Error)->Void) {
        self._isPresented = isPresented
        self.onImport = onImport
        self.onError = onError
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL{
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
            
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                do{
                    var filename = "image"
                    if let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL{
                        filename = imageUrl.deletingPathExtension().lastPathComponent
                    }
                    let imagePath = documentsPath?.appendingPathComponent("\(filename).jpg")
                    try! pickedImage.jpegData(compressionQuality: 0.8)?.write(to: imagePath!)
                    self.onImport(imagePath!)
                }catch(let error){
                    
                }
            }
        }
        self.isPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.isPresented = false
    }
    
}

struct MediaUploaderModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onImport: (URL)->Void = { url in }
    var onError: (Error)->Void = { error in }
    var scheme: Color.CustomColorScheme = .auto
    
    @State private var mediaSelection: Bool = false
    @State private var fileSelection: Bool = false
    
    struct MediaUploaderError: Error{
        
    }
    
    var grip: some View{
        Rectangle()
            .frame(maxWidth: 90, maxHeight: 6)
            .background(Color.gray)
            .foregroundColor(Color.gray)
            .clipShape(Capsule())
    }
    
    func overlay(reader: GeometryProxy) -> some View{
        return Rectangle()
            .foregroundColor(Color.white)
            .frame(maxWidth:.infinity,maxHeight: reader.safeAreaInsets.bottom + 15)
            .offset(y: reader.safeAreaInsets.bottom)
    }
    
    func content() -> some View{
        VStack(spacing:10){
            Button{
                self.mediaSelection = true
                self.fileSelection = false
            } label:{
                HStack(alignment:.center){
                    Text(LocalizedStringKey("Select from photos"))
                }
            }
                .buttonStyle(.secondaryNext(image:"camera", scheme: .light))
            
            Button{
                self.fileSelection = true
                self.mediaSelection = false
            } label:{
                HStack(alignment:.center){
                    Text(LocalizedStringKey("Select from files"))
                }
            }
            .buttonStyle(.secondaryNext(image:"document", scheme: .light))
        }
        .padding(.horizontal, 16)
    }
    
    func body(content: Content) -> some View {
        Group{
            GeometryReader{ reader in
                ZStack(alignment:.bottom){
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            self.isPresented = false
                        }
                    Group{
                        self.overlay(reader:reader)
                        self.content()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 0)
                        .padding(.vertical,20)
                        .background(Color.white)
                        .cornerRadius(15)
                        .zIndex(2)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: self.$fileSelection,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: false){ result in
            do {
                let file: URL? = try result.get().first
                if file != nil{
                    self.onImport(file!)
                    self.isPresented = false
                    return
                }
                throw MediaUploaderError()
            } catch let error{
                self.isPresented = false
                self.onError(error)
            }
            DispatchQueue.main.async {
                self.isPresented = false
            }
        }
        .sheet(isPresented: self.$mediaSelection){
            ImagePickerView(
                isPresented: self.$mediaSelection,
                onImport: { url in
                    if url != nil{
                        self.onImport(url)
                        self.isPresented = false
                        return
                    }
                }
            )
        }
    }
}

extension MediaUploaderContainer{
    func present() -> UIViewController{
        let topMostController = topMostController()
        let someView = modifier(MediaUploaderModifier(isPresented: self.$isPresented, onImport: self.onImport, onError: self.onError, scheme: self.scheme))
        let viewController = UIHostingController(rootView: someView)
        viewController.view?.backgroundColor = .clear
        viewController.modalPresentationStyle = .overFullScreen
        topMostController.present(viewController, animated: true)
        self.state.controller = viewController
        return viewController
    }
}

class MediaUploaderState: ObservableObject{
    @Published var visible: Bool = false
    var controller: UIViewController?
}

struct MediaUploaderContainer: View{
    @Binding var isPresented: Bool
    var onImport: (URL)->Void = { url in }
    var onError: (Error)->Void = { error in }
    private var scheme: Color.CustomColorScheme = .auto
    
    @StateObject var state: MediaUploaderState = MediaUploaderState()
    
    init(isPresented: Binding<Bool>, onImport: @escaping (URL)->Void, onError: @escaping (Error)->Void, scheme: Color.CustomColorScheme = .auto){
        _isPresented = isPresented
        self.onImport = onImport
        self.onError = onError
        self.scheme = scheme
    }
    
    func onPresentChanged(){
        if self.isPresented{
            DispatchQueue.main.async {
                self.state.controller = self.present()
            }
        }else{
            DispatchQueue.main.async{
                self.state.controller?.dismiss(animated: false)
            }
        }
    }
    
    var body: some View{
        return ZStack{
            EmptyView().onChange(of: self.isPresented){ change in
                onPresentChanged()
            }
        }
    }
}

struct MediaUploaderPreview: View{
    @State private var presented: Bool = false
    
    var body: some View{
        VStack{
            Button("Uploader"){
                self.presented = true
            }
            MediaUploaderContainer(isPresented: self.$presented,
                                   onImport: {_ in},
                                   onError: { _ in })
        }
    }
}

struct MediaUploaderView_Previews: PreviewProvider {
    static var previews: some View {
        MediaUploaderPreview()
    }
}
