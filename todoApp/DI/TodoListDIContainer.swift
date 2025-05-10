//
//  TodoListDIContainer.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import Swinject
import UIKit
import Moya

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
        initFilter: TodoFilterType, env: DataEnvironment = .local
    ) -> TodoListVC {
  
        let dataSource:TodoDataSourceProtocol = {
            switch env {
            case .local:
                return container.resolveOrFail(TodoDataSourceProtocol.self)
            
            case .stub, .production:
                let provider = container.resolveOrFail(
                    MoyaProvider<TodoAPI>.self, name: env.rawValue
                )

                return container
                    .resolveOrFail(
                        TodoDataSourceProtocol.self,
                        argument: provider
                    )
            }
        }()

        let repo = container.resolveOrFail(TodoRepository.self, argument: dataSource)
        
        let viewModel = self.container.resolveOrFail(
            TodoListVM.self,
            arguments: initFilter, repo
        )

        return self.container.resolveOrFail(
            TodoListVC.self,
            arguments: initFilter, viewModel
        )
    }
}

final class TodoListAssembly: Assembly {
    func assemble(container: Container) {
        // vm 등록
        container.register(TodoListVM.self) {
            (resolver, initFilter: TodoFilterType, repo: TodoRepository) in

            return TodoListVM(repo, initFilter: initFilter)
        }

        // vc 등록
        container.register(TodoListVC.self) {
            (resolver, initFilter: TodoFilterType, vm: TodoListVM) in

            return TodoListVC(initFilter: initFilter, vm: vm)
        }
    }
}
