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

extension EditableTodoVM: ViewModelProtocol {
    struct Input {
        let titleRelay: BehaviorRelay<String>
        let dateRelay: BehaviorRelay<Date?>
        let contentRelay: BehaviorRelay<String>
        let doneTap = PublishRelay<Void>()
    }

    struct Output {
        let inputValid: Driver<Bool>
        let writeTodoResult: Driver<Result<TodoModelProtocol, Error>>
        let isLoading: Driver<Bool>
    }
}

class EditableTodoVM {
    let input: Input
    let output: Output

    fileprivate let repo: TodoRepo

    // MARK: RX
    fileprivate let loadingRelay: BehaviorRelay<Bool> = .init(value: false)
    private let createResultRelay:
        PublishRelay<Result<TodoModelProtocol, Error>> = .init()
    fileprivate let inputValidRelay: Observable<Bool>
    var disposeBag = DisposeBag()

    // MARK: Init
    fileprivate init(
        input: Input,
        inputValidRelay: Observable<Bool>,
        repository: TodoRepo
    ) {
        self.repo = repository
        self.input = input
        self.inputValidRelay = inputValidRelay

        self.output = Output(
            inputValid: self.inputValidRelay.asDriver(onErrorJustReturn: false),
            writeTodoResult: self.createResultRelay
                .asDriver(onErrorDriveWith: .empty()),
            isLoading: self.loadingRelay.asDriver()
        )

        self.input.doneTap
            .flatMap { self.doneTap() }
            .subscribe(
                onNext: { value in
                    self.createResultRelay.accept(.success(value))
                },
                onError: { error in
                    self.createResultRelay.accept(.failure(error))
                }
            )
            .disposed(by: disposeBag)

    }

    fileprivate func doneTap() -> Single<TodoModel> {
        preconditionFailure("Subclasses must implement doneTap()")
    }
}

class CreateTodoVM: EditableTodoVM {
    init(_ repository: TodoRepo) {
        let input = Input(
            titleRelay: .init(value: ""),
            dateRelay: .init(value: nil),
            contentRelay: .init(value: "")
        )

        let validation = Observable.combineLatest(
            input.titleRelay, input.dateRelay
        )
        .map { (title: String, date: Date?) in
            return !(title.isEmpty) && date != nil
        }

        super.init(
            input: input,
            inputValidRelay: validation,
            repository: repository
        )
    }

    override func doneTap() -> Single<TodoModel> {
        guard let date = self.input.dateRelay.value else {
            preconditionFailure("date 값이 nil 입니다")
        }

        let title = self.input.titleRelay.value
        let contents = self.input.contentRelay.value

        self.loadingRelay.accept(true)

        return .deferred { [weak self] in
            guard let self = self else { preconditionFailure("self 가 없습니다") }

            return .async {
                let response = try await self.repo.writeTodo(
                    title: title,
                    contents: contents,
                    date: date
                )

                return response.asTodoModel
            }
        }
    }
}

class EditTodoVM: EditableTodoVM {
    // MARK: Property
    private let model: TodoModel
    // MARK: RX
    private let isChangedTitle = BehaviorRelay(value: false)
    private let isChangedDate = BehaviorRelay(value: false)
    private let isChangedContent = BehaviorRelay(value: false)

    // MARK: Init
    init(model: TodoModelProtocol, repository: TodoRepo) {
        self.model = TodoModel(model)

        let input = Input(
            titleRelay: .init(value: model.title),
            dateRelay: .init(value: model.date),
            contentRelay: .init(value: model.contents)
        )

        // 변화가 있는지 체크
        let isChangedInput = Observable.combineLatest(
            self.isChangedTitle,
            self.isChangedDate,
            self.isChangedContent
        ).map { $0 || $1 || $2 }

        // 변화가 있고 기본 validation을 만족
        let validation = Observable.combineLatest(
            input.titleRelay,
            input.dateRelay,
            isChangedInput
        )
        .map { (title: String, date: Date?, isChanged: Bool) in
            return !(title.isEmpty) && date != nil && isChanged
        }

        super.init(
            input: input,
            inputValidRelay: validation,
            repository: repository
        )

        input.titleRelay.map { $0 != model.title }
            .bind(to: isChangedTitle)
            .disposed(by: disposeBag)

        input.dateRelay.map {
            guard let date = $0 else { return false }
            return !Calendar.current.isDate(date, inSameDayAs: model.date)
        }
        .bind(to: isChangedDate)
        .disposed(by: disposeBag)

        input.contentRelay.map { $0 != model.title }
            .bind(to: isChangedContent)
            .disposed(by: disposeBag)
    }

    override func doneTap() -> Single<TodoModel> {
        guard let date = self.input.dateRelay.value else {
            preconditionFailure("date 값이 nil 입니다")
        }

        let title = self.input.titleRelay.value
        let contents = self.input.contentRelay.value

        self.loadingRelay.accept(true)

        return .deferred { [weak self] in
            guard let self = self else { preconditionFailure("self 가 없습니다") }

            return .async {

                let newTodo = self.model.copyWith(
                    title: title,
                    date: date,
                    contents: contents
                )

                let response = try await self.repo.updateTodo(newTodo)
                
                return response.asTodoModel
            }
        }
    }
}
