//
//  File.swift
//  todoApp
//
//  Created by 조영태 on 4/8/25.
//

import Foundation
import Swinject


class EditableTodoDIContainer {
    private let container: Container
    private let assembler: Assembler

    init(parentContainer: Container? = nil) {
        self.container = Container(parent: parentContainer)

        self.assembler = Assembler(
            [TodoEditableAssembly()],
            container: self.container
        )
    }

    func makeCreateTodoVC(_ type: DataEnvironment = .mock) -> CreateTodoVC {
        return assembler.resolver.resolve(CreateTodoVC.self, argument: type)!
    }

    func makeEditTodoVC(
        todoModel: TodoModelProtocol,
        _ type: DataEnvironment = .mock
    ) -> EditTodoVC {
        return assembler.resolver.resolve(EditTodoVC.self, arguments: type, todoModel)!
    }
}

final class TodoEditableAssembly: Assembly {
    func assemble(container: Container) {
        // Repository 등록
        container.register(TodoDS.self) { _ in
            TodoDS()
        }.inObjectScope(.container)

        // Mock Repository 등록
        container.register(MockTodoDS.self) { _ in
            MockTodoDS()
        }.inObjectScope(.container)

        // 생성 vm 등록
        container.register(CreateTodoVM.self) { (r, env: DataEnvironment) in
            let repo = self.getRepository(resolver: r, env)

            return CreateTodoVM(repo)
        }
        
        // 생성 화면 등록
        container.register(CreateTodoVC.self) { (r, env: DataEnvironment) in
            let vm = r.resolve(CreateTodoVM.self, argument: env)!

            return CreateTodoVC(vm)
        }

        
        // 수정 vm 등록
        container.register(EditTodoVM.self) {
            (r, env: DataEnvironment, model: TodoModelProtocol) in
            let repo = self.getRepository(resolver: r, env)

            return EditTodoVM(model: model, repository: repo)
        }
   
        // 수정 화면 등록
        container.register(EditTodoVC.self) {
            (r, env: DataEnvironment, model: TodoModelProtocol) in
            let vm = r.resolve(EditTodoVM.self, arguments: env, model)!

            return EditTodoVC(model: model, viewModel: vm)
        }
    }

    private func getRepository(resolver: Resolver, _ env: DataEnvironment)
        -> TodoRepo
    {
        let dataSource: TodoDataSourceProvider = {
            switch env {
            case .mock:
                return resolver.resolve(MockTodoDS.self)!
            case .real:
                return resolver.resolve(TodoDS.self)!
            }
        }()

        return TodoRepo(dataSource)
    }

}
