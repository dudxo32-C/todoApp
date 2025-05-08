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
    case write(title:String, contents:String, date:Date)
    case delete(id: String)
    case update(
        id:String,
        title:String,
        contents:String,
        isDone:Bool,
        date:Date
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
            return .requestParameters(
                parameters: [
                    "title": title,
                    "date": date,
                    "contents": contents,
                ], encoding: URLEncoding.httpBody
            )
        case .delete(let id):
            return .requestParameters(
                parameters: ["id": id],
                encoding: URLEncoding.queryString
            )
        case .update(let id, let title,let contents,let isDone,let date):
            return .requestParameters(
                parameters: [
                    "id": id,
                    "title": title,
                    "completed": isDone,
                    "date": date,
                    "contents": contents,
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
            return SampleDataLoader.loadJSON(named: "fetch")
        case .write(let title, let contents, let date):
            let data = [
                "id":"smaple ID",
                "title":title,
                "isDone":false,
                "date":date.description,
                "contents":contents
            ] as [String : Any]
            
            return try! JSONSerialization.data(withJSONObject: data)
        case .delete(let id):
            return try! JSONSerialization.data(withJSONObject: ["id": id])
            
        case .update(let id, let title,let contents,let isDone,let date):
            let data = [
                "id":id,
                "title":title,
                "isDone":isDone,
                "date":date.description,
                "contents":contents
            ] as [String : Any]
            
            return try! JSONSerialization.data(withJSONObject: data)
        }
    }
}
