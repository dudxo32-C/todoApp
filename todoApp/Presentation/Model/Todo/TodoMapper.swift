//
//  TodoMapper.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation

struct TodoMapper {
    static func toEntity(_ model: TodoModelProtocol) -> Todo {
        return TodoImpl(
            id: model.id,
            title: model.title,
            date: model.date,
            contents: model.contents,
            isDone: model.isDone
        )
    }
    
    static func toModel(_ entity: Todo) -> TodoModel {
        return TodoModel(
            id: entity.id,
            title: entity.title,
            date: entity.date,
            contents: entity.contents,
            isDone: entity.isDone
        )
    }
}
