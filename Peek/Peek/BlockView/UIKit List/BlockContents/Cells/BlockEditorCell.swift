//
//  BlockEditorCell.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.04.21.
//

import UIKit
import Combine
import SnapKit

struct Constants {
    static var iconSize: CGFloat = 16
    static var padding: CGFloat = 8
    static var cornerRadius: CGFloat = 5
    static var animationDuration: TimeInterval = 0.5
}

struct EditorConstants {
    #if targetEnvironment(macCatalyst)
    static var gesturesEnabled = false
    static var hardwareKeyboardMode = true
    #else
    static var gesturesEnabled = true
    static var hardwareKeyboardMode = false
    #endif
}

class BlockEditorCell: UITableViewCell {
    private var cancellables: [AnyCancellable] = []

    private let listIconView = UIImageView(image: UIImage(systemName: "list.bullet"))
    private let innerContentView = UIView()
    private var centerXConstraint: Constraint!

    var blockID: UUID!

    weak var viewController: BlockEditorViewController!
    weak var focusEngine: FocusEngine! {
        didSet {
            focusEngine.$mode
                .sink { [weak self] mode in
                    guard let self = self else { return }

                    switch mode {
                    case .focus(let focused):
                        self.focusModeDidChange(active: true, mode: mode)
                        self.focusStateDidChange(focused: focused == self.blockID)
                    case .select, .none:
                        self.focusModeDidChange(active: false, mode: mode)
                        self.focusStateDidChange(focused: false)
                    }

                    let type = self.focusEngine.selectionType(for: self.blockID, mode)
                    self.selectionTypeDidChange(to: type)
                }
                .store(in: &cancellables)
        }
    }

    // -- Methods to be called by subclasses

    func cellWasExternallyFocused() {
        focusEngine.focus(blockID)
    }

    func cellChangedLayoutHeight() {
        viewController.updateCellLayout(animate: true)
    }

    // -- Methods and fields to be overidden by subclasses

    var capturedKeyCommands: BlockEditorKeyCommands { [] }

    /// Whether or not this cell contains content after an internal cursor,
    /// which should be integrated into the previous cell on deletion or moved
    /// to the next cell on insertion of a new cell.
    var containsTrailingContent: Bool {
        false
    }

    func configureContent(in view: UIView) {}

    func focusModeDidChange(active: Bool, mode: FocusEngine.Mode) {}

    func focusStateDidChange(focused: Bool) {}

    func selectionTypeDidChange(to type: FocusEngine.SelectionType?) {
        switch type {
        case .anchor, .cursor, .incidental, .range:
            innerContentView.backgroundColor = .systemPink
        default:
            innerContentView.backgroundColor = .background
        }
    }

    // -- Fields used by the superclass logic

    var textContentView: UIView? {
        nil
    }

    // --

    override func prepareForReuse() {
        cancellables.removeAll()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        listIconView.tintColor = .label
        contentView.addSubview(listIconView)
        listIconView.snp.makeConstraints { make in
            make.width.equalTo(Constants.iconSize)
            make.height.equalTo(Constants.iconSize)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(Constants.padding)
        }

        contentView.addSubview(innerContentView)
        innerContentView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            centerXConstraint = make.centerX.equalToSuperview().constraint
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }

        if EditorConstants.gesturesEnabled {
            let panGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal, target: self, action: #selector(handlePanGesture(_:)))
            contentView.addGestureRecognizer(panGestureRecognizer)
        }

        backgroundColor = .clear
        selectionStyle = .none
        contentView.layer.cornerRadius = Constants.cornerRadius
        contentView.clipsToBounds = true

        configureContent(in: innerContentView)
        innerContentView.layer.cornerRadius = Constants.cornerRadius
        innerContentView.backgroundColor = .background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        let maximumDistance = Constants.iconSize + Constants.padding * 2
        let translationX = min(0, pan.translation(in: contentView).x)

        let percentage = abs(translationX) / maximumDistance
        let easedPercentage = atan(2 * percentage) * 0.65
        let easedTranslation = -maximumDistance * easedPercentage

        switch pan.state {
        case .began:
            self.innerContentView.backgroundColor = .interaction
            self.contentView.backgroundColor = .selection
        case .changed:
            centerXConstraint.update(offset: easedTranslation)
        case .cancelled, .failed, .ended:
            UIView.animate(withDuration: Constants.animationDuration) {
                self.contentView.backgroundColor = .clear
                self.innerContentView.backgroundColor = .background
                self.centerXConstraint.update(offset: 0)
                self.contentView.layoutIfNeeded()

                if pan.state == .ended && percentage > 0.5 {
                    self.focusEngine.toggle(self.blockID, ignoreFocus: true)
                }
            }
        default:
            ()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let modifiers = event?.modifierFlags, let touch = touches.first else { return }

        if case .focus = focusEngine.mode {
            if let textView = textContentView {
                let location = touch.location(in: textView)
                focusEngine.caret = location
            }
            focusEngine.focus(blockID, resetMoveDirection: true)
        } else if case .select = focusEngine.mode, !EditorConstants.hardwareKeyboardMode {
            focusEngine.toggle(blockID)
        } else if case .select(let cursor, let anchor, let incidentals) = focusEngine.mode {
            // When a hardware keyboard mode is enabled, selection logic is like a macOS list
            // Clicking an item selects only that item, shift+click selects up to that item, cmd+click adds to selection
            if modifiers.contains(.command) {
                focusEngine.toggle(blockID)
            } else if modifiers.contains(.shift) {
                focusEngine.moveCursor(to: blockID)
            } else if cursor == blockID, cursor == anchor, incidentals == .empty {
                // Focus ourselves and set the caret position to the touch location
                //  if there is text content
                if let textView = textContentView {
                    let location = touch.location(in: textView)
                    focusEngine.caret = location
                    focusEngine.enterFocusMode()
                } else {
                    focusEngine.enterFocusMode()
                }
            } else {
                focusEngine.deselectAll()
                focusEngine.select(blockID)
            }
        } else if case .none = focusEngine.mode, focusEngine.defaultToFocusMode, let textView = textContentView  {
            let location = touch.location(in: textView)
            focusEngine.caret = location
            focusEngine.select(blockID)
        } else {
            focusEngine.select(blockID)
        }
    }
}
