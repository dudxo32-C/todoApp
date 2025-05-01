//
//  TodoListDIContainer.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import Swinject
import UIKit

class TodoListDIContainer {
    private let container: Container
    private let assembler: Assembler

    init(parentContainer: Container? = nil) {
        self.container = Container(parent: parentContainer)

        self.assembler = Assembler(
            [
                TodoRepositoryAssembly(),
                TodoListAssembly(),
            ],
            container: self.container
        )
    }

    func makeTodoListVC(
        initFilter: TodoFilterType, env: DataEnvironment = .mock
    ) -> TodoListVC {
        let vm = self.container.resolveOrFail(
            TodoListVM.self,
            arguments: initFilter, env
        )

        return self.container.resolveOrFail(
            TodoListVC.self,
            arguments: initFilter, vm
        )
    }
}

final class TodoListAssembly: Assembly {
    func assemble(container: Container) {
        // vm 등록
        container.register(TodoListVM.self) {
            (resolver, initFilter: TodoFilterType, env: DataEnvironment) in

            let repo = resolver.resolveOrFail(TodoRepo.self, argument: env)
            return TodoListVM(repo, initFilter: initFilter)
        }

        // vc 등록
        container.register(TodoListVC.self) {
            (resolver, initFilter: TodoFilterType, vm: TodoListVM) in

            return TodoListVC(initFilter: initFilter, vm: vm)
        }
    }
}
