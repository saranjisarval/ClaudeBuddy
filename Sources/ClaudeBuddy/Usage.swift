import Foundation

struct Config: Codable {
    var dailyBudgetUSD: Double = 20
    var intervalMinutes: Double = 30
    var visibleSeconds: Double = 15
    var corner: String = "bottomRight"   // bottomRight | bottomLeft | topRight | topLeft
    var sound: Bool = true
    var theme: String = "Aurora"

    init() {}
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self), def = Config()
        dailyBudgetUSD = try c.decodeIfPresent(Double.self, forKey: .dailyBudgetUSD) ?? def.dailyBudgetUSD
        intervalMinutes = try c.decodeIfPresent(Double.self, forKey: .intervalMinutes) ?? def.intervalMinutes
        visibleSeconds = max(3, try c.decodeIfPresent(Double.self, forKey: .visibleSeconds) ?? def.visibleSeconds)
        corner = try c.decodeIfPresent(String.self, forKey: .corner) ?? def.corner
        sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? def.sound
        theme = try c.decodeIfPresent(String.self, forKey: .theme) ?? def.theme
    }

    func save() {
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? FileManager.default.createDirectory(at: Self.dir, withIntermediateDirectories: true)
        try? enc.encode(self).write(to: Self.url)
    }

    static let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude-buddy")
    static let url = dir.appendingPathComponent("config.json")

    static func load() -> Config {
        if let d = try? Data(contentsOf: url), let c = try? JSONDecoder().decode(Config.self, from: d) { return c }
        let c = Config()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? enc.encode(c).write(to: url)
        return c
    }
}

struct Snapshot {
    var tokens = 0
    var costUSD = 0.0          // local estimate
    var apiCostUSD: Double?    // real spend from Admin API, if available
    var budgetUSD = 20.0
    var spent: Double { apiCostUSD ?? costUSD }
    var remaining: Double { max(0, budgetUSD - spent) }
    var usedFraction: Double { budgetUSD > 0 ? min(1, spent / budgetUSD) : 0 }
    var source: String { apiCostUSD != nil ? "API" : "local" }
}

enum UsageReader {
    // USD per million tokens (input, output). Estimates; adjust if pricing differs.
    static func price(_ model: String) -> (Double, Double) {
        let m = model.lowercased()
        if m.contains("haiku") { return (1, 5) }
        if m.contains("sonnet") { return (3, 15) }
        return (15, 75) // opus / fable / unknown
    }

    static func localToday() -> (tokens: Int, cost: Double) {
        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")
        let start = Calendar.current.startOfDay(for: Date())
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var seen = Set<String>(); var tokens = 0; var cost = 0.0
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else { return (0, 0) }
        for case let url as URL in en where url.pathExtension == "jsonl" {
            if let mod = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate, mod < start { continue }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for line in text.split(separator: "\n") where line.contains("\"usage\"") {
                guard let o = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                      let ts = o["timestamp"] as? String, let t = iso.date(from: ts), t >= start,
                      let msg = o["message"] as? [String: Any], let u = msg["usage"] as? [String: Any] else { continue }
                let key = (msg["id"] as? String ?? "") + (o["requestId"] as? String ?? "")
                if !key.isEmpty { if seen.contains(key) { continue }; seen.insert(key) }
                let i = u["input_tokens"] as? Int ?? 0, out = u["output_tokens"] as? Int ?? 0
                let cw = u["cache_creation_input_tokens"] as? Int ?? 0, cr = u["cache_read_input_tokens"] as? Int ?? 0
                let (pi, po) = price(msg["model"] as? String ?? "")
                tokens += i + out + cw + cr
                cost += (Double(i) * pi + Double(out) * po + Double(cw) * pi * 1.25 + Double(cr) * pi * 0.1) / 1_000_000
            }
        }
        return (tokens, cost)
    }

    static func adminKey() -> String? {
        if let k = ProcessInfo.processInfo.environment["ANTHROPIC_ADMIN_KEY"], !k.isEmpty { return k }
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["find-generic-password", "-s", "claude-buddy-admin-key", "-w"]
        let pipe = Pipe(); p.standardOutput = pipe; p.standardError = Pipe()
        guard (try? p.run()) != nil else { return nil }
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let k = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (k?.isEmpty ?? true) ? nil : k
    }

    /// Today's real spend (UTC day buckets) from the Admin cost report. Amounts are in cents.
    static func apiCostToday(key: String) async -> Double? {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
        let start = cal.startOfDay(for: Date())
        let f = ISO8601DateFormatter()
        var comps = URLComponents(string: "https://api.anthropic.com/v1/organizations/cost_report")!
        comps.queryItems = [URLQueryItem(name: "starting_at", value: f.string(from: start))]
        var req = URLRequest(url: comps.url!)
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let buckets = o["data"] as? [[String: Any]] else { return nil }
        var cents = 0.0
        for b in buckets { for r in b["results"] as? [[String: Any]] ?? [] {
            if let s = r["amount"] as? String, let v = Double(s) { cents += v } else if let v = r["amount"] as? Double { cents += v }
        } }
        return cents / 100
    }

    static func snapshot(budget: Double) async -> Snapshot {
        let (t, c) = localToday()
        var s = Snapshot(tokens: t, costUSD: c, budgetUSD: budget)
        if let k = adminKey() { s.apiCostUSD = await apiCostToday(key: k) }
        return s
    }
}
