//
//  MainViewController.swift
//  todoApp
//
//  Created by 조영태 on 2022/09/25.
//

import Foundation
import RxCocoa
import RxDataSources
import RxGesture
import RxSwift
import SnapKit
import Then
import UIKit

private let reuseIdentifier = "CustomCell"

extension TodoListVC: HasRxIO {
    struct Input {
        let presentedCreateVC = PublishRelay<CreateTodoVC>()
        let presentedEditVC = PublishRelay<EditTodoVC>()
    }

    struct Output {
        let presentCreateVC: Driver<Void>
        let presentEditVC: Driver<TodoModelProtocol>
    }
}

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
        $0.items = [
            UITabBarItem(
                title: I18N.past,
                image: UIImage(systemName: "arrow.left.circle"),
                tag: TodoFilterType.past.rawValue
            ),

            UITabBarItem(
                title: I18N.today,
                image: UIImage(systemName: "calendar.circle"),
                tag: TodoFilterType.today.rawValue
            ),

            UITabBarItem(
                title: I18N.future,
                image: UIImage(systemName: "arrow.right.circle"),
                tag: TodoFilterType.future.rawValue
            ),
        ]

        let appearanceTabbar = UITabBarAppearance()
        appearanceTabbar.configureWithOpaqueBackground()
        appearanceTabbar.backgroundColor = UIColor.white
        $0.standardAppearance = appearanceTabbar
    }

    let viewModel: TodoListVM
    let initFilter: TodoFilterType

    // MARK: - RX
    let input = Input()
    let output: Output

    let goCreateVC = PublishRelay<Void>()
    let goEditVC = PublishRelay<TodoModelProtocol>()

    let disposeBag = DisposeBag()

    init(initFilter: TodoFilterType, vm: TodoListVM) {
        self.viewModel = vm
        self.initFilter = initFilter
        self.output = Output(
            presentCreateVC: goCreateVC.asDriver(onErrorJustReturn: ()),
            presentEditVC: goEditVC.asDriver(onErrorDriveWith: .empty())
        )

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.title = I18N.todo

        tableView.delegate = self
        tabBar.delegate = self
        tabBar.selectedItem = {
            return tabBar.items?.first { $0.tag == initFilter.rawValue }
        }()

        // ✅ 오른쪽 버튼 추가
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.add,
            style: .plain,
            target: self,
            action: nil
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
        self.bindErrorAlert()
        self.bindCreateTodoTap()
        self.bindFinishPresentCreateVC()
        self.bindFinishPresentEditVC()
        
        viewModel.input.fetchItems.accept(())
    }

    // MARK: - Binding
    private func bindLoading() {
        self.viewModel.output.isLoading
            .drive(loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
    }

    private func bindErrorAlert() {
        viewModel.output.error
            .compactMap { $0?.localizedDescription }
            .drive { e in
                self.rx.showRetry(
                    message: e,
                    retryAction: { _ in
                        self.viewModel.input.retryTrigger.accept(.retry)
                    },
                    confirmAction: { _ in
                        self.viewModel.input.retryTrigger.accept(.none)
                    }
                )

            }
            .disposed(by: disposeBag)
    }

    private func bindTableView() {

        let dataSource = RxTableViewSectionedReloadDataSource<TodoSection>(
            configureCell: { dataSource, tableView, indexPath, item in
                guard
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: reuseIdentifier) as? TodoCell
                else {
                    return UITableViewCell()
                }
                cell.todoModel = item

                cell.rx.doneTap
                    .map { cell.todoModel }
                    .bind(to: self.viewModel.input.toggleDone)
                    .disposed(by: cell.disposeBag)

                cell.rx.tapGesture()
                    .when(.recognized)
                    .withUnretained(self)
                    .bind { (self, _) in
                        self.goEditVC.accept(cell.todoModel)
                    }
                    .disposed(by: cell.disposeBag)

                return cell
            },
            titleForHeaderInSection: { dataSource, index in
                return dataSource.sectionModels[index].header
            }
        )

        viewModel.output.items
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    private func bindNoListLabel() {
        let isFetching = self.viewModel.output
            .isLoading
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

    private func bindFinishPresentCreateVC() {
        input.presentedCreateVC
            .flatMap { vc in vc.output.writtenTodo }
            .withUnretained(self)
            .bind { (self, todo) in
                self.viewModel.input.addedItem.accept(todo)
            }
            .disposed(by: disposeBag)
    }

    private func bindCreateTodoTap() {
        navigationItem.rightBarButtonItem?.rx
            .tap.withUnretained(self)
            .bind(onNext: { (self, _) in self.goCreateVC.accept(()) })
            .disposed(by: disposeBag)
    }

    private func bindFinishPresentEditVC() {
        input.presentedEditVC
            .flatMap { vc in vc.output.writtenTodo }
            .withUnretained(self)
            .bind { (self, todo) in
                self.viewModel.input.edittedItem.accept(todo)
            }
            .disposed(by: disposeBag)
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
        guard
            let selectedFilter = TodoFilterType.values.first(where: { type in
                type.rawValue == item.tag
            })
        else {
            assertionFailure("not found tag")
            return
        }

        viewModel.input.tapFilter.accept(selectedFilter)
    }
}

extension Reactive where Base: UIViewController {
    func showRetry(
        message: String,
        retryAction: @escaping (UIAlertAction) -> Void,
        confirmAction: @escaping (UIAlertAction) -> Void
    ) {
        let alert = UIAlertController(
            title: I18N.serverError, message: message, preferredStyle: .alert)

        alert.addAction(
            UIAlertAction(
                title: I18N.confirm, style: .cancel, handler: confirmAction)
        )
        alert.addAction(
            UIAlertAction(
                title: I18N.retry, style: .default, handler: retryAction)
        )

        base.present(alert, animated: true)
    }

}
