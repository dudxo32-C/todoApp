//
//  InputTodoViewModel.swift
//  todoApp
//
//  Created by 조영태 on 3/24/25.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

extension WritableTodoVM: ViewModelProtocol, LoadingProtocol, RetryProtocol {
    struct UseCase {
        let addTodo: any AddTodoUseCase
        let EditTodo: any EditTodoUseCase
    }

    struct Input: RetryInput {
        let titleRelay: BehaviorRelay<String>
        let dateRelay: BehaviorRelay<Date?>
        let contentRelay: BehaviorRelay<String>
        let doneTap = PublishRelay<Void>()
        let retryTrigger = PublishRelay<RetryAction>()
    }

    struct State: LoadingState {
        let inputValid: Driver<Bool>
        let editedModel: Driver<TodoModelProtocol>
        let editError: Driver<Error?>
        let isLoading: Driver<Bool>

        fileprivate init(
            inputValid: BehaviorRelay<Bool>,
            editedModel: PublishRelay<TodoModel>,
            editError: PublishRelay<Error?>,
            isLoading: BehaviorRelay<Bool>
        ) {
            self.inputValid = inputValid.asDriver()

            self.editedModel = editedModel.map { $0 as TodoModelProtocol }
                .asDriver(onErrorDriveWith: .never())

            self.editError = editError.asDriver(onErrorJustReturn: nil)

            self.isLoading = isLoading.asDriver()
        }
    }
}

class WritableTodoVM {
    let input: Input
    let state: State

    // MARK: RX
    fileprivate let loadingRelay: BehaviorRelay<Bool> = .init(value: false)
    private let errorRelay: PublishRelay<Error?> = .init()
    private let editedModelRelay: PublishRelay<TodoModel> = .init()
    fileprivate let inputValidRelay = BehaviorRelay<Bool>.init(value: false)
    var disposeBag = DisposeBag()

    fileprivate let useCase: UseCase

    // MARK: Init
    fileprivate init(
        input: Input,
        useCase: UseCase
    ) {
        self.useCase = useCase
        self.input = input

        self.state = State(
            inputValid: inputValidRelay,
            editedModel: editedModelRelay,
            editError: errorRelay,
            isLoading: loadingRelay
        )

        bindDoneTap()
    }

    private func bindDoneTap() {
        self.input.doneTap
            .withUnretained(self)
            .flatMap { (self, _) in self.handleChangeTodo() }
            .bind(to: editedModelRelay)
            .disposed(by: disposeBag)
    }

    private func handleChangeTodo() -> Single<TodoModel> {
        return writeTodo()
            .handleLoadingState(to: self.loadingRelay)
            .retry(when: { error in
                return self.handelRetry(from: error, in: self.errorRelay)
            })
            .catch { _ in .never() }
    }

    fileprivate func writeTodo() -> Single<TodoModel> {
        preconditionFailure("Subclasses must implement doneTap()")
    }
}

class CreateTodoVM: WritableTodoVM {
    init(_ useCase: UseCase) {
        let input = Input(
            titleRelay: .init(value: ""),
            dateRelay: .init(value: nil),
            contentRelay: .init(value: "")
        )

        super.init(
            input: input,
            useCase: useCase
        )

        bindValid()
    }

    private func bindValid() {
        Observable.combineLatest(
            input.titleRelay, input.dateRelay
        )
        .map { (title: String, date: Date?) in
            return !(title.isEmpty) && date != nil
        }
        .bind(to: inputValidRelay)
        .disposed(by: disposeBag)
    }

    override func writeTodo() -> Single<TodoModel> {
        guard let date = self.input.dateRelay.value else {
            preconditionFailure("date 값이 nil 입니다")
        }

        let title = self.input.titleRelay.value
        let contents = self.input.contentRelay.value

        return .deferredWithUnretained(self) { obj in
            return .async {
                let response = try await obj.useCase.addTodo.execute(
                    title: title,
                    contents: contents,
                    date: date
                )

                return TodoMapper.toModel(response)
            }
        }
    }
}

class EditTodoVM: WritableTodoVM {
    // MARK: Property
    private let model: TodoModel
    // MARK: RX
    private let isChangedTitle = BehaviorRelay(value: false)
    private let isChangedDate = BehaviorRelay(value: false)
    private let isChangedContent = BehaviorRelay(value: false)

    // MARK: Init
    init(model: TodoModelProtocol, useCase: UseCase) {
        self.model = model.asTodoModel

        let input = Input(
            titleRelay: .init(value: model.title),
            dateRelay: .init(value: model.date),
            contentRelay: .init(value: model.contents)
        )

        super.init(
            input: input,
            useCase: useCase
        )

        bindValid()
        bindChangeText()
    }

    private func bindValid() {
        // 변화가 있는지 체크
        let isChangedInput = Observable.combineLatest(
            self.isChangedTitle,
            self.isChangedDate,
            self.isChangedContent
        ).map { $0 || $1 || $2 }

        // 변화가 있고 기본 validation을 만족
        Observable.combineLatest(
            input.titleRelay,
            input.dateRelay,
            isChangedInput
        )
        .map { (title: String, date: Date?, isChanged: Bool) in
            return !(title.isEmpty) && date != nil && isChanged
        }
        .bind(to: inputValidRelay)
        .disposed(by: disposeBag)
    }

    private func bindChangeText() {
        input.titleRelay.map { $0 != self.model.title }
            .bind(to: isChangedTitle)
            .disposed(by: disposeBag)

        input.dateRelay.map {
            guard let date = $0 else { return false }
            return !Calendar.current.isDate(date, inSameDayAs: self.model.date)
        }
        .bind(to: isChangedDate)
        .disposed(by: disposeBag)

        input.contentRelay.map { $0 != self.model.title }
            .bind(to: isChangedContent)
            .disposed(by: disposeBag)
    }

    override func writeTodo() -> Single<TodoModel> {
        guard let date = self.input.dateRelay.value else {
            preconditionFailure("date 값이 nil 입니다")
        }

        let title = self.input.titleRelay.value
        let contents = self.input.contentRelay.value

        return .deferredWithUnretained(self) { obj in
            return .async {

                let response = try await obj.useCase.EditTodo.execute(
                    TodoMapper.toEntity(obj.model),
                    newTitle: title,
                    newDate: date,
                    newContents: contents
                )

                return TodoMapper.toModel(response)
            }
        }
    }
}
