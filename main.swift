// Expresso: mantém a tela (e opcionalmente o Mac) acordados. App só de barra de menus.
import AppKit
import IOKit.pwr_mgt

enum Mode: Int { case display = 0, displayAndSystem = 1 }

// MARK: - Trava de energia (IOKit)
final class Keeper {
    private var ids: [IOPMAssertionID] = []
    var isOn: Bool { !ids.isEmpty }

    @discardableResult
    func start(mode: Mode) -> Bool {
        let old = ids   // solta as antigas só depois de criar as novas: não fica nem um instante sem trava
        ids = []
        defer { for id in old { IOPMAssertionRelease(id) } }
        var types = ["PreventUserIdleDisplaySleep"]
        if mode == .displayAndSystem { types.append("PreventUserIdleSystemSleep") }
        let reason = mode == .display ? "Expresso (tela)" : "Expresso (tela e repouso)"   // sem acento: o pmset não mostra UTF-8
        for t in types {
            var id: IOPMAssertionID = 0
            let r = IOPMAssertionCreateWithName(t as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &id)
            guard r == kIOReturnSuccess else { stop(); return false }
            ids.append(id)
        }
        return true
    }

    func stop() {
        for id in ids { IOPMAssertionRelease(id) }
        ids.removeAll()
    }
}

// MARK: - Preferências
enum Prefs {
    static let d = UserDefaults.standard
    static var mode: Mode {
        get { Mode(rawValue: d.integer(forKey: "mode")) ?? .display }
        set { d.set(newValue.rawValue, forKey: "mode") }
    }
    // 0 = 1h, 1 = 2h, 2 = 3h, 3 = nunca, 4 = personalizado
    static var timeChoice: Int {
        get { d.object(forKey: "timeChoice") == nil ? 0 : d.integer(forKey: "timeChoice") }
        set { d.set(newValue, forKey: "timeChoice") }
    }
    static var customHours: Int {
        get { min(999, max(0, d.integer(forKey: "customHours"))) }
        set { d.set(min(999, max(0, newValue)), forKey: "customHours") }
    }
    static var customMinutes: Int {
        get {
            let m = d.object(forKey: "customMinutes") == nil ? 30 : min(59, max(0, d.integer(forKey: "customMinutes")))
            return m == 0 && customHours == 0 ? 1 : m   // 0 h 0 min não existe: o mínimo é 1 minuto
        }
        set { d.set(min(59, max(0, newValue)), forKey: "customMinutes") }
    }
    /// nil = sem limite
    static var durationSeconds: TimeInterval? {
        switch timeChoice {
        case 0: return 3600
        case 1: return 7200
        case 2: return 10800
        case 3: return nil
        default: return TimeInterval(max(1, customHours * 60 + customMinutes) * 60)
        }
    }
}

// MARK: - Ícone da barra de menus (xícara desenhada à mão: vazia, enchendo, cheia)
enum CupIcon {
    static let size = NSSize(width: 18, height: 18)
    static let empty = image(level: 0)
    static let full = image(level: 1, steam: 1)

    /// level: 0 = vazia, 1 = cheia. pouring: fio de café caindo. steam: 0 a 1, fumaça em cima.
    static func image(level: CGFloat, pouring: Bool = false, steam: CGFloat = 0) -> NSImage {
        let img = NSImage(size: size, flipped: false) { _ in
            let shift = NSAffineTransform()
            shift.translateX(by: 0.6, yBy: 0)
            shift.concat()
            NSColor.black.set()
            let bottom: CGFloat = 3.5, top: CGFloat = 11.5

            let body = NSBezierPath()
            body.move(to: NSPoint(x: 2.5, y: top))
            body.line(to: NSPoint(x: 2.5, y: 7.5))
            body.curve(to: NSPoint(x: 6.5, y: bottom), controlPoint1: NSPoint(x: 2.5, y: 5.3), controlPoint2: NSPoint(x: 4.3, y: bottom))
            body.line(to: NSPoint(x: 8.5, y: bottom))
            body.curve(to: NSPoint(x: 12.5, y: 7.5), controlPoint1: NSPoint(x: 10.7, y: bottom), controlPoint2: NSPoint(x: 12.5, y: 5.3))
            body.line(to: NSPoint(x: 12.5, y: top))
            body.close()
            body.lineWidth = 1.3
            body.lineJoinStyle = .round

            if level > 0 {   // o café: enche o corpo de baixo para cima
                NSGraphicsContext.saveGraphicsState()
                body.addClip()
                NSRect(x: 0, y: bottom, width: 18, height: (top - bottom) * min(1, level)).fill()
                NSGraphicsContext.restoreGraphicsState()
            }
            body.stroke()

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 12.5, y: 10.3))
            handle.curve(to: NSPoint(x: 12.5, y: 5.9), controlPoint1: NSPoint(x: 16.3, y: 10.3), controlPoint2: NSPoint(x: 16.3, y: 5.9))
            handle.lineWidth = 1.3
            handle.stroke()

            let saucer = NSBezierPath()
            saucer.move(to: NSPoint(x: 1.5, y: 1.4))
            saucer.line(to: NSPoint(x: 13.5, y: 1.4))
            saucer.lineWidth = 1.3
            saucer.lineCapStyle = .round
            saucer.stroke()

            if pouring {   // fio de café caindo dentro da xícara
                let stream = NSBezierPath()
                stream.move(to: NSPoint(x: 7.5, y: 18))
                stream.line(to: NSPoint(x: 7.5, y: bottom + (top - bottom) * min(1, level)))
                stream.lineWidth = 1.6
                stream.stroke()
            }
            if steam > 0 {   // fumaça: só aparece com a xícara cheia
                NSColor.black.withAlphaComponent(min(1, steam)).set()
                for x in [5.0, 10.0] as [CGFloat] {
                    let w = NSBezierPath()
                    w.move(to: NSPoint(x: x, y: 13.3))
                    w.curve(to: NSPoint(x: x, y: 17.3), controlPoint1: NSPoint(x: x + 1.8, y: 14.6), controlPoint2: NSPoint(x: x - 1.8, y: 16.0))
                    w.lineWidth = 1.2
                    w.lineCapStyle = .round
                    w.stroke()
                }
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    /// Quadro da animação de encher. p vai de 0 (vazia) a 1 (cheia, com fumaça).
    static func frame(progress p: CGFloat) -> NSImage {
        let pour: CGFloat = 0.75   // parte do tempo gasta enchendo; o resto é a fumaça aparecendo
        if p >= 1 { return full }
        if p < pour {
            let t = max(0, p) / pour
            return image(level: t * (2 - t), pouring: true)   // enche rápido e desacelera no fim
        }
        return image(level: 1, steam: (p - pour) / (1 - pour))
    }
}

// MARK: - App
final class AppDelegate: NSObject, NSApplicationDelegate {
    let keeper = Keeper()
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    var panel: Panel!
    var endDate: Date?
    var ticker: Timer?
    var fillTimer: Timer?        // animação do café enchendo a xícara
    var fillStart = Date()
    static let fillSeconds = 1.2

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let b = statusItem.button {
            b.target = self
            b.action = #selector(clicked(_:))
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        panel = Panel(app: self)
        popover.contentViewController = panel
        popover.behavior = .transient   // clicar fora fecha
        refresh()
    }

    func applicationWillTerminate(_ notification: Notification) { keeper.stop() }

    @objc func clicked(_ sender: NSStatusBarButton) {
        guard let e = NSApp.currentEvent else { return }
        let isRight = e.type == .rightMouseUp || e.modifierFlags.contains(.control)
        if isRight {
            if popover.isShown { popover.performClose(nil) }
            toggle()
        } else {
            togglePanel()
        }
    }

    func togglePanel() {
        guard let b = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            panel.sync()
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func toggle() { keeper.isOn ? turnOff() : turnOn() }

    func turnOn() {
        let wasOn = keeper.isOn
        guard keeper.start(mode: Prefs.mode) else { NSSound.beep(); turnOff(); return }
        if !wasOn { startFill() }   // só anima quando sai de desligado para ligado
        endDate = Prefs.durationSeconds.map { Date().addingTimeInterval($0) }
        ticker?.invalidate()
        let t = Timer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        t.tolerance = 0.3
        RunLoop.main.add(t, forMode: .common)
        ticker = t
        refresh()
    }

    func turnOff() {
        keeper.stop()
        endDate = nil
        ticker?.invalidate()
        ticker = nil
        stopFill()
        refresh()
    }

    func startFill() {
        stopFill()
        fillStart = Date()
        let t = Timer(timeInterval: 1.0 / 30, target: self, selector: #selector(fillStep), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        fillTimer = t
        fillStep()
    }

    func stopFill() {
        fillTimer?.invalidate()
        fillTimer = nil
    }

    @objc func fillStep() {
        let p = Date().timeIntervalSince(fillStart) / AppDelegate.fillSeconds
        if p >= 1 { stopFill(); refresh() } else { statusItem?.button?.image = CupIcon.frame(progress: p) }
    }

    @objc func tick() {
        if let e = endDate, Date() >= e { turnOff() } else { refresh() }
    }

    /// Mudou o modo: se estiver ligado, troca as travas e mantém a contagem (não mexe no endDate).
    func modeChanged() {
        guard keeper.isOn else { refresh(); return }
        if keeper.start(mode: Prefs.mode) { refresh() } else { NSSound.beep(); turnOff() }
    }

    /// Mudou o tempo: se estiver ligado, recomeça a contagem com o valor novo.
    func timeChanged() { keeper.isOn ? turnOn() : refresh() }

    var statusText: String {
        guard keeper.isOn else { return "Desligado" }
        guard let e = endDate else { return "Ligado, sem limite" }
        let s = max(0, Int(e.timeIntervalSinceNow.rounded()))
        return String(format: "Ligado, faltam %d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    func refresh() {
        if let b = statusItem?.button {
            if fillTimer == nil { b.image = keeper.isOn ? CupIcon.full : CupIcon.empty }   // durante a animação, quem desenha é o fillStep
            b.setAccessibilityLabel(keeper.isOn ? "Expresso ligado" : "Expresso desligado")
            b.toolTip = "Expresso: " + statusText + "\nClique direito: " + (keeper.isOn ? "desligar" : "ligar")
        }
        panel?.updateStatus()
    }
}

// MARK: - Popover
final class Panel: NSViewController, NSTextFieldDelegate {
    unowned let app: AppDelegate
    var modeButtons: [NSButton] = []
    var timeButtons: [NSButton] = []
    let hours = NSTextField()
    let minutes = NSTextField()
    let status = NSTextField(labelWithString: "")
    var power: NSButton!

    init(app: AppDelegate) {
        self.app = app
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("não usado") }

    private func header(_ s: String) -> NSTextField {
        let l = NSTextField(labelWithString: s)
        l.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        return l
    }

    private func column(_ views: [NSView], spacing: CGFloat = 4) -> NSStackView {
        let s = NSStackView(views: views)
        s.orientation = .vertical
        s.alignment = .leading
        s.spacing = spacing
        s.setClippingResistancePriority(.required, for: .horizontal)   // nunca deixa um item vazar para fora
        return s
    }

    override func loadView() {
        let modeTitles = ["Não desligar a tela", "Não desligar a tela nem deixar o Mac em repouso"]
        modeButtons = modeTitles.enumerated().map { i, t in
            let b = NSButton(radioButtonWithTitle: t, target: self, action: #selector(modePicked(_:)))
            b.tag = i
            return b
        }
        let timeTitles = ["1 hora", "2 horas", "3 horas", "Nunca (sem limite)", "Personalizado"]
        timeButtons = timeTitles.enumerated().map { i, t in
            let b = NSButton(radioButtonWithTitle: t, target: self, action: #selector(timePicked(_:)))
            b.tag = i
            return b
        }

        for f in [hours, minutes] {
            f.alignment = .right
            f.delegate = self
            f.translatesAutoresizingMaskIntoConstraints = false
            f.widthAnchor.constraint(equalToConstant: 48).isActive = true
        }
        let customRow = NSStackView(views: [hours, NSTextField(labelWithString: "h"), minutes, NSTextField(labelWithString: "min")])
        customRow.orientation = .horizontal
        customRow.spacing = 4
        let indented = NSStackView(views: [customRow])
        indented.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        status.textColor = .secondaryLabelColor

        power = NSButton(title: "Ligar", target: self, action: #selector(powerPressed))
        power.keyEquivalent = "\r"
        let quit = NSButton(title: "Sair", target: self, action: #selector(quitPressed))
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let bottom = NSStackView(views: [power, spacer, quit])
        bottom.orientation = .horizontal

        let sep1 = NSBox(); sep1.boxType = .separator
        let sep2 = NSBox(); sep2.boxType = .separator

        let root = column([
            header("Modo"), column(modeButtons),
            sep1,
            header("Tempo"), column(timeButtons + [indented]),
            sep2,
            status, bottom,
        ], spacing: 10)
        root.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        for v in [sep1, sep2, bottom] {
            v.translatesAutoresizingMaskIntoConstraints = false
            v.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -32).isActive = true
        }
        root.translatesAutoresizingMaskIntoConstraints = false
        // o painel cresce até caber o texto mais comprido com as margens (antes ficava em 330 e o Modo vazava)
        let widest = (modeButtons + timeButtons).map { $0.intrinsicContentSize.width }.max() ?? 0
        root.widthAnchor.constraint(greaterThanOrEqualToConstant: max(330, ceil(widest) + 32)).isActive = true
        view = root
        sync()
    }

    func sync() {
        guard isViewLoaded else { return }
        for b in modeButtons { b.state = b.tag == Prefs.mode.rawValue ? .on : .off }
        for b in timeButtons { b.state = b.tag == Prefs.timeChoice ? .on : .off }
        hours.integerValue = Prefs.customHours
        minutes.integerValue = Prefs.customMinutes
        let custom = Prefs.timeChoice == 4
        hours.isEnabled = custom
        minutes.isEnabled = custom
        updateStatus()
    }

    func updateStatus() {
        guard isViewLoaded else { return }
        status.stringValue = app.statusText
        power.title = app.keeper.isOn ? "Desligar" : "Ligar"
    }

    @objc func modePicked(_ b: NSButton) {
        commitFields()
        Prefs.mode = Mode(rawValue: b.tag) ?? .display
        sync(); app.modeChanged()
    }

    @objc func timePicked(_ b: NSButton) {
        commitFields()
        Prefs.timeChoice = b.tag
        sync(); app.timeChanged()
        if b.tag == 4 { view.window?.makeFirstResponder(hours) }
    }

    /// Número inteiro de 0 até max, ou nil se o texto não serve (letras, vazio, negativo, grande demais).
    private func number(in field: NSTextField, max: Int) -> Int? {
        guard let v = Int(field.stringValue.trimmingCharacters(in: .whitespaces)), (0...max).contains(v) else { return nil }
        return v
    }

    /// Grava o que está digitado nos campos, mesmo no meio da edição.
    /// Valor que não serve volta para o último valor bom. 0 h 0 min vira 1 min, à vista.
    func commitFields() {
        guard isViewLoaded else { return }
        let oldH = Prefs.customHours, oldM = Prefs.customMinutes
        Prefs.customHours = number(in: hours, max: 999) ?? oldH
        Prefs.customMinutes = number(in: minutes, max: 59) ?? oldM
        let h = Prefs.customHours, m = Prefs.customMinutes
        if hours.stringValue != String(h) { hours.stringValue = String(h) }
        if minutes.stringValue != String(m) { minutes.stringValue = String(m) }
        // só recomeça a contagem se o valor mudou de verdade
        if (h != oldH || m != oldM) && Prefs.timeChoice == 4 { app.timeChanged() }
    }

    func controlTextDidEndEditing(_ obj: Notification) { commitFields() }

    /// O painel fechou (clique fora, clique no ícone): guarda o que estava digitado.
    override func viewWillDisappear() {
        super.viewWillDisappear()
        commitFields()
    }

    @objc func powerPressed() {
        commitFields()   // grava o campo em edição
        app.toggle()
    }

    @objc func quitPressed() {
        commitFields()
        NSApp.terminate(nil)
    }
}

// MARK: - Autoteste pela linha de comando (não abre interface)
func selfTest() -> Int32 {
    func myAssertions() -> [String] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g", "assertions"]
        let pipe = Pipe()
        p.standardOutput = pipe
        try? p.run()
        p.waitUntilExit()
        let out = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let tag = "pid \(getpid())("
        return out.split(separator: "\n").map(String.init).filter { $0.contains(tag) }
    }
    let k = Keeper()
    var ok = true
    for (m, expected) in [(Mode.display, ["PreventUserIdleDisplaySleep"]),
                          (Mode.displayAndSystem, ["PreventUserIdleDisplaySleep", "PreventUserIdleSystemSleep"])] {
        print("== modo \(m.rawValue + 1): start = \(k.start(mode: m))")
        usleep(1_000_000)   // o powerd registra a trava de forma assíncrona
        let lines = myAssertions()
        lines.forEach { print("   " + $0.trimmingCharacters(in: .whitespaces)) }
        for e in expected where !lines.contains(where: { $0.contains(e) }) { print("   FALTA \(e)"); ok = false }
        if m == .display && lines.contains(where: { $0.contains("PreventUserIdleSystemSleep") }) { print("   SOBRA trava de repouso"); ok = false }
        k.stop()
        usleep(1_000_000)
        let after = myAssertions()
        print("   depois de desligar: \(after.count) trava(s)")
        if !after.isEmpty { ok = false }
    }
    print(ok ? "AUTOTESTE OK" : "AUTOTESTE FALHOU")
    return ok ? 0 : 1
}

// MARK: - Início
if CommandLine.arguments.contains("--teste") { exit(selfTest()) }

let app = NSApplication.shared
if let id = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
    exit(0)   // já existe um Expresso aberto
}
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
