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
    case write(title: String, contents: String, date: Date)
    case delete(id: String)
    case update(
        id: String,
        title: String,
        contents: String,
        isDone: Bool,
        date: Date
    )
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
        case .write(let title, let contents, let date):
            let decodable = TodoRequest.Write(
                title: title,
                date: date,
                contents: contents
            )

            return .requestJSONEncodable(decodable)

        case .delete(let id):
            let encodable = TodoRequest.Delete(id: id)
            return .requestJSONEncodableToQuery(encodable)

        case .update(let id, let title, let contents, let isDone, let date):
            let encodable = TodoRequest.Update(
                id: id,
                title: title,
                contents: contents,
                isDone: isDone,
                date: date
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
        
        case .write(let title, let contents, let date):
            let sample = TodoResponse.Write(
                id: "sample ID",
                title: title,
                date: date,
                contents: contents,
                isDone: false
            )

            return SampleDataFactory.make(sample)

        case .delete(let id):
            return SampleDataFactory.make(TodoResponse.Delete(id: id))

        case .update(let id, let title, let contents, let isDone, let date):
            let sample = TodoResponse.Update(
                id: id,
                title: title,
                date: date,
                contents: contents,
                isDone: isDone
            )
            
            return SampleDataFactory.make(sample)
        }
    }
}
