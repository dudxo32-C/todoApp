//
//  LoadingIndicator.swift
//  todoApp
//
//  Created by 조영태 on 4/3/25.
//

import Foundation
import UIKit
import RxSwift



class LoadingIndicator: UIView {
    private let loadingIndicator = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .white
        $0.hidesWhenStopped = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.isHidden = true
        addSubview(loadingIndicator)
    }
    
    var isAnimating: Bool {
        get {
            return self.loadingIndicator.isAnimating
        }
        set (isAnimating ){
            self.isHidden = !isAnimating
            if isAnimating {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
      }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview else { return }
        
        // ✅ 부모 뷰(superview)의 크기에 맞게 자동 설정
        self.snp.makeConstraints { make in
            make.edges.equalTo(superview)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func startLoading() {
        self.isHidden = false
        loadingIndicator.startAnimating()
    }

    func stopLoading() {
        loadingIndicator.stopAnimating()
        self.isHidden = true
    }
}
