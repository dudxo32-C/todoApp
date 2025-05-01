//  CreateTodoViewController.swift
//  todoApp
//
//  Created by 조영태 on 3/24/25.
//

import Foundation
import RxCocoa
import RxGesture
import RxSwift
import SnapKit
import Then
import UIKit

extension EditableTodoVC: HasRxIO {
    typealias Input = Empty
    
    struct Output {
        let writtenTodo = PublishSubject<TodoModelProtocol>()
    }
}

class EditableTodoVC: UIViewController {
    // MARK: UI Components
    fileprivate let textInputStackView: TextInputStackView
    fileprivate let dateInputStackView: DateInputStackView
    private let scrollView = VerticalScrollView().then {
        $0.contentSpacing = 24
        $0.contentMargins = .init(top: 16, left: 16, bottom: 0, right: 16)
    }

    // MARK: ViewModel
    fileprivate let viewModel: EditableTodoVM

    // MARK: RX
    private let isDatePickerVisible = BehaviorRelay(value: false)
    let disposeBag = DisposeBag()
    private let loadingIndicator = LoadingIndicator()
    
    let output = Output()

    // MARK: Snap
    private var contentHeightContraint: Constraint?  // 높이 제약 저장

    // MARK: Init
    fileprivate init(
        viewModel: EditableTodoVM,
        model: TodoModelProtocol? = nil
    ) {
        self.textInputStackView = TextInputStackView(
            title: model?.title, content: model?.contents)
        self.dateInputStackView = DateInputStackView(model?.date)
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        let createTodoButton = UIBarButtonItem(
            title: I18N.done,
            style: .plain,
            target: self,
            action: nil
        )

        self.navigationItem.rightBarButtonItem = createTodoButton

        self.setupScrollViewUI()

        // 로딩인디케이터 추가
        self.view.addSubview(self.loadingIndicator)

        self.textInputBinding()
        self.createButtonBinding(createTodoButton)

        // 로딩인디케이터 바인딩
        self.viewModel.output.isLoading
            .drive(self.loadingIndicator.rx.isAnimating)
            .disposed(by: self.disposeBag)

        // 생성, 수정 완료후 작업
        self.viewModel.output.writeTodoResult.drive { result in
            switch result {
            case .success(let todo):
                self.didFinishWriting(todo)

                break
            case .failure(let error):
                print(error)

            }
        }.disposed(by: self.disposeBag)
    }

    // MARK: SetUI
    private func setupScrollViewUI() {
        self.view.addSubview(scrollView)

        self.scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.scrollView.contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(self.view.safeAreaInsets)
            make.width.equalToSuperview()
        }

        self.scrollView.addArrangedSubview(self.textInputStackView)
        self.scrollView.addArrangedSubview(self.dateInputStackView)
    }

    // MARK: Binding
    private func textInputBinding() {
        self.textInputStackView.titleTextRX.orEmpty
            .bind(to: self.viewModel.input.titleRelay)
            .disposed(by: disposeBag)

        self.textInputStackView.contentTextRX.orEmpty
            .bind(to: self.viewModel.input.contentRelay)
            .disposed(by: disposeBag)

        self.dateInputStackView.changedDateRX
            .bind(to: self.viewModel.input.dateRelay)
            .disposed(by: disposeBag)
    }

    private func createButtonBinding(_ button: UIBarButtonItem) {
        self.viewModel.output.inputValid
            .filter { _ in self.navigationItem.rightBarButtonItem != nil }
            .drive(self.navigationItem.rightBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)

        button.rx.tap
            .bind(to: self.viewModel.input.doneTap)
            .disposed(by: disposeBag)
    }
    
    fileprivate func didFinishWriting(_ todo:TodoModelProtocol) {
        preconditionFailure("Subclasses must implement didFinishWriting()")
    }
}

// MARK: -
class CreateTodoVC: EditableTodoVC {
    init(_ viewModel:EditableTodoVM) {
        super.init(viewModel: viewModel)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.title = I18N.createTodo
        super.viewDidLoad()
    }
    
    override func didFinishWriting(_ todo:TodoModelProtocol) {
        self.output.writtenTodo.onNext(todo)
        self.output.writtenTodo.onCompleted()
        self.navigationController?.dismiss(animated: true)
    }

}

// MARK: -
class EditTodoVC: EditableTodoVC {
    init(model: TodoModelProtocol, viewModel: EditableTodoVM) {
        super.init(viewModel: viewModel, model: model)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.title = I18N.editTodo
        super.viewDidLoad()
    }
    
    override func didFinishWriting(_ todo:TodoModelProtocol) {
        self.output.writtenTodo.onNext(todo)
        self.output.writtenTodo.onCompleted()
        self.navigationController?.dismiss(animated: true)
    }
}
