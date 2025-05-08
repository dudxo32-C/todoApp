//
//  TodoTarget.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation
import Moya

final class SampleDataLoader {
    static func loadJSON(named fileName: String) -> Data {
        guard
            let url = Bundle.main.url(
                forResource: fileName, withExtension: "json")
        else {
            fatalError("Missing file: \(fileName).json")
        }
        return try! Data(contentsOf: url)
    }
}

enum TodoAPI {
    case fetchList
    case write(todo: TodoModelProtocol)
    case delete(id: String)
    case update(todo: TodoModelProtocol)

}

extension TodoAPI: TargetType {
    var method: Moya.Method {
        switch self {
        case .fetchList:
            return .get
        case .write(let todo):
            return .post
        case .delete(let id):
            return .delete
        case .update(let todo):
            return .put
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchList:
            return .requestPlain
        case .write(let todo):
            return .requestParameters(
                parameters: [
                    "id": todo.id,
                    "title": todo.title,
                    "completed": todo.isDone,
                    "date": todo.date,
                    "contents": todo.contents,
                ], encoding: URLEncoding.httpBody
            )
        case .delete(let id):
            return .requestParameters(
                parameters: ["id": id],
                encoding: URLEncoding.queryString
            )
        case .update(let todo):
            return .requestParameters(
                parameters: [
                    "id": todo.id,
                    "title": todo.title,
                    "completed": todo.isDone,
                    "date": todo.date,
                    "contents": todo.contents,
                ], encoding: URLEncoding.queryString
            )
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
        case .write(let todo):
            return "write"
        case .delete(let id):
            return "delete"
        case .update(let todo):
            return "update"
        }
    }

    var sampleData: Data {
        switch self {
        case .fetchList:
            return SampleDataLoader.loadJSON(named: "fetch")
        case .write(let todo):
            return try! JSONSerialization.data(withJSONObject: todo)
        case .delete(let id):
            return try! JSONSerialization.data(withJSONObject: ["id": id])
        case .update(let todo):
            return try! JSONSerialization.data(withJSONObject: todo)
        }
    }
}
