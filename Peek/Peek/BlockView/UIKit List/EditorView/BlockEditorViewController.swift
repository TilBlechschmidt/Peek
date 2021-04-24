//
//  BlockEditorView.swift
//  Peek
//
//  Created by Til Blechschmidt on 13.04.21.
//

import UIKit
import Combine
import SnapKit

import SwiftUI

protocol BlockEditorDelegate: FocusEngineDelegate {
    var instance: UUID { get }
    
    // Content list
    var blocks: CurrentValueSubject<[ContentBlock], Never> { get }
    func content(for id: UUID) -> ContentBlock?

    // Cell management
    func cellTypes() -> [String : BlockEditorCell.Type]
    func cellIdentifier(for block: UUID) -> String
    func configure(cell: BlockEditorCell, for block: UUID)

    // Content modification
    func newBlock(forInsertionAfter id: UUID) -> ContentBlock
    func insert(_ block: ContentBlock, at index: Int)
    func insert(_ block: ContentBlock, before id: UUID)
    func insert(blocks: [ContentBlock], before id: UUID)
    func insert(_ block: ContentBlock, after id: UUID)
    func insert(blocks: [ContentBlock], after id: UUID)
    func append(_ block: ContentBlock)
    func move(blockWithID id: UUID, after other: UUID, animate: Bool)
    func remove(_ id: UUID)
    func removeAll(in collection: [UUID])
}

class BlockEditorDragState {
    /// DO NOT SET THIS VARIABLE DIRECTLY
    @Published private(set) var active: Bool = false
    @Published var dragActive: Bool = false { didSet { active = dragActive || dropActive } }
    @Published var dropActive: Bool = false { didSet { active = dragActive || dropActive } }
    @Published var participatingBlocks = Set<UUID>()
    @Published var target: (id: UUID, above: Bool)? = nil
}

class BlockEditorViewController: UITableViewController {
    var dataSource: UITableViewDiffableDataSource<Section, UUID>! = nil
    var currentSnapshot: NSDiffableDataSourceSnapshot<Section, UUID>! = nil

    private var cancellables: [AnyCancellable] = []
    private var insertionView = UIView()
    private var insertionConstraint: Constraint?

    internal let focusEngine = FocusEngine()
    internal let dragState = BlockEditorDragState()
    weak var delegate: BlockEditorDelegate? {
        didSet {
            delegate?.cellTypes().forEach { (identifier, type) in
                tableView.register(type, forCellReuseIdentifier: identifier)
            }
            configureObservers()

            focusEngine.delegate = delegate
            focusEngine.deselectAll()
            updateData(animate: false)
        }
    }

    init() {
        #if targetEnvironment(macCatalyst)
        focusEngine.defaultToFocusMode = false
        #endif

        super.init(style: .plain)

        focusEngine.selectionDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // We are setting an arbitrary height to prevent constraint issues during view loading
        // as the insertionViews width is tied to the tableView's width - 16 which obviously fails
        // when the tableView has a width of 0.
        let tableView = BlockTableView(frame: .init(origin: .zero, size: CGSize(width: 100, height: 0)))
        tableView.delegate = self
        tableView.viewController = self
        tableView.focusEngine = focusEngine
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureInsertionView()
        configureDataSource()
        configureObservers()
        configureDragInteraction()
        configureDropInteraction()
    }

    override func viewDidAppear(_ animated: Bool) {
        updateData(animate: false)
    }
}

extension BlockEditorViewController {
    enum Section: CaseIterable {
        case main
    }

    func updateData(animate: Bool = true) {
        currentSnapshot = NSDiffableDataSourceSnapshot<Section, UUID>()

        let blockIDs: [UUID] = delegate?.allItems() ?? []

        currentSnapshot.appendSections([.main])
        currentSnapshot.appendItems(blockIDs, toSection: .main)

        dataSource.apply(currentSnapshot, animatingDifferences: animate)
    }

    func configureCell(for id: UUID, useReusableCell: Bool = true) -> UITableViewCell? {

        guard let identifier = delegate?.cellIdentifier(for: id),
              let delegate = delegate,
              let cell = useReusableCell ? (
                  tableView.dequeueReusableCell(withIdentifier: identifier) as? BlockEditorCell
              ) : (
                  delegate.cellTypes()[identifier]!.init()
              )
        else { return nil }

        cell.viewController = self
        cell.blockID = id
        cell.focusEngine = focusEngine
        cell.dragState = dragState
        delegate.configure(cell: cell, for: id)

        return cell
    }

    func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, UUID>(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, blockID: UUID) -> UITableViewCell? in
            self?.configureCell(for: blockID)
        }

        dataSource.defaultRowAnimation = .fade
    }

    func configureTableView() {
        view.backgroundColor = .clear
        tableView.clipsToBounds = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
    }

    func configureInsertionView() {
        let height: CGFloat = 2.5

        insertionView.alpha = 0
        insertionView.backgroundColor = .accentColor
        insertionView.layer.cornerRadius = height / 2

        tableView.addSubview(insertionView)
        insertionView.snp.makeConstraints { make in
            make.height.equalTo(height)
            make.width.equalToSuperview().inset(Constants.padding)
            make.centerX.equalToSuperview()
        }
    }

    func attachInsertionView(to cell: UIView, above: Bool) {
        tableView.bringSubviewToFront(insertionView)
        insertionConstraint?.deactivate()
        insertionView.snp.makeConstraints { make in
            if above {
                insertionConstraint = make.bottom.equalTo(cell.snp.top).offset(insertionView.frame.height / 2).constraint
            } else {
                insertionConstraint = make.top.equalTo(cell.snp.bottom).offset(-insertionView.frame.height / 2).constraint
            }
        }
    }

    func detachInsertionView() {
        // Pin the insertionView to its current position relative to the tableView
        let frame = insertionView.frame
        insertionConstraint?.deactivate()
        insertionView.snp.makeConstraints { make in
            insertionConstraint = make.top.equalToSuperview().inset(frame.minY).constraint
        }
        tableView.layoutIfNeeded()

        // Fade the insertionView out and remove the pinning once done
        UIView.animate(withDuration: Constants.animationDuration) {
            self.insertionView.alpha = 0
        }
    }

    func configureObservers() {
        cancellables.removeAll()

        delegate?.blocks
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateData()
                }
            }
            .store(in: &cancellables)

//        focusEngine.$mode
//            .sink { [weak self] mode in
//                // TODO Add a proper UI element for this and a "done" button
//                if case .select = mode {
//                    self?.tableView.backgroundColor = .brown
//                } else {
//                    self?.tableView.backgroundColor = .clear
//                }
//            }
//            .store(in: &cancellables)

        dragState.$dropActive
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.detachInsertionView()
            }
            .store(in: &cancellables)

        dragState.$target
            .sink { [weak self] target in
                guard let s = self, let target = target else {
                    self?.detachInsertionView()
                    return
                }

                if let cell = s.cell(for: target.id) {
                    s.attachInsertionView(to: cell, above: target.above)
                }

                // Do not animate when the previous value is nil
                let duration = s.dragState.target == nil ? 0 : Constants.animationDuration / 2

                UIView.animate(withDuration: duration) {
                    self?.insertionView.alpha = 1
                    s.tableView.layoutIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    func updateCellLayout(animate: Bool) {
        // Reload the same snapshot to force the layout system to re-think its existence :D
        let snapshot = dataSource.snapshot()
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    func cell(for block: UUID) -> BlockEditorCell? {
        guard let sectionIndex = currentSnapshot.indexOfSection(.main),
              let itemIndex = currentSnapshot.indexOfItem(block) else {
            return nil
        }

        let indexPath = IndexPath(item: itemIndex, section: sectionIndex)

        return tableView.cellForRow(at: indexPath) as? BlockEditorCell
    }
}

struct UIBlockListView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BlockEditorViewController {
        let editorView = BlockEditorViewController()
        editorView.delegate = context.coordinator.blockManager

        return editorView
    }

    func updateUIViewController(_ uiViewController: BlockEditorViewController, context: Context) {
        // Nothing!
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let blockManager: BlockManager

        init() {
            blockManager = BlockManager([
                TextContentBlock(text: "Hello world 1"),
                TextContentBlock(text: "Hello world 2"),
                TextContentBlock(text: "Hello world 3"),
                TextContentBlock(text: "Hello world 4"),
                TextContentBlock(text: "Hello world 5"),
            ])
        }
    }
}
