//
//  ViewModelProtocol.swift
//  todoApp
//
//  Created by 조영태 on 2022/10/03.
//

import Foundation
import RxRelay
import RxSwift
import RxCocoa

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output

    var input: Input { get }
    var output: Output { get }
    var disposeBag: DisposeBag { get set }
}

// MARK: - 재시도 요청 프로토콜
enum RetryAction { case retry, none }

// 재시도 요청 input protocol
protocol CommonRetryInput {
    var retryTrigger: PublishRelay<RetryAction> { get }
}

protocol RetryProtocol: ViewModelProtocol where Input: CommonRetryInput {}

extension RetryProtocol {
    func handelRetry(_ error: Error) -> Observable<Void> {
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

// MARK: - 로딩 인디케이터 프로토콜
protocol LoadingOutput {
    var isLoading: Driver<Bool> { get }
}

protocol LoadingProtocol: ViewModelProtocol where Output: LoadingOutput {}
