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
    
    func makeCreateTodoVC(_ env: DataEnvironment = .mock) -> CreateTodoVC {
        return assembler.resolver.resolveOrFail(CreateTodoVC.self, argument: env)
    }
    
    func makeEditTodoVC(todoModel: TodoModelProtocol, _ env: DataEnvironment = .mock)
    -> EditTodoVC
    {
        return assembler.resolver.resolveOrFail(
            EditTodoVC.self,
            arguments: env, todoModel
        )
    }
}

final class TodoEditableAssembly: Assembly {
    func assemble(container: Container) {
        // 생성 vm 등록
        container.register(CreateTodoVM.self) { (r, env: DataEnvironment) in
            let repo = r.resolveOrFail(TodoRepo.self, argument: env)
            
            return CreateTodoVM(repo)
        }
        
        // 생성 화면 등록
        container.register(CreateTodoVC.self) { (r, env: DataEnvironment) in
            let vm = r.resolveOrFail(CreateTodoVM.self, argument: env)
            
            return CreateTodoVC(vm)
        }
        
        // 수정 vm 등록
        container.register(EditTodoVM.self) {
            (r, env: DataEnvironment, model: TodoModelProtocol) in
            let repo = r.resolveOrFail(TodoRepo.self, argument: env)
            
            return EditTodoVM(model: model, repository: repo)
        }
        
        // 수정 화면 등록
        container.register(EditTodoVC.self) {
            (r, env: DataEnvironment, model: TodoModelProtocol) in
            let vm = r.resolveOrFail(EditTodoVM.self, arguments: env, model)
            
            return EditTodoVC(model: model, viewModel: vm)
        }
    }
}
