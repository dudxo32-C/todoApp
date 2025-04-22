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

typealias TodoGroup = [TodoFilterType: [any TodoModelProtocol]]

enum ToDoListError: Error {
}

enum TodoFilterType {
    case past, today, future
}

class TodoListVM: ViewModelProtocol {
    struct Input {
        let fetchItems: PublishRelay<Void>
        let addItem: PublishRelay<TodoModelProtocol>
        let tapDelete: PublishRelay<TodoModelProtocol>
        let tapFilter: PublishRelay<TodoFilterType>
        let tapDone: PublishRelay<TodoModelProtocol>
    }

    struct Output {
        let isFetching: Driver<Bool>
        let items: Driver<[TodoModelProtocol]>
        let error: Driver<Error?>
    }

    var input: Input
    private var _output: Output?
    var output: Output {
        if let cached = _output {
            return cached
        }

        let new = transform()
        _output = new
        return new
    }

    var disposeBag = DisposeBag()
    let repo = TodoRepo(MockTodoDS())

    private let isfetchingRelay = BehaviorRelay(value: false)
    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private let allItems = BehaviorRelay<[TodoModelProtocol]>(value: [])
    private let cachedGroup = BehaviorRelay<TodoGroup>(value: [:])
    private let selectedFilter: BehaviorRelay<TodoFilterType>

    init(_ selectedFilter: TodoFilterType) {
        self.input = Input(
            fetchItems: PublishRelay(),
            addItem: PublishRelay(),
            tapDelete: PublishRelay(),
            tapFilter: PublishRelay(),
            tapDone: PublishRelay()
        )

        self.selectedFilter = .init(value: selectedFilter)

        bindSelectedFilter()

        bindAllItems()
        bindCacheGroup()
        bindDoneTap()
        
        handleAddItem()
        handleDeleteItem()
    }

    private func transform() -> Output {
        return Output(
            isFetching: isfetchingRelay.asDriver(),
            items: makeItemsDriver(),
            error: errorRelay.asDriver()
        )
    }

    // view 에서 사용할 items
    private func makeItemsDriver() -> Driver<[TodoModelProtocol]> {
        return Observable.combineLatest(
            selectedFilter.asObservable(), cachedGroup.asObservable()
        ).map { (filter, group) in
            return group[filter] ?? []
        }
        .asDriver(onErrorJustReturn: [])
    }

    // MARK: - Binding
    // 탭 클릭 데이터 저장
    private func bindSelectedFilter() {
        input.tapFilter
            .bind(to: self.selectedFilter)
            .disposed(by: disposeBag)
    }

    private func bindCacheGroup() {
        allItems
            .withUnretained(self)
            .map { (vm, items) in vm.makeGroup(items) }
            .bind(to: cachedGroup)
            .disposed(by: disposeBag)
    }

    private func bindAllItems() {
        input.fetchItems
            .withUnretained(self)
            .flatMap { (vm, _) in vm.fetchItems() }
            .subscribe(
                onNext: { value in
                    self.allItems.accept(value)
                },
                onError: { error in
                    self.errorRelay.accept(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func bindDoneTap() {
        input.tapDone
            .withUnretained(self)
            .flatMap { (vm, value) in vm.handleDoneToggle(value) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    // MARK: - handle
    private func handleAddItem() {
        self.input.addItem
            .withUnretained(self)
            .map({ (vm, newItem) in
                let filterType = vm.getDateFilter(newItem)
                let currentArr = vm.cachedGroup.value[filterType] ?? []
                let newArr = currentArr + [newItem]

                return vm.changeGroupItem(items: newArr, type: filterType)
            })
            .bind(to: self.cachedGroup)
            .disposed(by: self.disposeBag)
    }

    private func handleDeleteItem() {
        self.input.tapDelete
            .withUnretained(self)
            .flatMap { $0.deleteTodo(todo: $1) }
            .map { removed in
                let filterType = self.getDateFilter(removed)
                let currentArr = self.cachedGroup.value[filterType] ?? []

                // 삭제된 todo 의 날짜 그룹에서 있는지 확인
                let isHave = currentArr.contains(where: { $0.id == removed.id })

                if isHave {
                    let arr = currentArr.filter {
                        $0.id != removed.id
                    }

                    return self.changeGroupItem(items: arr, type: filterType)

                } else {
                    // 그룹에서 찾아지지 않을경우 전체에서 한번더 검색
                    let arr = self.allItems.value.filter {
                        $0.id != removed.id
                    }

                    // 새롭게 그룹화
                    return self.makeGroup(arr)
                }
            }
            .bind(to: self.cachedGroup)
            .disposed(by: self.disposeBag)
    }

    private func handleDoneToggle(_ todo: TodoModelProtocol) -> Single<[TodoModelProtocol]> {
        let toggled = todo.copyWith(isDone: !todo.isDone)
        
        return updateDone(targetTodo: toggled).map { newValue in
            var currentAll = self.allItems.value
            guard
                let targetIndex = currentAll.firstIndex(where: {
                    $0.id == newValue.id
                })
            else {
                return currentAll
            }
            currentAll[targetIndex] = newValue

            return currentAll
        }
    }

    // MARK: - async
    private func fetchItems() -> Single<[TodoModelProtocol]> {
        self.isfetchingRelay.accept(true)

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
                self?.isfetchingRelay.accept(false)
            }
        }
    }

    private func deleteTodo(todo: TodoModelProtocol) -> Single<
        TodoModelProtocol
    > {
        return .create { [weak self] single in
            guard let self = self else { preconditionFailure("self 가 없습니다") }

            Task {
                do {
                    let _ = try await self.repo.deleteTodo(todo.id)
                    single(.success(todo))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    private func updateDone(targetTodo target: TodoModelProtocol) -> Single<
        TodoModelProtocol
    > {
        return .create { [weak self] single in
            guard let self = self else { preconditionFailure("self 가 없습니다") }

            Task {
                do {
                    let updated = try await self.repo.updateTodo(target)

                    single(.success(updated))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }

    }

    // MARK: -
    private func getDateFilter(_ todo: TodoModelProtocol) -> TodoFilterType {
        let comparison = Calendar.current.compare(
            todo.date, to: Date(), toGranularity: .day)

        switch comparison {
        case .orderedAscending:
            return TodoFilterType.past
        case .orderedSame:
            return TodoFilterType.today
        case .orderedDescending:
            return TodoFilterType.future
        }
    }

    private func changeGroupItem(
        items: [TodoModelProtocol], type: TodoFilterType
    ) -> TodoGroup {
        var currentGroup = self.cachedGroup.value

        currentGroup[type] = items
        return currentGroup
    }

    private func makeGroup(_ items: [TodoModelProtocol]) -> TodoGroup {
        return Dictionary(grouping: items, by: getDateFilter(_:))
    }
}
