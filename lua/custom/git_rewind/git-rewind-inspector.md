# Git Rewind Inspector PRD

## Problem Statement

The current Git workflow is split across multiple tools. Lazygit works well as a repository dashboard and launch point, but when the user needs to deeply inspect the history of the current file or a selected set of lines, the information is fragmented across separate commands and plugins.

The user wants a Neovim-native "rewind" workflow that makes it easy to move from a file opened from lazygit into a persistent inspector that can answer the practical questions behind code archaeology:

- Who last touched this line or range?
- What commit changed it?
- When did that happen?
- What PR did it come from?
- What did the whole file look like at that point in history?
- How does that revision compare to the current working tree?
- Can I step backward and forward through relevant history using the arrow keys?

The user already has useful Git capabilities in the config, but they are not yet unified into a single, inspectable, selection-aware interface. The goal is to create a cohesive Neovim flow that feels closer to GitLens-style archaeology while remaining terminal-native, hackable, and friendly to the user's existing lazygit-first workflow.

## Solution

Build a local Neovim "Git Rewind Inspector" that opens from the current buffer and supports two primary modes:

1. **Whole-file rewind mode** when invoked in normal mode.
2. **Selected-lines rewind mode** when invoked from visual mode.

The inspector should open as a persistent split-based interface with three main regions:

- A **left sidebar** that shows the commit history for the current file or selected range, along with blame, commit, timestamp, and PR metadata for the currently focused revision.
- A **historical file pane** showing the selected revision of the file.
- A **current file pane** showing the working tree version of the file.

The two file panes should be displayed as a vertical diff so the user can compare past and present with full-file context. In selected-lines mode, the inspector should still show the full files, but it should automatically center and highlight the relevant range in both panes so the selection remains anchored in context.

The inspector should support keyboard-driven stepping through the relevant history using the left and right arrow keys:

- **Left** moves to an older commit affecting the target.
- **Right** moves to a newer commit affecting the target.

For whole-file mode, history should be based on commits affecting the file. For selected-lines mode, history should be based specifically on the chosen line range.

GitHub pull request metadata should be an optional enrichment layer powered by the `gh` CLI. When available, the inspector should show PR number, title, author, URL, merged time, and state for the currently selected commit, and provide a key to open the PR in the browser.

The inspector should reuse the existing Git-oriented Neovim stack where possible rather than replacing it. Existing blame, file history, and diff tooling should remain useful, but the new inspector should become the primary workflow for focused archaeology.

## User Stories

1. As a developer, I want to open a file from lazygit into Neovim and immediately start investigating its history, so that my repo dashboard and deep inspection flow work together.
2. As a developer, I want a normal-mode rewind command for the current file, so that I can inspect the history of a file without making a visual selection first.
3. As a developer, I want a visual-mode rewind command for a selected range of lines, so that I can investigate the history of the exact code I care about.
4. As a developer, I want the rewind inspector to preserve full-file context even when I selected only a range, so that I can understand the surrounding implementation and not just an isolated snippet.
5. As a developer, I want the selected range to stay visually centered and highlighted in history mode, so that I do not lose my place while stepping through revisions.
6. As a developer, I want to move backward and forward through history using the arrow keys, so that rewinding feels immediate and conversational instead of command-driven.
7. As a developer, I want left and right arrows to mean older and newer revisions consistently, so that the mental model is easy to remember.
8. As a developer, I want a persistent history list in the inspector, so that I can see where I am in the sequence of relevant commits.
9. As a developer, I want the inspector to show blame information for the current line or selection, so that I can quickly identify who changed the code and when.
10. As a developer, I want the inspector to show commit metadata for the currently selected revision, so that I can understand the intent and timing of the change.
11. As a developer, I want the inspector to show pull request metadata when available, so that I can connect a code change back to review discussion and broader context.
12. As a developer, I want PR lookup to be optional, so that the core rewind flow still works in repos or environments where GitHub CLI enrichment is unavailable.
13. As a developer, I want a key to open the related PR in the browser, so that I can jump directly from code archaeology into review context.
14. As a developer, I want the historical and current files shown in a vertical diff layout, so that I can compare old and new code side by side without leaving the inspector.
15. As a developer, I want the historical pane to update as I move through commits, so that I can rapidly understand how the file evolved.
16. As a developer, I want the current working tree pane to remain stable while I browse history, so that I always know what the code looks like now.
17. As a developer, I want detailed blame behavior to feel familiar, so that I can rely on semantics similar to existing Fugitive-style blame workflows.
18. As a developer, I want the inspector to degrade gracefully when range history is difficult to resolve, so that I still get useful information even when Git history is messy.
19. As a developer, I want the inspector to work on ordinary Git repositories and only add GitHub-specific data when possible, so that the core feature remains broadly useful.
20. As a developer, I want the new functionality implemented as a local module rather than a pile of inline config, so that it is easier to maintain and extend.
21. As a developer, I want the feature to coexist with the existing git keybindings and plugins, so that I can adopt the new workflow incrementally.
22. As a developer, I want separate whole-file and visual-selection entry paths to feel like the same tool with different scopes, so that the feature remains coherent.
23. As a developer, I want the sidebar to prioritize the information I actually ask during archaeology—blame, commit, PR, and time—so that I spend less time hopping between commands.
24. As a developer, I want the inspector to remain hackable inside my Neovim config, so that I can keep evolving the UI and behavior over time.

## Implementation Decisions

- The feature will be implemented as a local module within the Neovim configuration rather than as additional ad hoc logic embedded directly into the main configuration file.
- The implementation should be organized into a small set of deep modules with clear responsibilities:
  - a **history module** that resolves commit sequences for a whole file or a selected line range,
  - a **git data module** that retrieves blame, commit details, and historical file contents,
  - a **GitHub enrichment module** that optionally resolves PR metadata via `gh`,
  - and a **UI/state module** that owns the inspector layout, selection scope, key handling, and view updates.
- The history module should support two scopes:
  - **file scope** for whole-file rewind invoked from normal mode,
  - **range scope** for selected-lines rewind invoked from visual mode.
- Range scope should treat the visual selection as the authoritative target for history traversal.
- The inspector should use a persistent split-based layout with a **left sidebar** and **two content panes**. The sidebar should contain the navigable commit history plus structured metadata for the currently focused item.
- The two content panes should show a vertical diff between the selected historical revision and the current working tree version of the file.
- In visual-selection mode, the content panes should still show the full files rather than isolated snippets, but the chosen range should be centered and highlighted so the user keeps context.
- Left and right arrow keys inside the inspector should step through the commit sequence affecting the current target, with left meaning older and right meaning newer.
- Normal-mode rewind and visual-mode rewind should use separate entry points but converge into the same inspector model and internal state representation.
- Existing git-oriented tools in the configuration should be reused rather than replaced. The new feature should complement the current blame, file history, and diff workflows.
- Detailed blame behavior should remain compatible with the user's existing expectations from Fugitive-style blame output. The new tool should summarize or present blame in a familiar way rather than inventing a novel blame model.
- Commit metadata for the focused revision should include author, commit summary, commit hash, and timestamp.
- Optional GitHub enrichment should query the selected commit for associated PR data and display at least PR number, title, author, URL, merged time, and state.
- PR enrichment must be optional. If `gh` is unavailable, the inspector should still provide the full rewind experience minus PR-specific data.
- The UI should provide an action to open the associated PR in the browser when PR metadata is available.
- The implementation should prefer robust fallbacks and graceful failure over brittle completeness. If a specific enrichment step fails, the inspector should keep the history and diff views usable.
- The initial version should optimize for local usability and maintainability rather than broad plugin packaging or cross-forge abstraction.

## Testing Decisions

- A good test for this feature verifies external behavior rather than internal implementation details. The important behaviors are: opening the correct scope, showing the expected commit sequence, updating the diff panes when history changes, centering the selection in range mode, showing metadata consistently, and degrading gracefully when optional GitHub enrichment is unavailable.
- The most important modules to validate are the history resolution module, the inspector state transitions, the metadata assembly logic, and the optional GitHub enrichment layer.
- For the initial implementation, testing will be manual rather than automated.
- Manual validation should cover at least:
  - opening whole-file rewind from normal mode,
  - opening range rewind from visual mode,
  - stepping older and newer with arrow keys,
  - confirming the historical pane changes while the current pane remains stable,
  - confirming the selection remains visible and centered in range mode,
  - confirming blame and commit metadata update with the focused revision,
  - confirming PR metadata appears when `gh` is available,
  - confirming PR metadata fails gracefully when unavailable,
  - and confirming the inspector can be exited cleanly without disturbing the current editing workflow.
- Prior art for behavior and validation should come from the existing Git integrations already present in the configuration, especially the current blame, file history, range-history, and diff-driven workflows.
- If the parsing and state-management logic becomes complex enough later, those deeper modules should be extracted in a way that makes them unit-testable without relying on full UI-level tests.

## Out of Scope

- Changing the user's existing lazygit bindings or building a lazygit-specific integration in the first version.
- Supporting forges other than GitHub in the first version.
- Guaranteeing perfect range tracking across large refactors, file moves, or heavily rewritten history.
- Building a fully generic standalone plugin for public distribution in the first version.
- Replacing existing Git plugins across the rest of the Neovim configuration.
- Adding automated tests in the first version.
- Supporting highly customizable pane layouts in the first version beyond the chosen left-sidebar inspector layout.

## Further Notes

- The current configuration already includes several relevant Git capabilities, so the implementation should focus on unifying and extending those capabilities instead of re-solving solved problems.
- The feature should be treated as a workflow improvement first and a reusable plugin second.
- The left sidebar layout was chosen because the user wants persistent metadata visible during navigation. If this proves too cramped in practice, a future iteration can add a collapsible or relocatable metadata pane without changing the core rewind model.
- The feature should preserve the existing mental model of "lazygit for repo operations, Neovim for deep inspection."