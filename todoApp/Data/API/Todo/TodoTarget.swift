//
//  TodoTarget.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation
import Moya

enum TodoAPI {
    case fetchList
    case write(_ request:TodoRequest.Write)
    case delete(_ request:TodoRequest.Delete)
    case update(_ request:TodoRequest.Update)
}

extension TodoAPI: TargetType {
    var method: Moya.Method {
        switch self {
        case .fetchList:
            return .get
        case .write:
            return .post
        case .delete:
            return .delete
        case .update:
            return .put
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchList:
            return .requestPlain
        
        case .write(let request):
            return .requestJSONEncodable(request)

        case .delete(let request):
            return .requestJSONEncodableToQuery(request)

        case .update(let request):
            let encodable = TodoRequest.Update(
                id: request.id,
                title: request.title,
                contents: request.contents,
                isDone: request.isDone,
                date: request.date
            )

            return .requestJSONEncodableToQuery(encodable)
        }
    }

    var headers: [String: String]? {
        return [:]
    }

    var baseURL: URL {
        URL(string: "https://mocking.com")!
    }

    var path: String {
        switch self {
        case .fetchList:
            return "todos"
        case .write:
            return "write"
        case .delete:
            return "delete"
        case .update:
            return "update"
        }
    }

    var sampleData: Data {
        switch self {
        case .fetchList:
            return SampleDataFactory.loadJSONFile(named: "fetch")
        
        case .write(let request):
            let sample = TodoResponse.Write(
                id: "sample ID",
                title: request.title,
                date: request.date,
                contents: request.contents,
                isDone: false
            )

            return SampleDataFactory.make(sample)

        case .delete(let request):
            return SampleDataFactory.make(request)

        case .update(let request):
            let sample = TodoResponse.Update(
                id: request.id,
                title: request.title,
                date: request.date,
                contents: request.contents,
                isDone: request.isDone
            )
            
            return SampleDataFactory.make(sample)
        }
    }
}
