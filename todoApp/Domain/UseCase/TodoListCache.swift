//
//  TodoListCache.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation

final class TodoListCache {
    enum Error: Swift.Error {
        case notFound
    }
    func deleteItemInList(_ removedID: String, list: [Todo]) -> [Todo] {
        let removedList = list.filter { $0.id != removedID }

        return removedList
    }

    func addItemInList(_ newTodo: Todo, list: [Todo]) -> [Todo] {
        return list + [newTodo]
    }

    /// 주어진 list 에서 newTodo를 변경
    /// - Throws: ``TodoListCache.Error``
    func changeItemInList(_ newTodo: Todo, list: [Todo]) throws -> [Todo] {
        var currentAll = list

        let targetIndex = currentAll.firstIndex { $0.id == newTodo.id }
        guard let index = targetIndex else { throw Error.notFound }

        currentAll[index] = newTodo

        return currentAll
    }
}
