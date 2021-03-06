//
//  ViewModel.swift
//  task3.1
//
//  Created by Nikita on 14.04.2019.
//  Copyright © 2019 Nikita. All rights reserved.
//

import UIKit

struct CellViewModel {
    let image: UIImage
    let text: String?
    //let text2: String?
}

class ViewModel {
    // MARK: Properties
    
    private let client: APIClient
    private var photos: Photos = [] {
        didSet {
            self.fetchPhoto()
        }
    }
    var cellViewModels: [CellViewModel] = []
    
    // MARK: UI
    
    var isLoading: Bool = false {
        didSet {
            showLoading?()
        }
    }
    var showLoading: (() -> Void)?
    var reloadData: (() -> Void)?
    var showError: ((Error) -> Void)?
    
    init(client: APIClient) {
        self.client = client
    }
    
    func fetchPhotos() {
        if let client = client as? UnsplashClient {
            self.isLoading = true
            let endpoint = UnspashEndpoint.photos(id: UnsplashClient.apiKey, order: .latest)
            client.fetch(with: endpoint) { (either) in
                switch either {
                case .success(let photos):
                    self.photos = photos
                case .error(let error):
                    self.showError?(error)
                }
            }
        }
    }
    
    private func fetchPhoto() {
        let group = DispatchGroup()
        self.photos.forEach { (photo) in
            DispatchQueue.global(qos: .background).async(group: group) {
                group.enter()
                guard let imageData = try? Data(contentsOf: photo.urls.small) else {
                    self.showError?(APIError.imageDownload)
                    group.leave()
                    return
                }
                
                guard let image = UIImage(data: imageData) else {
                    self.showError?(APIError.imageConvert)
                    group.leave()
                    return
                }
                
                guard let textData = photo.links.download else {
                    self.showError?(APIError.text)
                    group.leave()
                    return
                }
                
                /*
                guard let textData = photo.alt_description, photo.alt_description != nil else {
                    self.showError?(APIError.text)
                    group.leave()
                    return
                }
                //"Just Some Picture Without Description"
                */
                
                self.cellViewModels.append(CellViewModel(image: image, text: textData))
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("here")
            self.isLoading = false
            self.reloadData?()
        }
    }
    
    
}













