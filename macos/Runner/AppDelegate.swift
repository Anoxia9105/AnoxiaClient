import Cocoa
import Darwin
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var singleInstanceLockFileDescriptor: Int32 = -1

  override func applicationWillFinishLaunching(_ notification: Notification) {
    super.applicationWillFinishLaunching(notification)

    let lockPath = (NSTemporaryDirectory() as NSString)
      .appendingPathComponent("cn.anoxia.single-instance.lock")
    let descriptor = Darwin.open(lockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)

    guard descriptor >= 0 else {
      return
    }

    guard Darwin.flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
      Darwin.close(descriptor)
      activateExistingInstance()
      NSApp.terminate(nil)
      return
    }

    singleInstanceLockFileDescriptor = descriptor
  }

  override func applicationWillTerminate(_ notification: Notification) {
    if singleInstanceLockFileDescriptor >= 0 {
      Darwin.flock(singleInstanceLockFileDescriptor, LOCK_UN)
      Darwin.close(singleInstanceLockFileDescriptor)
      singleInstanceLockFileDescriptor = -1
    }
    super.applicationWillTerminate(notification)
  }

  private func activateExistingInstance() {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      return
    }

    let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
    let existingInstance = NSRunningApplication
      .runningApplications(withBundleIdentifier: bundleIdentifier)
      .first { $0.processIdentifier != currentProcessIdentifier }

    existingInstance?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
