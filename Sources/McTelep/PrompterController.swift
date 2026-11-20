import AppKit
import Combine

/// Playback state: scroll offset, play/pause, countdown.
@MainActor
final class PrompterController: ObservableObject {
    @Published private(set) var offset: CGFloat = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var countdown: Int?
    @Published private(set) var toast: String?

    /// Measured by the view.
    var textHeight: CGFloat = 0
    var lineHeight: CGFloat = 28

    private let settings: Settings
    private var wordCount = 0
    private var timer: Timer?
    private var lastTick: CFTimeInterval = 0
    private var countdownTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(settings: Settings) {
        self.settings = settings
        settings.$script
            .sink { [weak self] text in
                guard let self else { return }
                wordCount = text.split(whereSeparator: \.isWhitespace).count
                pause()
                offset = 0
            }
            .store(in: &cancellables)
    }

    /// Scroll stops when the last line reaches the reading line.
    private var maxOffset: CGFloat { max(0, textHeight - lineHeight) }
    var isBusy: Bool { isPlaying || countdown != nil }

    func toggle() { isBusy ? pause() : start() }

    func start() {
        guard wordCount > 0, offset < maxOffset else { return }
        guard settings.countdownEnabled else { return beginScrolling() }
        countdownTask = Task { [weak self] in
            for n in stride(from: 3, through: 1, by: -1) {
                self?.countdown = n
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            self?.countdown = nil
            self?.beginScrolling()
        }
    }

    func pause() {
        countdownTask?.cancel()
        countdownTask = nil
        countdown = nil
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }

    func restart() {
        pause()
        offset = 0
    }

    func changeSpeed(by delta: Int) {
        let range = Settings.wpmRange
        settings.wpm = min(max(settings.wpm + delta, range.lowerBound), range.upperBound)
        flash("\(settings.wpm) wpm")
    }

    func manualScroll(_ event: NSEvent) {
        pause()
        var dy = event.scrollingDeltaY
        if !event.hasPreciseScrollingDeltas { dy *= 10 }
        offset = min(max(offset - dy, 0), maxOffset)
    }

    private func beginScrolling() {
        isPlaying = true
        lastTick = CACurrentMediaTime()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = now - lastTick
        lastTick = now
        guard wordCount > 0, textHeight > 0 else { return }
        // points per word × words per second
        let pointsPerSecond = textHeight / CGFloat(wordCount) * CGFloat(settings.wpm) / 60
        offset = min(offset + pointsPerSecond * dt, maxOffset)
        if offset >= maxOffset { pause() }
    }

    private func flash(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            if !Task.isCancelled { self?.toast = nil }
        }
    }
}
