//
//  NetworkEX.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import Moya

extension MoyaProvider {
    static func makeProvider(for environment: APIEnvironment) -> MoyaProvider<
        Target
    > {
        switch environment {
        case .production:
            return MoyaProvider<Target>()
        case .stub:
            return MoyaProvider<Target>(
                stubClosure: MoyaProvider.delayedStub(1)
            )
        case .local:
            assertionFailure("local environment not supported")
            return MoyaProvider<Target>()
        }
    }

    func request(_ target: Target) async -> Result<Response, MoyaError> {
        await withCheckedContinuation { continuation in
            self.request(target) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

extension Response {
    func toDecoded<R: Decodable>(type: R.Type) throws -> R {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let decoded = try decoder.decode(R.self, from: self.data)

            return decoded
        } catch {
            throw NetworkError.DecodedFailed
        }
    }
}

extension _Concurrency.Task where Success == Never, Failure == Never {
    static func delayTwoSecond() async throws {
        try await _Concurrency.Task<Success, Failure>.sleep(for: .seconds(2))
    }
}

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any] else {
            throw NetworkError.DictionaryFailed
        }

        return dictionary
    }
}

extension Task {
    static func requestJSONEncodableToQuery(_ encodable: (any Encodable))
        -> Task
    {
        do {
            let param = try encodable.toDictionary()

            return .requestParameters(
                parameters: param,
                encoding: URLEncoding.queryString
            )
        } catch {
            assertionFailure(error.localizedDescription)
            return .requestPlain
        }
    }
}

struct SampleDataFactory {
    private init() {}
    
    static func make<T: Encodable>(_ value: T) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            return try encoder.encode(value)
        } catch {
            assertionFailure("sample data encoding error")
            return Data()
        }
    }

    static func makeRaw(_ dict: [String: Any]) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: dict)
        } catch {
            assertionFailure("sample data encoding error")
            return Data()
        }
    }

    static func loadJSONFile(named fileName: String) -> Data {
        guard
            let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "json"
            )
        else {
            fatalError("Missing file: \(fileName).json")
        }
        return try! Data(contentsOf: url)
    }
}
