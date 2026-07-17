import Foundation

enum PromptBuilder {
    static func imagePrompt(subject: String, complexity: ComplexityLevel) -> String {
        """
        Black and white children's colouring book page. Subject: \(subject). \
        Clean bold black outlines only, no shading, no grey fill, no colour, \
        pure white background, printable line art, portrait orientation. \
        \(complexity.promptModifier)
        """
    }

    static func fallbackSubjects(theme: String, count: Int) -> [String] {
        (1...count).map { "A fun \(theme) scene, variation \($0)" }
    }
}
