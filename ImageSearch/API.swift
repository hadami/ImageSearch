//
//  API.swift
//  ImageSearch
//
//  Created by chloe on 22/03/2019.
//  Copyright © 2019 chloe. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class SearchImage: Mappable {
    var thumbnailUrl: String?
    var height: CGFloat?
    var width: CGFloat?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        thumbnailUrl    <- map["image_url"]
        height          <- map["height"]
        width           <- map["width"]
    }
}

class PageInfo: Mappable {
    var isEnd: Bool?
    var pageableCount: Int?
    var totalCount: Int?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        isEnd           <- map["is_end"]
        pageableCount   <- map["pageable_count"]
        totalCount      <- map["total_count"]
    }
}

class API: NSObject {
    static var shared: API {
        struct Static {
            static let instance = API()
        }
        return Static.instance
    }
    
    func searchImage(withKeyword query: String, sort: String = "accuracy", page: Int = 1, size: Int = 20, callback: ((_ error: Error?, _ images: [SearchImage]?, _ info: PageInfo?) -> Void)? ) {
        let parameters: Parameters = [
            "query": query,
            "sort": sort, // accuracy or recency
            "page": page, // default: 1 (1~50)
            "size": size // default: 80 (1~80)
        ]
        let headers: HTTPHeaders = [
            "Authorization": "KakaoAK a441c5a9474d338329c840945a5da4c1"
        ]
        let utilityQueue = DispatchQueue.global(qos: .utility)
        
        AF.request("https://dapi.kakao.com/v2/search/image",
                   method: .get,
                   parameters: parameters,
                   encoding: URLEncoding.default,
                   headers: headers,
                   interceptor: nil)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON(queue: utilityQueue) { response in
                var error: Error?
                var images: [SearchImage]?
                var info: PageInfo?
                
                switch response.result {
                case .success:
                    if let JSON = response.result.value as? [String: Any] {
                        images = Mapper<SearchImage>().mapArray(JSONObject:JSON["documents"])
                        info = Mapper<PageInfo>().map(JSONObject:JSON["meta"])
                    }
                case .failure(let err):
                    error = err
                    debugPrint(err)
                }
                
                if let cb = callback {
                    cb(error, images, info)
                }
        }
    }
}
