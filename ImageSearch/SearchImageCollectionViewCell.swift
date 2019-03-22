//
//  SearchImageCollectionViewCell.swift
//  ImageSearch
//
//  Created by chloe on 22/03/2019.
//  Copyright © 2019 chloe. All rights reserved.
//

import UIKit
import Kingfisher

class SearchImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    var thumbnailUrl: String? {
        didSet {
            if let urlString = thumbnailUrl, !urlString.isEmpty {
                let url = URL(string: urlString)
                thumbnailImageView.kf.setImage(with: url)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
    }

}
