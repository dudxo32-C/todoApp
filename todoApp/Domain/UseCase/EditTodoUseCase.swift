//
//  EditTodoUseCase.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation

protocol EditTodoUseCase {
    associatedtype Error: Swift.Error
    var repository: TodoRepository { get }
    
    /// Todo 수정하기
    /// - Throws: ``EditTodoUseCase.Error``
    func execute(_ target:Todo, newTitle:String?, newDate:Date?, newContents:String?) async throws -> Todo
}

final class DefaultEditTodoUseCase: EditTodoUseCase {
    enum Error: Swift.Error {
        case notFound
    }

    var repository: any TodoRepository
    init(repository: any TodoRepository) {
        self.repository = repository
    }
    
    func execute(_ target:Todo, newTitle:String?, newDate:Date?, newContents:String? ) async throws -> Todo {
        do {
            
            let newTodo  = Todo(
                id: target.id,
                title: newTitle ?? target.title,
                date: newDate ?? target.date,
                contents: newContents ?? target.contents,
                isDone: target.isDone
            )
            
            let response = try await repository.updateTodo(
                id: newTodo.id,
                title: newTodo.title,
                contents: newTodo.contents,
                date: newTodo.date,
                isDone: newTodo.isDone
            )
            
            return response
        } catch TodoError.notFound {
            // DataLayer Error Mapping
            throw Error.notFound
        } catch {
            // Network Error 전달
            throw error
        }
    }
    
}

