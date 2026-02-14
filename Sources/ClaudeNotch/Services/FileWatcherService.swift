import Foundation

final class FileWatcherService: @unchecked Sendable {
    let directoryURL: URL

    private let lock = NSLock()
    private var _callback: (@MainActor () -> Void)?
    private var _fileDescriptor: CInt = -1
    private var _dispatchSource: DispatchSourceFileSystemObject?

    var onDirectoryChanged: (@MainActor () -> Void)? {
        get { lock.withLock { _callback } }
        set { lock.withLock { _callback = newValue } }
    }

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.directoryURL = home
            .appendingPathComponent(".claude/notch-monitor/sessions")

        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    func startWatching() {
        let path = directoryURL.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: .global(qos: .userInitiated)
        )

        lock.withLock {
            _fileDescriptor = fd
            _dispatchSource = source
        }

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let cb = self.lock.withLock { self._callback }
            if let cb {
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        cb()
                    }
                }
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            let fd = self.lock.withLock { self._fileDescriptor }
            if fd >= 0 {
                close(fd)
            }
        }

        source.resume()
    }

    func stopWatching() {
        lock.withLock {
            _dispatchSource?.cancel()
            _dispatchSource = nil
        }
    }

    func scanSessions() -> [SessionState] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> SessionState? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(SessionState.self, from: data)
            }
            .sorted {
                // 先按状态优先级降序，再按时间戳降序
                if $0.status.sortPriority != $1.status.sortPriority {
                    return $0.status.sortPriority > $1.status.sortPriority
                }
                return $0.timestamp > $1.timestamp
            }
    }
}
