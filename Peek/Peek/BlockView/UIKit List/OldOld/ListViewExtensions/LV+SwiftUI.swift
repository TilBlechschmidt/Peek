//
//  LV+SwiftUI.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import UIKit
import SwiftUI

struct UIBlockListView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NewBlockListViewController {
        NewBlockListViewController()
    }

    func updateUIViewController(_ uiViewController: NewBlockListViewController, context: Context) {
        // Nothing!
    }
}
