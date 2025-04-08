//
//  NetworkManager.swift
//  todoApp
//
//  Created by 조영태 on 2/25/25.
//

import Combine
import Foundation
import Moya

public enum APIEnvironment {
    case mock
    case production
}

enum NetworkError : Error {
    case DecodedFailed
}

class NetworkManager<Target: TargetType>: MoyaProvider<Target> {
    init(
        endpointClosure: @escaping EndpointClosure = MoyaProvider<Target>
            .defaultEndpointMapping,
        requestClosure: @escaping RequestClosure = MoyaProvider<Target>
            .defaultRequestMapping,
        environment: APIEnvironment,
        callbackQueue: DispatchQueue? = nil,
        session: Session = MoyaProvider<Target>.defaultAlamofireSession(),
        plugins: [PluginType] = [],
        trackInflights: Bool = false
    ) {
        let stubClosure = {
            switch environment {
            case .mock:
                return MoyaProvider<Target>.delayedStub(2)
            case .production:
                return MoyaProvider.neverStub
            }
        }()

        super.init(
            endpointClosure: endpointClosure,
            requestClosure: requestClosure,
            stubClosure: stubClosure,
            callbackQueue: callbackQueue,
            session: session,
            plugins: plugins,
            trackInflights: trackInflights
        )
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

//struct APIService {
//    private let provider: MoyaProvider<TodoAPI>
//
//    init(environment: APIEnvironment) {
//        switch environment {
//        case .mock:
//            self.provider = MoyaProvider<TodoAPI>(stubClosure: MoyaProvider.immediatelyStub)
//        case .production:
//            self.provider = MoyaProvider<TodoAPI>()
//        }
//    }
//
//    func fetchUser(completion: @escaping (Result<String, Error>) -> Void) {
//        provider.request(.fetchList) { result in
//            switch result {
//            case .success(let response):
//                let dataString = String(data: response.data, encoding: .utf8)
//                completion(.success(dataString ?? "Invalid JSON"))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//}
