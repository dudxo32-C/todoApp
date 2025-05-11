//
//  NetworkEX.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import Moya

extension MoyaProvider {
    static func makeProvider(for environment: APIEnvironment) -> MoyaProvider<Target> {
        switch environment {
        case .production:
            return MoyaProvider<Target>()
        case .stub:
            return MoyaProvider<Target>(
                stubClosure: MoyaProvider.immediatelyStub
            )
        case .local:
            assertionFailure("local environment not supported")
            return MoyaProvider<Target>()
        }
    }
}

extension Response {
    func toDecoded<R:Decodable>(type:R.Type) throws -> R {
        do {
            let decoded = try JSONDecoder().decode(R.self, from: self.data)
            return decoded
        } catch {
            throw NetworkError.DecodedFailed
        }
    }
}


extension MoyaProvider {
    func request(_ target: Target) async -> Result<Response, MoyaError> {
        await withCheckedContinuation { continuation in
            self.request(target) { result in
                continuation.resume(returning: result)
            }
        }
    }
}



extension _Concurrency.Task where Success == Never, Failure == Never {
    static func delayTwoSecond() async throws {
        try await _Concurrency.Task<Success, Failure>.sleep(for: .seconds(2))
    }
}
