//
//  MainViewModel.swift
//  todoApp
//
//  Created by 조영태 on 2022/10/03.
//

import Foundation
import RealmSwift
import RxCocoa
import RxDataSources
import RxRelay
import RxSwift

struct TodoSection {
    var header: String
    var items: [Item]
}

extension TodoSection: SectionModelType {
    typealias Item = TodoModelProtocol

    init(original: TodoSection, items: [Item]) {
        self = original
        self.items = items
    }
}

typealias TodoGroup = [TodoFilterType: [TodoModel]]

enum ToDoListError: Error {
    case notFound
}

enum TodoFilterType {
    case past, today, future
}

class TodoListVM: ViewModelProtocol {
    struct Input {
        let fetchItems: PublishRelay<Void>
        let addItem: PublishRelay<TodoModelProtocol>
        let changedItem: PublishRelay<TodoModelProtocol>
        let tapDelete: PublishRelay<TodoModelProtocol>
        let tapFilter: PublishRelay<TodoFilterType>
        let tapDone: PublishRelay<TodoModelProtocol>
    }

    struct Output {
        let isFetching: Driver<Bool>
        let items: Driver<[TodoSection]>
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
    private let allItems = BehaviorRelay<[TodoModel]>(value: [])
    private let cachedGroup = BehaviorRelay<TodoGroup>(value: [:])
    private let selectedFilter: BehaviorRelay<TodoFilterType>

    init(_ selectedFilter: TodoFilterType) {
        self.input = Input(
            fetchItems: PublishRelay(),
            addItem: PublishRelay(),
            changedItem: PublishRelay(),
            tapDelete: PublishRelay(),
            tapFilter: PublishRelay(),
            tapDone: PublishRelay()
        )

        self.selectedFilter = .init(value: selectedFilter)

        bindSelectedFilter()

        bindAllItems()
        bindCacheGroup()
        bindDoneTap()
        bindChangeItem()

        handleAddItem()
        handleDeleteItem()
    }

    // MARK: - Transform
    private func transform() -> Output {
        return Output(
            isFetching: isfetchingRelay.asDriver(),
            items: makeItemsDriver(),
            error: errorRelay.asDriver()
        )
    }

    private func makeSectionByDate(_ todos: [TodoModel]) -> [TodoSection] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ko_KR")

        let grouped = Dictionary(grouping: todos) { todo in
            formatter.string(from: todo.date)
        }

        let sections =
            grouped
            .map { key, value in
                TodoSection(header: key, items: value)
            }
            .sorted { $0.header < $1.header }  // 날짜순 정렬

        return sections
    }

    // view 에서 사용할 items
    private func makeItemsDriver() -> Driver<[TodoSection]> {
        return Observable.combineLatest(
            selectedFilter.asObservable(), cachedGroup.asObservable()
        ).map { (filter, group) in
            let arr = group[filter] ?? []
            return self.makeSectionByDate(arr)
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
            .map { (vm, items) in vm.makeTapGroup(items) }
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
            .asTodoModel
            .withUnretained(self)
            .flatMap { (vm, value) in vm.handleDoneToggle(value) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindChangeItem() {
        input.changedItem
            .asTodoModel
            .withUnretained(self)
            .flatMap { (vm, value) in
                vm.handleChangeItem(value)
                    .catch { _ in .never() }
            }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    // MARK: - handle
    private func handleChangeItem(_ newTodo: TodoModel) -> Single<[TodoModel]> {
        var currentArr = allItems.value

        return .create { single in

            Task {
                //TODO: TodoModel equatable 적용
                let index = currentArr.firstIndex { $0.id == newTodo.id }

                guard let index = index else { throw TodoError.notFound }

                currentArr[index] = newTodo
                single(.success(currentArr))

            }
            return Disposables.create()
        }
    }

    private func handleAddItem() {
        self.input.addItem
            .asTodoModel
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
            .asTodoModel
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
                    return self.makeTapGroup(arr)
                }
            }
            .bind(to: self.cachedGroup)
            .disposed(by: self.disposeBag)
    }

    private func handleDoneToggle(_ todo: TodoModel) -> Single<[TodoModel]> {
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
    private func fetchItems() -> Single<[TodoModel]> {
        self.isfetchingRelay.accept(true)
        return .create { [weak self] single in
            Task {
                guard let self = self else {
                    preconditionFailure("self 가 없습니다")
                }

                do {
                    let response = try await self.repo.fetchTodoList()
                        .map { $0.asTodoModel }

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

    private func deleteTodo(todo: TodoModel) -> Single<TodoModel> {
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

    private func updateDone(targetTodo target: TodoModel) -> Single<TodoModel> {
        return .create { [weak self] single in
            guard let self = self else { preconditionFailure("self 가 없습니다") }

            Task {
                do {
                    let updated = try await self.repo.updateTodo(target)
                    let model = TodoModel(updated)

                    single(.success(model))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create()
        }

    }

    // MARK: -
    private func getDateFilter(_ todo: TodoModel) -> TodoFilterType {
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

    private func changeGroupItem(items: [TodoModel], type: TodoFilterType)
        -> TodoGroup
    {
        var currentGroup = self.cachedGroup.value

        currentGroup[type] = items
        return currentGroup
    }

    private func makeTapGroup(_ items: [TodoModel]) -> TodoGroup {
        return Dictionary(grouping: items, by: getDateFilter(_:))
    }
}

private extension PublishRelay where Element == TodoModelProtocol {
    var asTodoModel: Observable<TodoModel> {
        return self.map { $0.asTodoModel }
    }
}
