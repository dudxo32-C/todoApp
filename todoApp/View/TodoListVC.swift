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

class TodoListVC: UIViewController {
    private let tableView = UITableView().then {
        $0.register(TodoCell.self, forCellReuseIdentifier: reuseIdentifier)
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

    private let tabBar = UITabBar().then {
        let pastItem = UITabBarItem(
            title: I18N.past, image: UIImage(systemName: "arrow.left.circle"),
            tag: 2
        )
        
        let todayItem = UITabBarItem(
            title: I18N.today, image: UIImage(systemName: "calendar.circle"),
            tag: 0
        )
        
        let futureItem = UITabBarItem(
            title: I18N.future,
            image: UIImage(systemName: "arrow.right.circle"),
            tag: 1
        )

        $0.items = [pastItem, todayItem, futureItem]
        $0.selectedItem = todayItem

        let appearanceTabbar = UITabBarAppearance()
        appearanceTabbar.configureWithOpaqueBackground()
        appearanceTabbar.backgroundColor = UIColor.white
        $0.standardAppearance = appearanceTabbar
    }
    let viewModel = TodoListVM(TodoFilterType.today)

    // MARK: - RX
    let disposeBag = DisposeBag()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")

    }

    override func viewDidLoad() {
        self.title = I18N.todo

        tableView.delegate = self
        tabBar.delegate = self

        // ✅ 오른쪽 버튼 추가
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.add,
            style: .plain,
            target: self,
            action: #selector(newTodoTap)
        )

        self.view.addSubview(self.tableView)

        view.addSubview(tabBar)
        tableView.backgroundView = noListLabel
        tableView.backgroundView?.isHidden = true

        self.view.addSubview(self.loadingIndicator)

        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
            make.left.right.equalTo(self.view.safeAreaLayoutGuide).inset(
                C_margin16)
            make.bottom.equalTo(tabBar.snp.top)
        }

        tabBar.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view.safeAreaLayoutGuide)
        }

        self.bindLoading()
        self.bindTableView()
        self.bindNoListLabel()

        
        viewModel.input.fetchItems.accept(())
    }

    // MARK: - Binding
    private func bindLoading() {
        self.viewModel.output.isFetching
            .drive(loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
    }

    private func bindTableView() {
        viewModel.output.items
            .drive(
                tableView.rx.items(
                    cellIdentifier: reuseIdentifier, cellType: TodoCell.self)
            ) { (row, element, cell) in
                cell.rx.doneTap
                    .map { cell.todoModel }
                    .bind(to: self.viewModel.input.tapDone)
                    .disposed(by: cell.disposeBag)
                
                cell.todoModel = element
                
                
            }
            .disposed(by: disposeBag)
    }

    private func bindNoListLabel() {
        let isFetching = self.viewModel.output
            .isFetching
            .asObservable()

        let isEmptyItems = viewModel.output.items
            .map { $0.isEmpty }
            .asObservable()

        Observable.combineLatest(isFetching, isEmptyItems)
            .map { isFetching, isEmpty in
                return isFetching || !isEmpty
            }
            .asDriver(onErrorJustReturn: false)
            .drive { [weak self] isHidden in
                self?.tableView.backgroundView?.isHidden = isHidden
            }
            .disposed(by: disposeBag)
    }

    // MARK: -
    // TODO: Coordinator 패턴 적용하기
    @objc private func newTodoTap() {
        let newVC = EditableTodoDIContainer().makeCreateTodoVC(.mock)
        let modalNavi = UINavigationController(rootViewController: newVC)
        self.navigationController?.present(modalNavi, animated: true)

        newVC.writtenTodo.subscribe(onNext: { [weak self] todo in
            self?.viewModel.input.addItem.accept(todo)
        }).disposed(by: disposeBag)
    }
}

extension TodoListVC: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    )
        -> UISwipeActionsConfiguration?
    {

        let deleteAction = UIContextualAction(style: .destructive, title: nil) {
            [weak self] _, _, completionHandler in

            let cell = tableView.cellForRow(at: indexPath) as! TodoCell
            self?.viewModel.input.tapDelete.accept(cell.todoModel)

            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension TodoListVC: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        switch item.tag {
        case 0:
            viewModel.input.tapFilter.accept(.today)
        case 1:
            viewModel.input.tapFilter.accept(.future)
        case 2:
            viewModel.input.tapFilter.accept(.past)
        default:
            break
        }
    }
}
