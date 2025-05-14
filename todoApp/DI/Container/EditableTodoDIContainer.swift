//
//  File.swift
//  todoApp
//
//  Created by 조영태 on 4/8/25.
//

import Foundation
import Moya
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
                TodoUseCaseAssembly(),
            ],
            container: self.container
        )
    }

    private func makeRepository(_ env: DataEnvironment) -> TodoRepository {
        return container.resolveOrFail(TodoRepository.self, argument: env)
    }

    func makeCreateTodoVC(_ env: DataEnvironment = .local) -> CreateTodoVC {
        let repo = makeRepository(env)

        let addTodo = container.resolveOrFail(
            (any AddTodoUseCase).self, argument: repo)
        let editTodo = container.resolveOrFail(
            (any EditTodoUseCase).self, argument: repo)

        let useCase = CreateTodoVM.UseCase(addTodo: addTodo, EditTodo: editTodo)

        return container.resolveOrFail(CreateTodoVC.self, argument: useCase)
    }

    func makeEditTodoVC(
        todoModel: TodoModelProtocol, _ env: DataEnvironment = .local
    )
        -> EditTodoVC
    {
        let repo = makeRepository(env)

        let addTodo = container.resolveOrFail(
            (any AddTodoUseCase).self, argument: repo)
        let editTodo = container.resolveOrFail(
            (any EditTodoUseCase).self, argument: repo)

        let useCase = EditTodoVM.UseCase(addTodo: addTodo, EditTodo: editTodo)
        
        return container.resolveOrFail(
            EditTodoVC.self,
            arguments: useCase, todoModel
        )
    }
}

final class TodoEditableAssembly: Assembly {
    func assemble(container: Container) {
        // 생성 vm 등록
        container.register(CreateTodoVM.self) {
            (_, useCase: CreateTodoVM.UseCase) in CreateTodoVM(useCase)
        }

        // 생성 화면 등록
        container.register(CreateTodoVC.self) {
            (resolver, useCase: CreateTodoVM.UseCase) in
            let viewModel = resolver.resolveOrFail(
                CreateTodoVM.self,
                argument: useCase
            )

            return CreateTodoVC(viewModel)
        }

        // 수정 vm 등록
        container.register(EditTodoVM.self) {
            (_, useCase: CreateTodoVM.UseCase, model: TodoModelProtocol) in
            return EditTodoVM(model: model, useCase: useCase)
        }

        // 수정 화면 등록
        container.register(EditTodoVC.self) {
            (resolver, useCase: CreateTodoVM.UseCase, model: TodoModelProtocol) in
            
            let viewModel = resolver.resolveOrFail(
                EditTodoVM.self,
                arguments: useCase, model
            )
            
            return EditTodoVC(model: model, viewModel: viewModel)
        }
    }
}
