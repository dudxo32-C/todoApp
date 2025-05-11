//
//  Constant.swift
//  todoApp
//
//  Created by 조영태 on 2022/09/25.
//

import Foundation

let C_margin16 = 16

/// Data 환경
enum DataEnvironment: String {
    case stub = "stub"
    case local = "local"
    case production = "production"
}

public enum APIEnvironment {
    case stub
    case local
    case production
}

enum NetworkError : Error {
    case DecodedFailed
}
