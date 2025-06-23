import SwiftUI
import AppKit

struct SelectionBoxView: NSViewRepresentable {
    // 选区变化回调，支持传递点击点
    var onSelectionRectChanged: (CGRect?, CGPoint?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionRectChanged: onSelectionRectChanged)
    }

    func makeNSView(context: Context) -> SelectionNSView {
        let view = SelectionNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: SelectionNSView, context: Context) {}

    class Coordinator: NSObject {
        var onSelectionRectChanged: (CGRect?, CGPoint?) -> Void
        init(onSelectionRectChanged: @escaping (CGRect?, CGPoint?) -> Void) {
            self.onSelectionRectChanged = onSelectionRectChanged
        }
    }

    class SelectionNSView: NSView {
        var coordinator: Coordinator?
        private var startPoint: NSPoint?
        private var currentPoint: NSPoint?
        private var selectionLayer: CAShapeLayer?

        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            startPoint = point
            currentPoint = point
            updateSelectionLayer()
            // 不在mouseDown时回调nil，等mouseUp时再处理
        }

        override func mouseDragged(with event: NSEvent) {
            currentPoint = convert(event.locationInWindow, from: nil)
            updateSelectionLayer()
            if let rect = selectionRect {
                coordinator?.onSelectionRectChanged(rect, nil)
            }
        }

        override func mouseUp(with event: NSEvent) {
            let isClick = (startPoint != nil && currentPoint != nil && distance(startPoint!, currentPoint!) < 2)
            updateSelectionLayer(clear: true)
            if isClick {
                let clickPoint = convert(event.locationInWindow, from: nil)
                coordinator?.onSelectionRectChanged(nil, clickPoint)
            } else if let rect = selectionRect {
                coordinator?.onSelectionRectChanged(rect, nil)
            }
            startPoint = nil
            currentPoint = nil
        }

        private func distance(_ a: NSPoint, _ b: NSPoint) -> CGFloat {
            hypot(a.x - b.x, a.y - b.y)
        }

        private var selectionRect: CGRect? {
            guard let start = startPoint, let current = currentPoint else { return nil }
            let x = min(start.x, current.x)
            let y = min(start.y, current.y)
            let width = abs(start.x - current.x)
            let height = abs(start.y - current.y)
            return CGRect(x: x, y: y, width: width, height: height)
        }

        private func updateSelectionLayer(clear: Bool = false) {
            if selectionLayer == nil {
                let layer = CAShapeLayer()
                layer.fillColor = NSColor.selectedControlColor.withAlphaComponent(0.2).cgColor
                layer.strokeColor = NSColor.selectedControlColor.cgColor
                layer.lineWidth = 1.5
                self.layer = CALayer()
                self.wantsLayer = true
                self.layer?.addSublayer(layer)
                selectionLayer = layer
            }
            if clear {
                selectionLayer?.path = nil
            } else if let rect = selectionRect {
                selectionLayer?.path = CGPath(rect: rect, transform: nil)
            }
        }
    }
} 