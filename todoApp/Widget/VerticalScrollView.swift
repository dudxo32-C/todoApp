//
//  ScrollView.swift
//  todoApp
//
//  Created by 조영태 on 4/3/25.
//

import Foundation
import UIKit
import Then
import SnapKit

class VerticalScrollView : UIScrollView {
    // ScrollView 내부 컨텐츠를 담는 뷰
    let contentView = UIStackView().then {
        $0.axis = .vertical
    }
    
    var contentMargins: UIEdgeInsets {
        get { contentView.layoutMargins }
        set {
            self.contentView.isLayoutMarginsRelativeArrangement = true
            contentView.layoutMargins = newValue
        }
    }
    
    var contentSpacing : CGFloat {
        get { contentView.spacing }
        set { contentView.spacing = newValue }
    }
    
    init() {
        super.init(frame: .zero)
        showsVerticalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    func addArrangedSubview(_ view: UIView) {
        contentView.addArrangedSubview(view)
    }
}
