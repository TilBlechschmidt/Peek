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
    // Content list
    var blockIDs: CurrentValueSubject<[UUID], Never> { get }

    // Cell management
    func registerCells(with tableView: UITableView)
    func cellIdentifier(for block: UUID) -> String
    func configure(cell: BlockEditorCell, for block: UUID)
}

class BlockEditorViewController: UITableViewController {
    var dataSource: UITableViewDiffableDataSource<Section, UUID>! = nil
    var currentSnapshot: NSDiffableDataSourceSnapshot<Section, UUID>! = nil

    private var cancellables: [AnyCancellable] = []

    private let focusEngine = FocusEngine()

    weak var delegate: BlockEditorDelegate? {
        didSet {
            delegate?.registerCells(with: tableView)
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let tableView = BlockTableView(frame: .zero)
        tableView.delegate = self
        tableView.viewController = self
        tableView.focusEngine = focusEngine
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureDataSource()
        configureObservers()
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

    func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, UUID>(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, blockID: UUID) -> UITableViewCell? in
            guard let identifier = self?.delegate?.cellIdentifier(for: blockID), let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? BlockEditorCell else {
                return nil
            }

            cell.viewController = self
            cell.blockID = blockID
            cell.focusEngine = self?.focusEngine
            self?.delegate?.configure(cell: cell, for: blockID)

            return cell
        }

        dataSource.defaultRowAnimation = .fade
    }

    func configureTableView() {
        view.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
    }

    func configureObservers() {
        cancellables.removeAll()

        delegate?.blockIDs
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateData()
                }
            }
            .store(in: &cancellables)

        focusEngine.$mode
            .sink { [weak self] mode in
                // TODO Add a proper UI element for this and a "done" button
                if case .select = mode {
                    self?.tableView.backgroundColor = .brown
                } else {
                    self?.tableView.backgroundColor = .clear
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
                UUID(),
                UUID(),
                UUID(),
                UUID(),
                UUID(),
                UUID()
            ])
        }
    }
}
