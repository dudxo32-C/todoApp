//
//  TodoUseCaseAssembly.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import Swinject

final class TodoUseCaseAssembly: Assembly {
    func assemble(container: Container) {
        container.register((any FetchTodoUseCase).self) {
            (_, repository: TodoRepository) in
            DefaultFetchTodoUseCase(repository)
        }

        container.register((any DeleteTodoUseCase).self) {
            (_, repository: TodoRepository, cache: TodoListCache) in
            DefaultDeleteTodoUseCase(repository, cache: cache)
        }

        container.register((any ToggleTodoDoneUseCase).self) {
            (_, repository: TodoRepository, cache: TodoListCache) in
            DefaultToggleTodoDoneUseCase(repository, cache: cache)
        }
        
        container.register((any AddTodoUseCase).self) {
            (_, repository: TodoRepository) in
            DefaultAddTodoUseCase(repository: repository)
        }
        
        container.register((any EditTodoUseCase).self) {
            (_, repository: TodoRepository) in
            DefaultEditTodoUseCase(repository: repository)
        }
    }
}
