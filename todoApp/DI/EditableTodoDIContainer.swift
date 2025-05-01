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
                TodoEditRepositoryAssembly(),
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

final class TodoEditRepositoryAssembly: Assembly {
    func assemble(container: Container) {
#if DEBUG
        // Mock DataSource 등록
        container.register(MockTodoDS.self) { _ in
            MockTodoDS()
        }.inObjectScope(.container)
#endif
        
        // DataSource 등록
        container.register(TodoDS.self) { _ in
            TodoDS()
        }.inObjectScope(.container)
        // Repository 등록
        container.register(TodoRepo.self) { (r, env: DataEnvironment) in
            let dataSource: TodoDataSourceProvider = {
                switch env {
                case .mock:
                    return r.resolve(MockTodoDS.self)!
                case .real:
                    return r.resolve(TodoDS.self)!
                }
            }()
            
            return TodoRepo(dataSource)
        }.inObjectScope(.container)
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
