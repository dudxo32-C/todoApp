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

// MARK: 데이터 캐싱 및 분리 타입

// MARK: - ViewModel에서 사용하는 데이터 모델
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

extension TodoListVM: ViewModelProtocol, RetryProtocol, LoadingProtocol {
    struct UseCase {
        let fetch: any FetchTodoUseCase
        let delete: any DeleteTodoUseCase
        let toggleDone: any ToggleTodoDoneUseCase
        let cache: TodoListCache
    }

    struct Input: RetryInput {
        let fetchItems: PublishRelay<Void>
        let addedItem: PublishRelay<TodoModelProtocol>
        let edittedItem: PublishRelay<TodoModelProtocol>
        let tapDelete: PublishRelay<TodoModelProtocol>
        let tapFilter: PublishRelay<TodoFilterType>
        let toggleDone: PublishRelay<TodoModelProtocol>
        let retryTrigger: PublishRelay<RetryAction>
    }

    struct State: LoadingState {
        let isLoading: Driver<Bool>
        let items: Driver<[TodoSection]>
        let error: Driver<Error?>

        fileprivate init(
            isLoading: BehaviorRelay<Bool>,
            filter: BehaviorRelay<TodoFilterType>,
            cachedGroup: BehaviorRelay<TodoGroup>,
            error: PublishRelay<Error?>
        ) {
            self.isLoading = isLoading.asDriver()
            self.error = error.asDriver(onErrorJustReturn: nil)

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

            self.items = Observable.combineLatest(
                filter.asObservable(), cachedGroup.asObservable()
            ).map { (filter, group) in
                let arr = group[filter] ?? []
                return makeSectionByDate(arr)
            }
            .asDriver(onErrorJustReturn: [])
        }
    }
}

// MARK: - VM
class TodoListVM {
    var state: State {
        if let cached = _state {
            return cached
        }

        let new = State(
            isLoading: isfetching,
            filter: selectedFilter,
            cachedGroup: cachedGroup,
            error: errorRelay
        )
        _state = new
        return new
    }

    var input: Input
    private var _state: State?

    var disposeBag = DisposeBag()
    
    private let isfetching = BehaviorRelay(value: false)
    private let errorRelay = PublishRelay<Error?>()
    private let allItems = BehaviorRelay<[TodoModel]>(value: [])
    private let cachedGroup = BehaviorRelay<TodoGroup>(value: [:])
    private let selectedFilter: BehaviorRelay<TodoFilterType>

    // MARK: - UseCase
    private let useCase: UseCase

    init(initFilter: TodoFilterType, useCase: UseCase) {
        self.useCase = useCase
        self.input = Input(
            fetchItems: PublishRelay(),
            addedItem: PublishRelay(),
            edittedItem: PublishRelay(),
            tapDelete: PublishRelay(),
            tapFilter: PublishRelay(),
            toggleDone: PublishRelay(),
            retryTrigger: PublishRelay()
        )

        self.selectedFilter = .init(value: initFilter)

        bindFetchItemsToAll()
        bindAllToCacheGroup()

        bindFilterTapToSelected()
        bindToggleDoneToAll()
        bindChangedItemToAll()
        bindAddedItemToAll()
        bindTapDeleteToAll()
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
            .asTodoEntity
            .withUnretained(self)
            .flatMap { (self, changed) in self.handleEditted(new: changed) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindToggleDoneToAll() {
        input.toggleDone
            .asTodoEntity
            .withUnretained(self)
            .flatMap { (self, value) in
                self.handleToggleDone(target: value)
            }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindAddedItemToAll() {
        self.input.addedItem
            .asTodoModel
            .withUnretained(self)
            .map { (self, newItem) in
                self.useCase.cache.addItemInList(
                    TodoMapper.toEntity(newItem),
                    list: self.allItems.value.map(TodoMapper.toEntity)
                )
                .map(TodoMapper.toModel)
            }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    private func bindTapDeleteToAll() {
        self.input.tapDelete
            .asTodoEntity
            .withUnretained(self)
            .flatMap { (self, value) in self.handleDeleteItem(target: value) }
            .bind(to: self.allItems)
            .disposed(by: self.disposeBag)
    }

    // MARK: - handle

    // 클로저에서 사용시 [weak self] 문제로 따로 떄서 사용
    private func retryCond(_ error: Observable<Error>) -> Observable<Void> {
        return self.handelRetry(from: error, in: self.errorRelay)
    }

    private func handleFetching() -> Single<[TodoModel]> {
        return .deferredWithUnretained(self) { obj in
            .async {
                try await obj.useCase.fetch.execute()
                    .map(TodoMapper.toModel)
            }
        }
        .handleLoadingState(to: self.isfetching)
        .retry(when: retryCond)
        .catch { _ in .never() }
    }

    private func handleDeleteItem(target: Todo) -> Single<[TodoModel]> {
        return Single.deferredWithUnretained(self) { obj in
            .async {
                return try await obj.useCase.delete.execute(
                    target,
                    list: obj.allItems.value.map(TodoMapper.toEntity)
                )
                .map(TodoMapper.toModel)
            }
        }
        .retry(when: retryCond)
        .catch { _ in .never() }
    }

    private func handleToggleDone(target: Todo) -> Single<[TodoModel]> {
        return .deferredWithUnretained(self) { obj in
            return .async {
                let response = try await obj.useCase.toggleDone.execute(
                    target,
                    list: obj.allItems.value.map(TodoMapper.toEntity)
                )

                return response.map(TodoMapper.toModel)
            }
        }
        .retry(when: retryCond)
        .catch { _ in .never() }
    }

    private func handleEditted(new: Todo) -> Observable<[TodoModel]> {
        return .deferredWithUnretained(self) { obj in
            do {
                let changedList = try obj.useCase.cache.changeItemInList(
                    new,
                    list: obj.allItems.value.map(TodoMapper.toEntity)
                )
                .map(TodoMapper.toModel)

                return .just(changedList)
            } catch {
                return .error(error)
            }
        }
        .retry(when: retryCond)
        .catch { _ in .empty() }
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
}

extension PublishRelay where Element == TodoModelProtocol {
    fileprivate var asTodoModel: Observable<TodoModel> {
        return self.map { $0.asTodoModel }
    }

    fileprivate var asTodoEntity: Observable<Todo> {
        return self.map { todo in
            TodoMapper.toEntity(todo)
        }
    }
}
