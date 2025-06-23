import AppKit
import SwiftUI

class EdgeTrackingView: NSView {
    
    enum Edge {
        case top, bottom, left, right
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove existing tracking areas to avoid duplicates
        trackingAreas.forEach { removeTrackingArea($0) }
        
        // Define the thickness of the edge for tracking
        let edgeThickness: CGFloat = 10.0
        
        // Create tracking areas for each edge
        let topRect = NSRect(x: 0, y: bounds.height - edgeThickness, width: bounds.width, height: edgeThickness)
        let bottomRect = NSRect(x: 0, y: 0, width: bounds.width, height: edgeThickness)
        let leftRect = NSRect(x: 0, y: 0, width: edgeThickness, height: bounds.height)
        let rightRect = NSRect(x: bounds.width - edgeThickness, y: 0, width: edgeThickness, height: bounds.height)

        addTrackingArea(for: topRect, edge: .top)
        addTrackingArea(for: bottomRect, edge: .bottom)
        addTrackingArea(for: leftRect, edge: .left)
        addTrackingArea(for: rightRect, edge: .right)
    }

    private func addTrackingArea(for rect: NSRect, edge: Edge) {
        let area = NSTrackingArea(rect: rect,
                                  options: [.mouseEnteredAndExited, .activeInActiveApp],
                                  owner: self,
                                  userInfo: ["edge": edge])
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        guard let userInfo = event.trackingArea?.userInfo,
              let edge = userInfo["edge"] as? Edge else {
            return
        }
        
        switch edge {
        case .top, .bottom:
            NSCursor.resizeUpDown.push()
        case .left, .right:
            NSCursor.resizeLeftRight.push()
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.pop()
    }
} 