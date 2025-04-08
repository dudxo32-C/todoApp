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
}

extension TodoAPI: TargetType {
    var method: Moya.Method {
        switch self {
        case .fetchList:
            return .get
        }
    }

    var task: Moya.Task {
        return .requestPlain
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
        }
    }
}
