import Foundation

enum ProcessReaper {
    private static let queue = DispatchQueue(label: "Heka.ProcessReaper", qos: .utility)

    static func reap(_ pid: pid_t, killing groups: [pid_t], after grace: DispatchTimeInterval = .seconds(2)) {
        guard pid > 0 else { return }
        queue.async {
            guard !collect(pid) else { return }
            let exit = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: queue)
            exit.setEventHandler {
                if collect(pid) { exit.cancel() }
            }
            exit.activate()
            if collect(pid) {
                exit.cancel()
                return
            }
            queue.asyncAfter(deadline: .now() + grace) {
                guard !exit.isCancelled else { return }
                groups.forEach { kill(-$0, SIGKILL) }
            }
        }
    }

    private static func collect(_ pid: pid_t) -> Bool {
        var status: Int32 = 0
        let result = waitpid(pid, &status, WNOHANG)
        return result == pid || (result == -1 && errno == ECHILD)
    }
}
