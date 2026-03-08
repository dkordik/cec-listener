import AppKit
import Foundation

final class ModeStatusController: NSObject {
  private let stateFilePath: String
  private let statusItem: NSStatusItem
  private var timer: Timer?
  private var lastStep: Int = -1

  init(stateFilePath: String) {
    self.stateFilePath = stateFilePath
    self.statusItem = NSStatusBar.system.statusItem(withLength: 22)
    super.init()

    if let button = statusItem.button {
      button.imagePosition = .imageOnly
      button.toolTip = "CEC mode"
      button.title = "M"
    }

    let menu = NSMenu()
    let quitItem = NSMenuItem(title: "Quit CEC Mode Icon", action: #selector(quitApp), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
    statusItem.menu = menu

    updateMode()
    timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
      self?.updateMode()
    }
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  private func readState() -> Int {
    let raw = (try? String(contentsOfFile: stateFilePath, encoding: .utf8)
      .trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
    if let data = raw.data(using: .utf8),
       let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      let parsedStep = object["step"] as? Int ?? 10
      return parsedStep
    }
    return 10
  }

  private func updateMode() {
    let step = readState()
    if step == lastStep {
      return
    }
    lastStep = step

    guard let button = statusItem.button else {
      return
    }

    let image = makeIcon(step: step)
    image.size = NSSize(width: 22, height: 18)
    image.isTemplate = true
    button.image = image
    button.title = ""
    button.toolTip = "CEC mouse mode (step \(step))"
  }

  private func makeIcon(step: Int) -> NSImage {
    let size = NSSize(width: 22, height: 18)
    let image = NSImage(size: size)
    image.lockFocus()

    NSColor.white.setFill()

    // Cursor with diagonal tail axis and clearly rounded lower corners.
    let cursor = NSBezierPath()
    cursor.move(to: NSPoint(x: 10.8, y: 17.1))   // tip
    cursor.line(to: NSPoint(x: 20.2, y: 8.5))    // right edge
    // Inward shoulder notch where tail connects into the main triangle.
    cursor.curve(
      to: NSPoint(x: 17.9, y: 5.1),
      controlPoint1: NSPoint(x: 19.4, y: 7.8),
      controlPoint2: NSPoint(x: 17.5, y: 6.8)
    )
    // Bottom-right corner of tail (rounded, obvious radius).
    cursor.curve(
      to: NSPoint(x: 16.9, y: 2.3),
      controlPoint1: NSPoint(x: 17.7, y: 3.8),
      controlPoint2: NSPoint(x: 17.2, y: 3.0)
    )
    // Tail bottom slants with pointer axis (not horizontal/vertical).
    cursor.curve(
      to: NSPoint(x: 15.3, y: 2.9),
      controlPoint1: NSPoint(x: 16.1, y: 2.2),
      controlPoint2: NSPoint(x: 15.7, y: 2.5)
    )
    cursor.line(to: NSPoint(x: 14.2, y: 6.4))
    // Bottom-left corner into left edge with visible rounding.
    cursor.curve(
      to: NSPoint(x: 10.9, y: 5.2),
      controlPoint1: NSPoint(x: 12.9, y: 5.1),
      controlPoint2: NSPoint(x: 11.8, y: 4.9)
    )
    cursor.curve(
      to: NSPoint(x: 10.8, y: 6.2),
      controlPoint1: NSPoint(x: 10.7, y: 5.3),
      controlPoint2: NSPoint(x: 10.8, y: 5.7)
    )
    cursor.close()
    cursor.fill()

    let exponent = step >= 80 ? "8" : "1"
    let attrs: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 14, weight: .black),
      .foregroundColor: NSColor.white,
    ]
    NSString(string: exponent).draw(at: NSPoint(x: -0.8, y: 3.6), withAttributes: attrs)

    image.unlockFocus()
    return image
  }
}

let args = CommandLine.arguments
let stateFilePath = args.count > 1 ? args[1] : "/tmp/cec-listener-mode.txt"

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = ModeStatusController(stateFilePath: stateFilePath)
_ = controller
app.run()
