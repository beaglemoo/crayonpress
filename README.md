# ColourMe

A small native macOS app that generates printable children's colouring books using AI image models via OpenRouter. Pick a theme, page count, and complexity level, preview the pages, regenerate any you don't like, then export a multi-page A4 PDF with a cover page - ready to print and staple.

## Why

Chat assistants tend to cram a whole colouring book onto a single image. ColourMe generates one proper line-art image per page and lays them out as individual A4 pages in a single PDF.

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26.6 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An [OpenRouter](https://openrouter.ai/keys) API key

## Setup

```
git clone git@github.com:beaglemoo/colourme.git
cd colourme
xcodegen generate
open ColourMe.xcodeproj
```

Build and run (Cmd+R), then open Settings (Cmd+,) and paste your OpenRouter API key. The key is stored only in the macOS Keychain - it never touches the repository, UserDefaults, or any file on disk.

## Usage

1. Enter a theme (dinosaurs, unicorns, space...)
2. Choose the number of pages (4 to 24) and a complexity level (Toddler, Young child, Older child)
3. Optionally add a child's name for the cover ("Ellie's Dinosaur Colouring Book")
4. Pick an image model - the list is fetched live from OpenRouter; the default is Gemini 2.5 Flash Image (roughly $0.03 per page)
5. Generate, review the preview grid, regenerate any page you don't like
6. Export PDF and print at A4

## Architecture

SwiftUI app using the macOS 26 Liquid Glass design language. The Xcode project is generated from `project.yml` by XcodeGen and is not committed.

- `Services/OpenRouterClient.swift` - async URLSession wrapper for the OpenRouter API: image model discovery, page subject brainstorming via a cheap text model, and image generation (`POST /api/v1/images`)
- `Services/BookGenerator.swift` - orchestrates a book: generates N distinct page subjects for the theme, then renders pages concurrently in small batches; per-page failures never abort the book
- `Services/PDFBuilder.swift` - composes the A4 PDF with Core Graphics: cover page with the title, then one aspect-fitted image per page
- `Services/KeychainStore.swift` - API key storage
- `Views/` - form, generation progress, preview grid, and settings screens

The app is sandboxed with network access and user-selected file write (for the PDF save panel) as its only entitlements.
