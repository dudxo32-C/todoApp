//
//  TodoListCoordinator.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import RxRelay
import RxSwift
import UIKit

final class TodoListCoordinator: CoordinatorProcotcol {
    let navigationController: UINavigationController
    let todoListVC: TodoListVC

    let disposeBag = DisposeBag()

    init(
        _ navigationController: UINavigationController,
        diContainer: TodoListDIContainer
    ) {
        self.navigationController = navigationController
        self.todoListVC = diContainer.makeTodoListVC(initFilter: .today)
    }

    func start() {
        navigationController.viewControllers = [todoListVC]

        bind()
    }

    func bind() {
        bindPresentCreateVC()
        bindPresentEditVC()
    }

    private func bindPresentCreateVC() {
        todoListVC.output.presentCreateVC
            .drive(onNext: { _ in
                let newVC = EditableTodoDIContainer().makeCreateTodoVC()
                let modalNavi = UINavigationController(
                    rootViewController: newVC)

                self.navigationController.present(modalNavi, animated: true) {
                    self.todoListVC.input
                        .didFinishPresentCreateVC
                        .accept(newVC)
                }
            })
            .disposed(by: disposeBag)
    }

    private func bindPresentEditVC() {

        todoListVC.output.presentEditVC
            .drive(onNext: { todo in
                let newVC = EditableTodoDIContainer().makeEditTodoVC(
                    todoModel: todo
                )
                let modalNavi = UINavigationController(
                    rootViewController: newVC
                )

                self.navigationController.present(modalNavi, animated: true) {
                    self.todoListVC.input
                        .didFinishPresentEditVC
                        .accept(newVC)
                }

            })
            .disposed(by: disposeBag)
    }
}
