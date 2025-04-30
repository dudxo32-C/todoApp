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

// MARK: ViewModel에서 사용하는 데이터 모델
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

// MARK: -  데이터 캐싱 및 분리 타입
private typealias TodoGroup = [TodoFilterType: [TodoModel]]

enum TodoFilterType {
    case past, today, future
}

// MARK: - Error 리스트
enum ToDoListError: Error {
    case notFound
}

// MARK: - VM
class TodoListVM: ViewModelProtocol, RetryProtocol, LoadingProtocol {

    struct Input: CommonRetryInput {
        let fetchItems: PublishRelay<Void>
        let addedItem: PublishRelay<TodoModelProtocol>
        let edittedItem: PublishRelay<TodoModelProtocol>
        let tapDelete: PublishRelay<TodoModelProtocol>
        let tapFilter: PublishRelay<TodoFilterType>
        let toggleDone: PublishRelay<TodoModelProtocol>
        let retryTrigger: PublishRelay<RetryAction>
    }

    struct Output: LoadingOutput {
        let isLoading: Driver<Bool>
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

    private let isfetching = BehaviorRelay(value: false)
    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private let allItems = BehaviorRelay<[TodoModel]>(value: [])
    private let cachedGroup = BehaviorRelay<TodoGroup>(value: [:])
    private let selectedFilter: BehaviorRelay<TodoFilterType>

    init(_ selectedFilter: TodoFilterType) {
        self.input = Input(
            fetchItems: PublishRelay(),
            addedItem: PublishRelay(),
            edittedItem: PublishRelay(),
            tapDelete: PublishRelay(),
            tapFilter: PublishRelay(),
            toggleDone: PublishRelay(),
            retryTrigger: PublishRelay()
        )

        self.selectedFilter = .init(value: selectedFilter)

        bindFetchItemsToAll()
        bindAllToCacheGroup()

        bindFilterTapToSelected()

        bindToggleDoneToAll()
        bindChangedItemToAll()
        bindAddedItemToAll()
        bindTapDeleteToAll()
    }

    // MARK: - Transform
    private func transform() -> Output {
        return Output(
            isLoading: isfetching.asDriver(),
            items: makeItemsDriver(),
            error: errorRelay.asDriver()
        )
    }
    // view 에서 사용할 items
    private func makeItemsDriver() -> Driver<[TodoSection]> {
        func makeSectionByDate(_ todos: [TodoModel]) -> [TodoSection] {
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

        return Observable.combineLatest(
            selectedFilter.asObservable(), cachedGroup.asObservable()
        ).map { (filter, group) in
            let arr = group[filter] ?? []
            return makeSectionByDate(arr)
        }
        .asDriver(onErrorJustReturn: [])
    }

    // MARK: - Binding
    private func bindFetchItemsToAll() {
        input.fetchItems
            .withUnretained(self)
            .flatMap { (vm, _) in vm.handleFetching() }
            .bind(to: allItems)
            .disposed(by: disposeBag)
    }

    private func bindAllToCacheGroup() {
        allItems
            .withUnretained(self)
            .map { (vm, items) in vm.makeTapGroup(items) }
            .bind(to: cachedGroup)
            .disposed(by: disposeBag)
    }

    // 탭 클릭 데이터 저장
    private func bindFilterTapToSelected() {
        input.tapFilter
            .bind(to: self.selectedFilter)
            .disposed(by: disposeBag)
    }

    private func bindChangedItemToAll() {
        input.edittedItem
            .asTodoModel
            .withUnretained(self)
            .flatMap { (self, changed) in self.handleEditted(new: changed) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindToggleDoneToAll() {
        input.toggleDone
            .asTodoModel
            .withUnretained(self)
            .flatMap { (self, value) in self.handleToggleDone(oldTodo: value) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindAddedItemToAll() {
        self.input.addedItem
            .asTodoModel
            .withUnretained(self)
            .map { (self, newItem) in self.addItemInLocal(newItem) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindTapDeleteToAll() {
        self.input.tapDelete
            .asTodoModel
            .withUnretained(self)
            .flatMap { (self, value) in self.handleDeleteItem(target: value) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    // MARK: - handle
    private func retryCond(error: Observable<Error>) -> Observable<Void> {
        return error.withUnretained(self)
            .do { (self, error) in self.errorRelay.accept(error) }
            .map { (_, error) in error }
            .flatMap(handelRetry)
    }

    private func handleFetching() -> Single<[TodoModel]> {
        return self.fetchItems()
            .retry(when: retryCond)
            .catch { _ in .never() }
    }

    private func handleDeleteItem(target: TodoModel) -> Observable<[TodoModel]>
    {
        return deleteTodo(todo: target)
            .asObservable()
            .withUnretained(self)
            .map { (self, removed) in self.deleteItemInLocal(removed) }
            .retry(when: retryCond)
            .catch { _ in .empty() }
    }

    private func handleToggleDone(oldTodo: TodoModel) -> Observable<[TodoModel]>
    {
        let toggled = oldTodo.copyWith(isDone: !oldTodo.isDone)

        return updateDone(newTodo: toggled)
            .asObservable()
            .withUnretained(self)
            .map { (self, updated) in try self.changeItemInLocal(updated) }
            .retry(when: retryCond)
            .catch { _ in .empty() }
    }

    private func handleEditted(new: TodoModel) -> Observable<[TodoModel]> {

        return .deferred {
            do {
                let changedList = try self.changeItemInLocal(new)

                return .just(changedList)
            } catch {
                return .error(error)
            }
        }
        .retry(when: retryCond)
        .catch { _ in .empty() }
    }

    // MARK: - async
    private func fetchItems() -> Single<[TodoModel]> {
        return .deferredWithUnretained(self) { retainedObj in
            return .async {
                return try await retainedObj.repo.fetchTodoList()
                    .map { $0.asTodoModel }
            }
            .handleLoadingState { isLoading in
                retainedObj.isfetching.accept(isLoading)
            }
        }
    }

    private func deleteTodo(todo: TodoModel) -> Single<TodoModel> {
        return .deferredWithUnretained(self) { retainedObj in
            return .async {
                let _ = try await retainedObj.repo.deleteTodo(todo.id)
                return todo
            }
        }
    }

    private func updateDone(newTodo: TodoModel) -> Single<TodoModel> {
        return .deferredWithUnretained(self) { retainedObj in
            return .async {
                let updated = try await retainedObj.repo.updateTodo(newTodo)
                return updated.asTodoModel
            }
        }
    }

    // MARK: -
    private func makeTapGroup(_ items: [TodoModel]) -> TodoGroup {
        return Dictionary(grouping: items) { item in
            let comparison = Calendar.current.compare(
                item.date,
                to: Date(),
                toGranularity: .day
            )

            switch comparison {
            case .orderedAscending:
                return TodoFilterType.past
            case .orderedSame:
                return TodoFilterType.today
            case .orderedDescending:
                return TodoFilterType.future
            }
        }
    }

    private func addItemInLocal(_ newTodo: TodoModel) -> [TodoModel] {
        var currentAll = allItems.value
        currentAll.append(newTodo)

        return currentAll
    }

    private func changeItemInLocal(_ newTodo: TodoModel) throws -> [TodoModel] {
        var currentAll = allItems.value

        let targetIndex = currentAll.firstIndex { $0.id == newTodo.id }
        guard let index = targetIndex else { throw TodoError.notFound }

        currentAll[index] = newTodo

        return currentAll
    }

    private func deleteItemInLocal(_ removed: TodoModel) -> [TodoModel] {
        let current = self.allItems.value
        let removedList = current.filter { $0.id != removed.id }

        return removedList
    }
}

extension PublishRelay where Element == TodoModelProtocol {
    fileprivate var asTodoModel: Observable<TodoModel> {
        return self.map { $0.asTodoModel }
    }
}
