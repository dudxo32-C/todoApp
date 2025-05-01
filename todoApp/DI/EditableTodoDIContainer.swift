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
            [
                TodoRepositoryAssembly(),
                TodoEditableAssembly(),
            ],
            container: self.container
        )
    }

    private func makeRepository(_ env: DataEnvironment) -> TodoRepo {
        return assembler.resolver.resolveOrFail(TodoRepo.self, argument: env)
    }

    func makeCreateTodoVC(_ env: DataEnvironment = .mock) -> CreateTodoVC {
        let repo = makeRepository(env)

        let vm = assembler.resolver.resolveOrFail(
            CreateTodoVM.self,
            argument: repo
        )

        return assembler.resolver
            .resolveOrFail(CreateTodoVC.self, argument: vm)
    }

    func makeEditTodoVC(todoModel: TodoModelProtocol, _ env: DataEnvironment = .mock)
    -> EditTodoVC
    {
        let repo = makeRepository(env)

        let vm = assembler.resolver.resolveOrFail(
            EditTodoVM.self,
            arguments: repo, todoModel
        )

        return assembler.resolver.resolveOrFail(
            EditTodoVC.self,
            arguments: vm, todoModel
        )
    }
}

final class TodoEditableAssembly: Assembly {
    func assemble(container: Container) {
        // 생성 vm 등록
        container.register(CreateTodoVM.self) { (_, repo: TodoRepo) in
            CreateTodoVM(repo)
        }

        // 생성 화면 등록
        container.register(CreateTodoVC.self) { (_, vm: CreateTodoVM) in
            CreateTodoVC(vm)
        }

        // 수정 vm 등록
        container.register(EditTodoVM.self) {
            (_, repo: TodoRepo, model: TodoModelProtocol) in
            return EditTodoVM(model: model, repository: repo)
        }

        // 수정 화면 등록
        container.register(EditTodoVC.self) {
            (_, vm: EditTodoVM, model: TodoModelProtocol) in
            return EditTodoVC(model: model, viewModel: vm)
        }
    }
}
