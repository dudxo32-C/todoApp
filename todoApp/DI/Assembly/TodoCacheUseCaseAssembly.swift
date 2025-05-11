//
//  TodoCacheUseCaseAssembly.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import Swinject

final class TodoCacheAssembly: Assembly {
    func assemble(container: Container) {
        container.register(TodoListCache.self) { _ in
            TodoListCache()
        }
    }
}
