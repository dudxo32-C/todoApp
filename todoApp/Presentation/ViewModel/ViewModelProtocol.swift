//
//  ViewModelProtocol.swift
//  todoApp
//
//  Created by 조영태 on 2022/10/03.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

protocol ViewModelProtocol: AnyObject {
    associatedtype Input
    associatedtype State
    associatedtype UseCase

    var input: Input { get }
    var state: State { get }
    var disposeBag: DisposeBag { get set }
}

// MARK: - 재시도 요청 프로토콜
enum RetryAction { case retry, none }

// 재시도 요청 input protocol
protocol RetryInput {
    var retryTrigger: PublishRelay<RetryAction> { get }
}

protocol RetryProtocol: ViewModelProtocol where Input: RetryInput {}

extension RetryProtocol {
    func handelRetry(
        from error: Observable<Error>, in store: PublishRelay<Error?>
    ) -> Observable<Void> {
        return error
            .do{ error in store.accept(error) }
            .withUnretained(self)
            .flatMap { (self, error) in
                return self.input.retryTrigger
                    .flatMap { action in
                        switch action {
                        case .retry:
                            return Observable.just(())

                        case .none:
                            return Observable.error(error)
                        }
                    }
            }
    }
}

// MARK: - 로딩 인디케이터 프로토콜
protocol LoadingState {
    var isLoading: Driver<Bool> { get }
}

protocol LoadingProtocol: ViewModelProtocol where State: LoadingState {}

extension PrimitiveSequence where Trait == SingleTrait {
    func handleLoadingState(
        to changeState: BehaviorRelay<Bool>
    ) -> Single<Element> {
        return self.do(
            onSubscribe: {
                changeState.accept(true)
            },
            onDispose: {
                changeState.accept(false)
            }
        )
    }
}
