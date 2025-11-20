> [!NOTE]
> I've created a design demo for the upcoming app! Feel free to check it out on the live page: [https://Pau1Net.github.io/Forgetting_Ebbinghaus_-urve/demo/forget_curve_demo.html](https://Pau1Net.github.io/Forgetting_Ebbinghaus_-urve/demo/forget_curve_demo.html)

"Forgetting Ebbinghaus Curve" (working title) is an open-source __iOS and macOS__ application for creating text-based notes (with plans to support other media types)
designed to enhance information retention based on the [Ebbinghaus forgetting curve](https://en.wikipedia.org/wiki/Forgetting_curve).
The application is currently in early development stages, with core features yet to be implemented.
It's worth noting that this application will remain completely free and open-source throughout its development lifecycle and ongoing maintenance.

## Project Structure

The codebase is organized into logical folders under `Forgetting_Ebbinghaus_Сurve/`:

```
Forgetting_Ebbinghaus_Сurve/
├── App/
│   └── Forgetting_Ebbinghaus__urveApp.swift      # Main app entry point
├── Models/
│   ├── FlashcardItem.swift                       # Flashcard data model
│   ├── RecallItem.swift                          # Recall task data model
│   ├── StudyProgress.swift                       # Review tracking for flashcards
│   ├── ReviewDifficulty.swift                    # Difficulty rating enum (Easy/Good/Hard)
│   ├── TextCategory.swift                        # Text categorization enum (Short/Medium/Long)
│   └── NotificationConflict.swift                # Night window conflict representation
├── Services/
│   ├── NotificationManager.swift                 # System notification handling
│   ├── PersistenceManager.swift                  # JSON-based data persistence
│   ├── ForgettingCurve.swift                     # Spaced repetition interval calculations
│   ├── TextComplexityAnalyzer.swift              # Text analysis and categorization
│   └── NightWindow.swift                         # Night-time scheduling utilities
├── Utilities/
│   ├── AppColor.swift                            # Color theme definitions
│   ├── Constants.swift                           # App-wide constants
│   └── TimeInterval+Formatting.swift             # Time formatting extensions
├── ViewModels/
│   └── RecallListViewModel.swift                 # Main business logic coordinator
├── Views/
│   ├── RecallItems/                              # Recall task views
│   │   └── ContentView.swift                     # Main recall interface
│   └── Flashcards/                               # Flashcard system views
│       ├── FlashcardListView.swift               # Main flashcard list with filters
│       ├── FlashcardRowView.swift                # Individual row in list
│       ├── FlashcardDetailView.swift             # Card with flip animation
│       ├── StudySessionView.swift                # Dedicated study mode interface
│       └── IndividualFlashcardReviewView.swift   # Single card review with stats
└── Assets.xcassets                               # Images and color assets
```

## Roadmap / TODO

- [x] Initial project setup
- [x] Basic note creation
- [x] __"Smart" notifications system__ (Smart notifications that consider input text size, time of day, and various other important parameters)
- [x] Flashcard generation
- [x] __Adaptive learning algorithm__ (based on input text length, enabling efficient studying for both short snippets and lengthy documents)
- [ ] __PDF support__ (for importing and working with PDF files)
- [ ] __AI-powered context__ (providing additional insights for studied materials via built-in neural network)
- [x] Add standart tests
- [ ] Add License file (Apache 2.0)
- [ ] __Multi-language support__ (beyond English)
  - [ ] Russian
  - [ ] French
  - [ ] Spanish
  - [ ] Italian
- [ ] __Complete README__ (documentation with detailed installation and usage instructions)
- [ ] Add UI interface, showed in demo
- [ ] Add UI tests
- [ ] __Add multiple media types support__ (in long plan)

🤝 __Contributing__

Contributions are welcome! Please contact [pavelkotsko@icloud.com](mailto:developer@example.com?subject=Forgetting%20Ebbinghaus%20Curve) for any questions.



<div align="center"> Made with ❤️ by the Paul "PaulNet" </div> 
