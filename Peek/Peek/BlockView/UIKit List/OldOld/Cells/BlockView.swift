//
//  BlockView.swift
//  Peek
//
//  Created by Til Blechschmidt on 08.03.21.
//

import UIKit
import SnapKit

struct Constant {
    static let admonitionWidth: CGFloat = 5
    static let defaultPadding: CGFloat = 16
    static let blockquoteCornerRadius: CGFloat = admonitionWidth
}

class BlockView: UIView {
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
            updateSelection()
        }
    }

    var selected: Bool = false {
        didSet {
            updateSelection()
        }
    }

    var displaySelectionBox: Bool = false {
        didSet {
            selectionBoxView.isHidden = !displaySelectionBox
            updateInsets()
        }
    }

    var connection: Connection = [] { didSet { updateInsets() } }

    let contentView = UIView()
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

    private let selectionView = UIView()
    private let selectionBoxView = SelectionBoxView()

    init(_ layoutChangeHandler: (() -> Void)?) {
        super.init(frame: .zero)
        setupUI()
        updateInsets()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        updateInsets()
        updateSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Admonition view
        admonitionView.isHidden = true
        admonitionView.backgroundColor = .accentColor
        admonitionView.layer.cornerRadius = Constant.admonitionWidth / 2
        admonitionView.clipsToBounds = true
        admonitionView.isUserInteractionEnabled = false
        addSubview(admonitionView)
        admonitionView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.equalTo(Constant.admonitionWidth)
            admonitionTopConstraint = make.top.equalToSuperview().constraint
            admonitionBottomConstraint = make.bottom.equalToSuperview().priority(.low).constraint
        }

        // Blockquote view
        blockquoteView.isHidden = true
        blockquoteView.backgroundColor = .blockquote
        blockquoteView.layer.cornerRadius = Constant.blockquoteCornerRadius
        blockquoteView.layer.borderColor = UIColor.selection.cgColor
        blockquoteView.clipsToBounds = true
        blockquoteView.isUserInteractionEnabled = false
        addSubview(blockquoteView)
        blockquoteView.snp.makeConstraints { make in
            blockquoteTopConstraint = make.top.equalToSuperview().constraint
            blockquoteBottomConstraint = make.bottom.equalToSuperview().priority(.low).constraint
            make.leading.equalToSuperview().inset(Constant.defaultPadding)
            make.trailing.equalToSuperview()
        }

        // Selection box view
        selectionBoxView.isHidden = true
        addSubview(selectionBoxView)
        selectionBoxView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Constant.defaultPadding)
            make.centerY.equalToSuperview()
            make.height.equalTo(Constant.defaultPadding * 1.5)
            make.width.equalTo(Constant.defaultPadding * 1.5)
        }

        // Content view
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            leadingConstraint = make.left.equalToSuperview().constraint
            trailingConstraint = make.right.equalToSuperview().constraint
            topConstraint = make.top.equalToSuperview().constraint
            bottomConstraint = make.bottom.equalToSuperview().priority(.low).constraint
        }

        // Selection view
        selectionView.layer.cornerRadius = Constant.blockquoteCornerRadius
        selectionView.clipsToBounds = true
        selectionView.isUserInteractionEnabled = false
        addSubview(selectionView)
        sendSubviewToBack(selectionView)
        selectionView.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(-Constant.defaultPadding / 2)
            make.bottom.equalTo(contentView).inset(-Constant.defaultPadding / 2)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    private var leadingInset: CGFloat {
        let blockquoteInset = blockquote ? Constant.defaultPadding : 0
        return Constant.defaultPadding + blockquoteInset
    }

    private var trailingInset: CGFloat {
        let selectionInset = displaySelectionBox ? Constant.defaultPadding * 3.5 : 0
        return Constant.defaultPadding + selectionInset
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
        trailingConstraint.update(inset: trailingInset)
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

    private func updateSelection() {
        selectionBoxView.selected = selected

        if blockquote {
            blockquoteView.layer.borderWidth = selected ? 1 : 0
            selectionView.backgroundColor = nil
        } else {
            blockquoteView.layer.borderWidth = 0
            selectionView.backgroundColor = selected ? UIColor.selection.withAlphaComponent(0.15) : nil
        }
    }
}

class SelectionBoxView: UIView {
    var selected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        UIColor.selection.setFill()
        UIColor.selection.setStroke()

//        let inset: CGFloat = selected ? 0 : 2
//        let circle = UIBezierPath(ovalIn: rect.inset(by: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)))
//
//        if selected {
//            circle.fill()
//        } else {
//            circle.lineWidth = inset
//            circle.stroke()
//        }

        // Circle with inner circle
        let outerCircleWidth: CGFloat = 2
        let outerCircleInset = UIEdgeInsets(top: outerCircleWidth, left: outerCircleWidth, bottom: outerCircleWidth, right: outerCircleWidth)
        let innerCircleInset = UIEdgeInsets(top: outerCircleWidth * 3, left: outerCircleWidth * 3, bottom: outerCircleWidth * 3, right: outerCircleWidth * 3)


        // Outer circle
        let outerPath = UIBezierPath(ovalIn: rect.inset(by: outerCircleInset))
        outerPath.lineWidth = outerCircleWidth
        outerPath.stroke()

        // Inner circle
        if selected {
            let innerPath = UIBezierPath(ovalIn: rect.inset(by: innerCircleInset))
            innerPath.fill()
        }
    }
}
