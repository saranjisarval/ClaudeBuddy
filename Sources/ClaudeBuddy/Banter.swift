import Foundation

/// Minion banter + useful prompt ideas, tuned to how much of today's budget is LEFT (0...1).
enum Banter {
    static func message(left: Double) -> String {
        let lines: [String]
        switch left {
        case ...0.0: lines = ["Budget eaten. I'm napping… 💤 Tomorrow we ride! 🔋",
                              "Tank empty. Recharging until tomorrow 🔋"]
        case ..<0.05: lines = ["Last drops! Make this one count 💧",
                               "Almost zero! One final smart prompt?"]
        case ..<0.2: lines = ["Running on fumes ⛽ Quick, high-value prompts only!",
                              "I'm sweating… go for small wins with big payoff."]
        case ..<0.4: lines = ["Getting lower — spend it on what matters most ☕",
                              "Fuel's dropping. Pick your best task and nail it."]
        case ..<0.6: lines = ["Solid pace ☕ Still half a tank — tackle one meaty task!",
                              "Plenty left! Go deeper than a snippet today."]
        case ..<0.8: lines = ["Loads left — time to put it to work! Ask for a whole feature 🔋",
                              "Those tokens won't spend themselves. Build something real!"]
        default: lines = ["Over 80% still unused! Don't let it go to waste — give me a real project! 🔋",
                          "Your tank is barely touched. Come on, ask me something big!",
                          "Psst… I'm getting bored. Feed me a hard problem! 😏"]
        }
        return lines.randomElement()!
    }

    private static let big = [
        "Audit my whole project (architecture, bugs, tests, docs) and give me a prioritized roadmap.",
        "Build a feature end-to-end: ask me 3 questions, then plan, implement and test it.",
        "Refactor my messiest module — tests first, then explain every change.",
        "Write a full test suite for my least-tested code and report the bugs it uncovers.",
        "Do a security review of my repo: dependencies, secrets, injection, auth.",
        "Generate a README, CONTRIBUTING guide and architecture diagram from my code.",
        "Turn this idea into a working prototype today: <describe idea>",
        "Explore my codebase and teach me the 5 things to know before changing it.",
        "Profile my slowest code path, then propose and implement optimizations.",
        "Migrate one of my scripts into a clean, typed CLI with docs and tests."
    ]
    private static let mid = [
        "Find and fix the most likely bug in <file>.",
        "Write unit tests for <function>, including edge cases.",
        "Review my last commit like a strict staff engineer.",
        "Add types and docstrings to <module>.",
        "Optimize <function> and explain the trade-offs.",
        "Summarize <long doc> into action items and open questions.",
        "Draft the PR description for my current changes.",
        "Explain this error and fix it: <paste error>"
    ]
    private static let low = [
        "Write a commit message for my staged diff.",
        "Give me a 5-line summary of what changed today.",
        "One-line fix for this error: <paste error>",
        "Write a regex for: <describe pattern>",
        "Explain this snippet in 3 sentences: <paste code>",
        "Rename these variables for clarity: <paste code>"
    ]
    private static let tomorrow = [
        "Tomorrow's plan: list my 3 highest-impact tasks.",
        "Write down where I left off so I can resume fast tomorrow.",
        "Draft a checklist for the first hour of tomorrow's work."
    ]
    private static var last = ""

    static func prompt(left: Double) -> String {
        let pool = left <= 0 ? tomorrow : left < 0.3 ? low : left < 0.6 ? mid : big
        var p = pool.randomElement()!
        while p == last && pool.count > 1 { p = pool.randomElement()! }
        last = p; return p
    }
}
