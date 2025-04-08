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
    private let disposeBag = DisposeBag()
    private let loadingIndicator = LoadingIndicator()
    let writtenTodo = PublishSubject<TodoModelProtocol>()

    // MARK: Snap
    private var contentHeightContraint: Constraint?  // 높이 제약 저장

    // MARK: Init
    fileprivate init(
        _ textInputStackView: TextInputStackView,
        _ dateInputStackView: DateInputStackView,
        viewModel: EditableTodoVM
    ) {
        self.textInputStackView = textInputStackView
        self.dateInputStackView = dateInputStackView
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

        textInputBinding()
        createButtonBinding(createTodoButton)

        self.viewModel.output.isLoading
            .drive(self.loadingIndicator.rx.isAnimating)
            .disposed(by: self.disposeBag)

        self.viewModel.output.writeTodoResult.drive { result in
            switch result {
            case .success(let todo):
                self.writtenTodo.onNext(todo)
                self.writtenTodo.onCompleted()
                self.navigationController?.dismiss(animated: true)

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
}

// MARK: -
class CreateTodoVC: EditableTodoVC {
    init() {
        super.init(
            TextInputStackView(),
            DateInputStackView(),
            viewModel: CreateTodoVM()
        )
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.title = I18N.createTodo
        super.viewDidLoad()
    }

}

// MARK: -
class EditTodoVC: EditableTodoVC {
    init(_ model: TodoModelProtocol) {
        //        let formatter = DateFormatter()
        //        formatter.dateFormat = "yyyy/MM/dd"
        //         let specificDate = formatter.date(from: "2025/03/29")!
        super.init(
            TextInputStackView(title: model.title, content: model.contents),
            DateInputStackView(model.date),
            viewModel: EditTodoVM(model: model)
        )
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.title = I18N.editTodo
        super.viewDidLoad()
    }
}
