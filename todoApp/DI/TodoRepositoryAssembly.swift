//
//  TodoRepositoryAssembly.swift
//  todoApp
//
//  Created by 조영태 on 5/1/25.
//

import Foundation
import Swinject

final class TodoRepositoryAssembly: Assembly {
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
