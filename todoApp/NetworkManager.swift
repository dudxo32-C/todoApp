//
//  NetworkManager.swift
//  todoApp
//
//  Created by 조영태 on 2/25/25.
//

import Combine
import Foundation
import Moya


//
//class NetworkManager<Target: TargetType>: MoyaProvider<Target> {
//    init(
//        endpointClosure: @escaping EndpointClosure = MoyaProvider<Target>
//            .defaultEndpointMapping,
//        requestClosure: @escaping RequestClosure = MoyaProvider<Target>
//            .defaultRequestMapping,
//        environment: APIEnvironment,
//        callbackQueue: DispatchQueue? = nil,
//        session: Session = MoyaProvider<Target>.defaultAlamofireSession(),
//        plugins: [PluginType] = [],
//        trackInflights: Bool = false
//    ) {
//        let stubClosure = {
//            switch environment {
//            case .stub:
//                return MoyaProvider<Target>.delayedStub(2)
//            case .production:
//                return MoyaProvider.neverStub
//            }
//        }()
//
//        super.init(
//            endpointClosure: endpointClosure,
//            requestClosure: requestClosure,
//            stubClosure: stubClosure,
//            callbackQueue: callbackQueue,
//            session: session,
//            plugins: plugins,
//            trackInflights: trackInflights
//        )
//    }
//  
//}

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
