//
//  UIBlockView.swift
//  Peek
//
//  Created by Til Blechschmidt on 02.03.21.
//

import UIKit
import MarkdownKit
import SnapKit
import SwiftUI

struct Constant {
    static let admonitionWidth: CGFloat = 5
    static let defaultPadding: CGFloat = 16
    static let blockquoteCornerRadius: CGFloat = admonitionWidth
}

struct Connection: OptionSet, Hashable {
    let rawValue: Int

    static let previous = Connection(rawValue: 1 << 0)
    static let next     = Connection(rawValue: 1 << 1)
    
    var cornersWithRadius: CACornerMask {
        var set: CACornerMask = []

        if !contains(.previous) {
            set.insert(.layerMaxXMinYCorner)
            set.insert(.layerMinXMinYCorner)
        }

        if !contains(.next) {
            set.insert(.layerMaxXMaxYCorner)
            set.insert(.layerMinXMaxYCorner)
        }

        return set
    }
}

class UIBlockView: UIView {
    var admonition: Bool = false {
        didSet {
            admonitionView.isHidden = !admonition
            updateInsets()
        }
    }

    var blockquote: Bool = false {
        didSet {
            blockquoteView.isHidden = !blockquote
            updateInsets()
        }
    }

    var connection: Connection = [] { didSet { updateInsets() } }

    var content: Block.Content {
        get {
            contentView.content
        }
        set {
            contentView.delegate = delegate
            contentView.content = newValue
        }
    }

    weak var delegate: BlockInteractionDelegate? {
        didSet {
            contentView.delegate = delegate
        }
    }

    private let contentView = UIBlockContentView()
    private var leadingConstraint: Constraint!
    private var trailingConstraint: Constraint!
    private var topConstraint: Constraint!
    private var bottomConstraint: Constraint!
    
    private let admonitionView = UIView()
    private var admonitionTopConstraint: Constraint!
    private var admonitionBottomConstraint: Constraint!
    
    private let blockquoteView = UIView()
    private var blockquoteTopConstraint: Constraint!
    private var blockquoteBottomConstraint: Constraint!

    override var canBecomeFirstResponder: Bool {
        contentView.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        contentView.becomeFirstResponder()
    }

    init(_ layoutChangeHandler: (() -> Void)?) {
        super.init(frame: .zero)
        contentView.delegate = delegate
        contentView.updateContentView()
        setupUI()
        updateInsets()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        updateInsets()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Admonition view
        admonitionView.isHidden = true
        admonitionView.backgroundColor = UIColor(named: "AccentColor")
        admonitionView.layer.cornerRadius = Constant.admonitionWidth / 2
        admonitionView.clipsToBounds = true
        addSubview(admonitionView)
        admonitionView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.equalTo(Constant.admonitionWidth)
            admonitionTopConstraint = make.top.equalToSuperview().constraint
            admonitionBottomConstraint = make.bottom.equalToSuperview().priority(.low).constraint
        }
        
        // Blockquote view
        blockquoteView.isHidden = true
        blockquoteView.backgroundColor = UIColor(named: "Blockquote")
        blockquoteView.layer.cornerRadius = Constant.blockquoteCornerRadius
        blockquoteView.clipsToBounds = true
        addSubview(blockquoteView)
        blockquoteView.snp.makeConstraints { make in
            blockquoteTopConstraint = make.top.equalToSuperview().constraint
            blockquoteBottomConstraint = make.bottom.equalToSuperview().priority(.low).constraint
            make.leading.equalToSuperview().inset(Constant.defaultPadding)
            make.trailing.equalToSuperview()
        }

        // Content view
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            leadingConstraint = make.left.equalToSuperview().constraint
            trailingConstraint = make.right.equalToSuperview().constraint
            topConstraint = make.top.equalToSuperview().constraint
            bottomConstraint = make.bottom.equalToSuperview().priority(.low).constraint
        }
    }
    
    private var leadingInset: CGFloat {
        let blockquoteInset = blockquote ? Constant.defaultPadding : 0
        return Constant.defaultPadding + blockquoteInset
    }
    
    private var topInset: CGFloat {
        let connectionInset = blockquote && !connection.contains(.previous) ? Constant.defaultPadding : 0
        return Constant.defaultPadding + connectionInset
    }
    
    private var bottomInset: CGFloat {
        let connectionInset = blockquote && !connection.contains(.next) ? Constant.defaultPadding : 0
        return Constant.defaultPadding + connectionInset
    }
    
    private func updateInsets() {
        // Content
        leadingConstraint.update(inset: leadingInset)
        trailingConstraint.update(inset: Constant.defaultPadding)
        topConstraint.update(inset: topInset)
        bottomConstraint.update(inset: bottomInset)
        
        // Admonition
        admonitionView.layer.maskedCorners = connection.cornersWithRadius
        admonitionTopConstraint.update(inset: connection.contains(.previous) ? 0 : Constant.defaultPadding / 2)
        admonitionBottomConstraint.update(inset: connection.contains(.next) ? 0 : Constant.defaultPadding / 2)
        
        // Blockquote
        blockquoteView.layer.maskedCorners = connection.cornersWithRadius
        blockquoteTopConstraint.update(inset: connection.contains(.previous) ? 0 : Constant.defaultPadding)
        blockquoteBottomConstraint.update(inset: connection.contains(.next) ? 0 : Constant.defaultPadding)
    }

    func select(offset: Int?) {
        contentView.select(offset: offset)
    }
}

protocol BlockInteractionDelegate: class {
    func blockRequestsDeletion()
    func blockRequestsNewParagraph()
    func blockDidChangeLayout()
}
