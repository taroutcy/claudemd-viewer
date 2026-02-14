//
//  ClaudeMDViewerApp.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import SwiftUI

@main
struct ClaudeMDViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
