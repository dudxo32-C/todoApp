//
//  TodoRepository.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation

protocol TodoRepositoryProtocol {
    init(_ dataSource: TodoDataSourceProtocol)

    /// 할일 목록 불러오기
    /// - Throws: ``NetworkError``
    /// - Returns: `Todo` 데이터 모델 배열
    func fetchTodoList() async throws -> [TodoModelProtocol]

    /// 할일 목록 작성하기
    /// - Throws: ``NetworkError``
    /// - Returns: `Todo` 데이터 모델
    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoModelProtocol
    
    /// 할일 목록 삭제하기
    /// - Throws: ``NetworkError``, ``TodoError``
    /// - Returns: Todo 모델의 `id`
    func deleteTodo(_ id: String) async throws -> String
    
    /// 할일 목록 수정하기
    /// - Throws: ``NetworkError``, ``TodoError``
    /// - Returns: `Todo` 데이터 모델
    func updateTodo(_ todo: TodoModelProtocol) async throws -> TodoModelProtocol
}
