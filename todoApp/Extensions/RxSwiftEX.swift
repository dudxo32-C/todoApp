//
//  RxSwiftEX.swift
//  todoApp
//
//  Created by 조영태 on 4/24/25.
//
import RxSwift

import Foundation

extension Single {
    static func async(
        _ factory: @escaping () async throws -> Element,
        onDispose: (() -> Void)? = nil
    )
        -> Single<Element>
    {
        return Single.create { single in
            Task {
                do {
                    let result = try await factory()
                    single(.success(result))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                onDispose?()
            }
        }
    }
}
