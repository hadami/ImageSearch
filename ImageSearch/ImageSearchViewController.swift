//
//  ImageSearchViewController.swift
//  ImageSearch
//
//  Created by chloe on 21/03/2019.
//  Copyright © 2019 chloe. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit

class ImageSearchViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var emptyLabel: UILabel!
    fileprivate var indicator: UIActivityIndicatorView!
    
    var keyword: Variable<String> = Variable<String>("")
    var currentPage: Variable<Int> = Variable<Int>(0)
    var isEmpty: Variable<Bool> = Variable<Bool>(false)
    let disposeBag = DisposeBag()
    
    fileprivate var searchImages: [SearchImage]? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let wself = self else { return }
                wself.collectionView.reloadData()
            }
        }
    }
    fileprivate var pageInfo: PageInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        indicator = UIActivityIndicatorView(style: .gray)
        indicator.isHidden = true
        collectionView.addSubview(indicator)
        indicator.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        collectionView.register(UINib(nibName: "SearchImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "SearchImageCollectionViewCell")
        
        setup()
    }
    
    func setup() {
        searchBar
            .rx.text
            .orEmpty
            .debounce(1.0, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] query in
                guard let wself = self else { return }
                
                wself.searchImages = nil
                wself.pageInfo = nil
                wself.currentPage.value = 1
                wself.keyword.value = query
                wself.fetchImageSearch()
            })
            .disposed(by: disposeBag)
        
        currentPage
            .asObservable()
            .debounce(0.1, scheduler: MainScheduler.instance)
            .filter{ $0 > 1 }
            .subscribe(onNext: { [weak self] page in
                guard let wself = self else { return }
                
                wself.fetchImageSearch()
            })
            .disposed(by: disposeBag)
        
        isEmpty
            .asObservable()
            .subscribe(onNext: { [weak self] empty in
                guard let wself = self else { return }
                wself.checkEmptyLabel(isHidden: !empty)
            })
            .disposed(by: disposeBag)
        
        collectionView
            .rx.willDisplayCell
            .subscribe(onNext: { [weak self] (cell, indexPath)  in
                if let wself = self, let count = wself.searchImages?.count, count == (indexPath.row + 1) {
                    wself.currentPage.value = wself.currentPage.value + 1
                }
            })
            .disposed(by: disposeBag)
    }
    
    func fetchImageSearch() {
        if let isEnd = pageInfo?.isEnd, isEnd || currentPage.value > 50 { return }
        
        checkIndicator(isHidden: false)
        API.shared.searchImage(withKeyword: keyword.value, page: currentPage.value) { [weak self] (error, images, info) in
            guard let wself = self else { return }
            
            if let error = error {
                wself.checkError(withMessage: error.localizedDescription)
                
            } else if let images = images {
                if wself.currentPage.value == 1 {
                    wself.searchImages = images
                    wself.isEmpty.value = images.count == 0
                    wself.scrollToTop()
                } else {
                    wself.searchImages?.append(contentsOf: images)
                }
                wself.pageInfo = info
            }
            
            wself.checkIndicator(isHidden: true)
        }
    }
    
    func scrollToTop() {
        DispatchQueue.main.async { [weak self] in
            guard let wself = self else { return }
            wself.collectionView.setContentOffset(CGPoint(x: 0, y: -wself.collectionView.contentInset.top), animated: true)
        }
    }
    
    func checkError(withMessage message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] (action) in
            guard let _ = self else { return }
        }
        
        alertController.addAction(confirmAction)
        DispatchQueue.main.async { [weak self] in
            guard let wself = self else { return }
            wself.present(alertController, animated: true, completion: nil)
        }
    }
    
    func checkEmptyLabel(isHidden: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let wself = self else { return }
            
            wself.emptyLabel.isHidden = isHidden
        }
    }
    
    func checkIndicator(isHidden: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let wself = self else { return }
            
            wself.indicator.isHidden = isHidden
            if isHidden {
                wself.indicator.stopAnimating()
            } else {
                wself.indicator.startAnimating()
            }
        }
    }
}

extension ImageSearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let image = searchImages?[indexPath.row], let w = image.width, let h = image.height else {
            return .zero
        }
        let ratio = h / w
        let width = UIScreen.main.bounds.width
        let height = width * ratio
        
        return CGSize(width: width, height: height)
    }
}

extension ImageSearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchImages?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchImageCollectionViewCell", for: indexPath) as? SearchImageCollectionViewCell, let thumbnailUrl = searchImages?[indexPath.row].thumbnailUrl {
            cell.thumbnailUrl = thumbnailUrl
            
            return cell
        }
        return UICollectionViewCell()
    }
}
