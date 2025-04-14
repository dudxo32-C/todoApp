//
//  MainViewController.swift
//  todoApp
//
//  Created by 조영태 on 2022/09/25.
//

import Foundation
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

private let reuseIdentifier = "CustomCell"

class MainViewController: UIViewController {
    let table = UITableView().then {
        $0.register(TodoCell.self, forCellReuseIdentifier: reuseIdentifier)
        $0.isHidden = true
    }

    let buton = UIButton().then {
        $0.backgroundColor = .black
    }

    private let loadingIndicator = LoadingIndicator()

    private let noListLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.noList
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.isHidden = true
        return label
    }()

    let disposeBag = DisposeBag()
    let viewModel: MainViewModel

    init() {

        viewModel = MainViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")

    }

    override func viewDidLoad() {
        self.title = I18N.todo
        // ✅ 오른쪽 버튼 추가
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.add,
            style: .plain,
            target: self,
            action: #selector(newTodoTap)
        )

        self.view.addSubview(self.table)
        self.view.addSubview(self.noListLabel)
        self.view.addSubview(self.loadingIndicator)

        self.table.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalTo(self.view.safeAreaLayoutGuide).inset(
                C_margin16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }

        self.noListLabel.snp.makeConstraints { make in
            make.center.equalTo(self.view.safeAreaLayoutGuide)
        }

        self.bindLoading()
        self.bindTableView()
        self.bindNoListLabel()
    }

    private func bindLoading() {
        self.viewModel.output.isFetching
            .drive(loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
    }

    private func bindTableView() {
        let isErrorObservable = viewModel.output.error.map { $0 != nil }
            .asObservable()
        let isFetchingOvservable = self.viewModel.output.isFetching
            .asObservable()

        Observable.zip(isFetchingOvservable, isErrorObservable)
            .map { $0 || $1 }
            .asDriver(onErrorJustReturn: false)
            .drive(self.table.rx.isHidden)
            .disposed(by: disposeBag)

        self.viewModel.output.items
            .drive(
                table.rx.items(
                    cellIdentifier: reuseIdentifier, cellType: TodoCell.self)
            ) { r, p, c in c.todoModel = p }
            .disposed(by: disposeBag)

    }

    private func bindNoListLabel() {
        self.viewModel.output.error
            .map { $0 as? ToDoListError != ToDoListError.noItems }
            .asDriver()
            .drive(noListLabel.rx.isHidden)
            .disposed(by: disposeBag)

    }

    // TODO: Coordinator 패턴 적용하기
    @objc private func newTodoTap() {
        let newVC = EditableTodoDIContainer().makeCreateTodoVC(.mock)
        let modalNavi = UINavigationController(rootViewController: newVC)
        self.navigationController?.present(modalNavi, animated: true)

        newVC.writtenTodo.subscribe(onNext: { [weak self] todo in
            self?.viewModel.createTodoListItem(todo: todo)
        }).disposed(by: disposeBag)
    }
}
