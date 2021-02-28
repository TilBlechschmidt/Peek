//
//  PeekApp.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import SwiftUI

@main
struct PeekApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ContentView().edgesIgnoringSafeArea(.init())
                    Spacer()
                }
                Spacer()
            }
                .background(Color.background)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
