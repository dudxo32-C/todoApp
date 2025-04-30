//
//  RxSwiftEX.swift
//  todoApp
//
//  Created by 조영태 on 4/24/25.
//
import RxSwift

extension PrimitiveSequence where Trait == SingleTrait {
    static func async(
        _ factory: @escaping () async throws -> Element
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

            return Disposables.create()
        }
    }
    
    func handleLoadingState(
        _ changeState: @escaping (_ isLoading: Bool) -> Void
    )
        -> Single<Element>
    {
        return self.do(
            onSubscribe: {
                changeState(true)
            },
            onDispose: {
                changeState(false)
            }
        ).debug("loading")
    }
}
