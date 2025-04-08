//
//  f.swift
//  todoApp
//
//  Created by 조영태 on 2/26/25.
//

import Foundation
import Moya

public protocol ResponseTargetType1: TargetType {
    associatedtype ResponseType: Decodable
    var responseType: ResponseType.Type { get }
    func response(from data: Data) throws -> ResponseType?
}

// 제네릭을 사용하여 각 케이스에 맞는 타입을 지정
enum TodoAPI1<T: Decodable> {
    case fetchList
}

extension TodoAPI1: ResponseTargetType {
    var baseURL: URL {
        <#code#>
    }
    
    var path: String {
        <#code#>
    }
    
    var method: Moya.Method {
        <#code#>
    }
    
    var task: Moya.Task {
        <#code#>
    }
    
    var headers: [String : String]? {
        <#code#>
    }
    
    
    // `ResponseType`을 제네릭으로 처리
    var responseType: T.Type {
        switch self {
        case .fetchList:
            return FetchListResponseDto.self as! T.Type
        }
    }

    func response(from data: Data) throws -> T? {
        return try JSONDecoder().decode(responseType, from: data)
    }
}

// 사용 예시
let fetchListAPI = TodoAPI1<FetchListResponseDto>.fetchList

let apiProvider = APIProvider<TodoAPI>( environment: .mock)

// `fetchListAPI`를 사용하여 응답을 받음
var eeee = apiProvider.requestPublisher1(fetchListAPI)
