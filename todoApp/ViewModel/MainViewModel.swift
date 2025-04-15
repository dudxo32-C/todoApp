//
//  MainViewModel.swift
//  todoApp
//
//  Created by 조영태 on 2022/10/03.
//

import Foundation
import RealmSwift
import RxCocoa
import RxRelay
import RxSwift

enum ToDoListError: Error {
//    case noItems
}

class MainViewModel: ViewModelProtocol {
    struct Input {
        let tapDelete: PublishRelay<TodoModelProtocol>
    }
    struct Output {
        let isFetching: Driver<Bool>
        let items: Driver<[TodoModelProtocol]>
        let error: Driver<Error?>
    }

    var input: Input
    let output: Output

    var disposeBag = DisposeBag()
    let repo = TodoRepo(MockTodoDS())

    private let loadingRelay = BehaviorRelay(value: false)
    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private let itemsRelay = BehaviorRelay<[TodoModelProtocol]>(value: [])
    
    init() {
        self.input = Input(
            tapDelete: PublishRelay()
        )

        self.output = Output(
            isFetching: self.loadingRelay.asDriver(),
            items: itemsRelay.asDriver(),
            error: errorRelay.asDriver()
        )

        fetch()

        handleDelete()
    }

    func fetch() {
        Task {
            self.loadingRelay.accept(true)

            do {
                let response = try await repo.fetchTodoList()
                self.itemsRelay.accept(response)
            } catch {
                self.errorRelay.accept(error)
            }

            self.loadingRelay.accept(false)
        }
    }

    func createTodoListItem(todo: TodoModelProtocol) {
        let arr = self.itemsRelay.value + [todo]
        self.itemsRelay.accept(arr)
    }

    private func handleDelete() {
        self.input.tapDelete
            .flatMap { self.deleteTodo(todo: $0) }
            .map { removedID in
                let arr = self.itemsRelay.value.filter {
                    $0.id != removedID
                }

                return arr
            }
            .bind(to: self.itemsRelay)
            .disposed(by: self.disposeBag)
    }

    private func deleteTodo(todo: TodoModelProtocol) -> Single<String> {
        return .create { [weak self] single in
            guard let self = self else { preconditionFailure("self 가 없습니다") }

            Task {
                do {
                    let id = try await self.repo.deleteTodo(todo.id)
                    single(.success(id))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }
}
