//
//  EditableTodoCoordinator.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import RxSwift
import UIKit

class EditableTodoCoordinator: CoordinatorProcotcol {
    enum Mode {
        case create
        case edit(todo: TodoModelProtocol)
    }

    let navigationController: UINavigationController
    let editableVC: EditableTodoVC

    struct Output {
        let presentedCreateVC = PublishSubject<CreateTodoVC>()
        let presentedEditVC = PublishSubject<EditTodoVC>()
    }
    
    let output = Output()
    let disposeBag = DisposeBag()

    init(
        _ navigationController: UINavigationController,
        diContainer: EditableTodoDIContainer,
        mode: Mode
    ) {
        self.navigationController = navigationController
        
        switch mode {
        case .create:
            self.editableVC = diContainer.makeCreateTodoVC()
        case .edit(let todo):
            self.editableVC = diContainer.makeEditTodoVC(todoModel: todo)
        }
    }

    func start() {
        presentEditableVC()
    }
    
    private func presentEditableVC() {
        let modalNavi = UINavigationController()
        modalNavi.viewControllers = [editableVC]
        
        self.navigationController.present(modalNavi, animated: true) {
            switch self.editableVC {
                
            case let createVC as CreateTodoVC:
                self.output.presentedCreateVC.onNext(createVC)
                self.output.presentedEditVC.onCompleted()
            
            case let editVC as EditTodoVC:
                self.output.presentedEditVC.onNext(editVC)
                self.output.presentedEditVC.onCompleted()
            
            default:
                break
            }
        }
    }
}
