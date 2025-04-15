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
}

class MainViewModel: ViewModelProtocol {
    struct Input {
        let fetchItems: PublishRelay<Void>
        let addItem: PublishRelay<TodoModelProtocol>
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
            fetchItems: PublishRelay(),
            addItem: PublishRelay(),
            tapDelete: PublishRelay()
        )

        self.output = Output(
            isFetching: self.loadingRelay.asDriver(),
            items: itemsRelay.asDriver(),
            error: errorRelay.asDriver()
        )

        handleFetch()
        handleAddItem()
        handleDelete()
    }

    private func handleFetch() {
        input.fetchItems
            .flatMap { [weak self] _ in
                self?.fetchItems() ?? Single<[TodoModelProtocol]>.just([])
            }
            .subscribe(
                onNext: { value in
                    print(value)
                    self.itemsRelay.accept(value)
                },
                onError: { error in
                    self.errorRelay.accept(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func fetchItems() -> Single<[TodoModelProtocol]> {
        self.loadingRelay.accept(true)

        return .create { [weak self] single in
            Task {
                guard let self = self else {
                    preconditionFailure("self 가 없습니다")
                }

                do {
                    let response = try await self.repo.fetchTodoList()
                    single(.success(response))

                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                self?.loadingRelay.accept(false)
            }
        }
    }

    private func handleAddItem() {
        self.input.addItem
            .map { newItem in
                let arr = self.itemsRelay.value + [newItem]
                print(arr)
                return arr
            }
            .bind(to: itemsRelay)
            .disposed(by: disposeBag)
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
