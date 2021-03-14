//
//  NewBlockListViewController.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import MarkdownKit
import SwiftUI
import Combine

private class CustomTableView: UITableView {
    override var keyCommands: [UIKeyCommand]? {
        return nil
    }
}

class NewBlockListViewController: UITableViewController {
    var dataSource: UITableViewDiffableDataSource<Section, UUID>! = nil
    var currentSnapshot: NSDiffableDataSourceSnapshot<Section, UUID>! = nil

    internal var activeModifierFlags: UIKeyModifierFlags = []
    private var cancellables: [AnyCancellable] = []
    internal let editorState = EditorState(blockManager: .withDemoData)

    override func loadView() {
        let tableView = CustomTableView(frame: .zero)
        tableView.delegate = self
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureDataSource()
        configureObservers()

        editorState.blockManager.delegate = self

        #if targetEnvironment(macCatalyst)
            editorState.isEditingContent = false
        #else
            editorState.isEditingContent = true
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        updateData(animate: false)
    }
}

extension NewBlockListViewController {
    enum Section: CaseIterable {
        case main
    }

    func updateData(animate: Bool = true) {
        currentSnapshot = NSDiffableDataSourceSnapshot<Section, UUID>()

        let blockIDs = editorState.blockManager.blockIDs

        currentSnapshot.appendSections([.main])
        currentSnapshot.appendItems(blockIDs, toSection: .main)

        dataSource.apply(currentSnapshot, animatingDifferences: animate)
    }

    func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, UUID>(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, blockID: UUID) -> UITableViewCell? in

            guard let block = self?.editorState.blockManager[blockID], let cell = tableView.dequeueReusableCell(matching: block, for: indexPath) else {
                return nil
            }

            cell.delegate = self
            cell.editorState = self?.editorState
            cell.block = block

            return cell
        }

        dataSource.defaultRowAnimation = .fade
    }

    func configureTableView() {
        view.backgroundColor = .clear
        tableView.allowsSelection = true
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.register(BlockCell.self, forCellReuseIdentifier: BlockCell.reuseIdentifier)
        tableView.register(TextBlockCell.self, forCellReuseIdentifier: TextBlockCell.reuseIdentifier)
    }

    func configureObservers() {
        editorState.$isEditingContent
            .sink { [weak self] isEditingContent in
                if isEditingContent {
                    self?.editorState.focusEngine.deselectAll()
                }
            }
            .store(in: &cancellables)

        editorState.focusEngine.$cursor
            .sink { [weak self] cursor in
                if let cursor = cursor, let self = self, let indexPath = self.dataSource.indexPath(for: cursor) {
                    self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                }
            }
            .store(in: &cancellables)

        editorState.blockManager.$blockIDs
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateData()
                }
            }
            .store(in: &cancellables)
    }
}

extension NewBlockListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !editorState.isEditingContent, let identifier = dataSource.itemIdentifier(for: indexPath) {
            // TODO Add SHIFT click (aka select from anchor to clicked item)
            editorState.focusEngine.toggle(identifier, deselectOther: isRunningOnMac && !activeModifierFlags.contains(.command))
        }
    }
}
