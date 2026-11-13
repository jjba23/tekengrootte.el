# Vision

`tekengrootte` is Dutch for character size, and that is the whole idea: an Emacs configuration
should name its type sizes once, as multiples of a single adjustable scale, so changing one number
resizes everything that was set up that way. The package is 284 lines and depends on nothing beyond
Emacs itself. This document is about what a small, correct package of that shape should become —
which invariants are worth protecting, which documented gaps are real work, and how far the idea
scales before it stops being small.

## Where tekengrootte.el is today

Two functions do all the work:

- `tekengrootte-mk-font-size` returns a height scaled by the current `tekengrootte-scale`, ready
  for a `:height` face attribute. Relative heights stay floats; absolute heights — an integer such
  as `114`, which is how a pixel-sized font is spelled — are rounded back to integers so they stay
  valid.
- `tekengrootte-set-scale` switches the scale to the multiplier of one name in `tekengrootte-sizes`
  (`nano` through `colossal`, with `gigantic` the obvious extension point), messages the result and
  runs `tekengrootte-set-scale-hook`.

Around those sit ten autoloaded commands — eight per-size setters plus
`tekengrootte-set-scale-increase` and `tekengrootte-set-scale-decrease`, which walk to the nearest
size above or below the current scale by comparing multipliers rather than looking the current name
up, so they keep working after the alist is edited or the scale is set by hand.

The design decisions that matter more than the code:

1. **The package never touches your faces.** Setting faces is the user's hook, not the package's
   job. `tekengrootte-set-scale-hook` is the entire integration surface, and that is why the package
   can coexist with any theme, any `use-package` block and any face-setting function without
   knowing about them.
2. **Names, not numbers.** A configuration says `large`, not `1.15`. Renaming or retuning the ladder
   then does not require editing every face.
3. **One global scale.** `tekengrootte-scale` is a plain global defcustom, not a buffer-local
   variable, because the problem it solves is "my whole editor is too small", not "this buffer wants
   different type".
4. **Customize and the command must agree.** The `:set` function on `tekengrootte-scale` runs the
   hook when the value genuinely changed, and stays silent while the file is being loaded — a
   package that repaints faces during load is a package that breaks startup order.
5. **The version is written once.** `Version:` in the header is the source of truth, `default.nix`
   reads it, and the packaging recipes carry copies that `maak version-check` holds to it.

What is honestly absent: custom size names have no commands (the README tells you to bind a lambda
instead), the scale is not persisted between sessions, scaling is global only, and the package is
still not in MELPA or ELPA — the repository carries four installation routes and an archive entry
in none of them. The gate is real, though: byte-compilation with warnings as errors, `checkdoc`
enforced by counting findings, an ERT suite, and CI running the same commands on two Emacs versions
so the recipes do not depend on Guile being installed.

## The vision

1. **A configuration names its type sizes in one place and every face follows, including faces set
   by third-party packages.** Today "every face follows" is true only for faces the user re-applies
   in the hook. A declared ladder that a package can opt into would make the promise hold for a
   theme the user did not write.
2. **The scale is not only global.** A presentation, a terminal, a second frame on a large monitor
   and a screenshot each want a different rung, and none of them should require a second copy of the
   face setup.
3. **Adding a size name gives you a command, a completion entry and a keybinding suggestion,
   without writing a lambda.** The ladder is already data; the commands should be derived from it
   rather than hard-coded beside it.
4. **It is a package in the distribution sense.** The four recipes it carries — Guix channel, Nix
   flake, container, and Debian/openSUSE/Arch — are joined by an archive entry, because "install it
   from source with `:ensure`" is not how most Emacs users install anything.
5. **Its invariants are tests, not admonitions.** The hook runs once per genuine change and never at
   load; an integer height stays an integer; stepping from a hand-set scale still lands on a real
   size; an unknown name is a `user-error` that changes nothing.

## Features that are in scope and not built yet

- **A command for every size in the ladder.** `tekengrootte--size-names` already answers what the
  ladder contains, and the eight per-size commands ignore it. The hard part is defining autoloaded
  commands for names that do not exist at byte-compile time without an `eval` at load and without
  losing the autoload cookies that make key bindings work before the package is loaded.
- **Persistence of the chosen rung.** `tekengrootte-scale` is a defcustom and nothing saves it. The
  hard part is `savehist` integration that does not resurrect last month's scale over a
  configuration file that sets one deliberately.
- **Per-frame or per-context scale.** Faces are global and `set-face-attribute` takes a frame
  argument that the package never uses. The hard part is frame-local state that does not surprise a
  user who then changes the global scale, and a documented answer to what happens to a frame that
  has its own rung when the global one moves.
- **A rounding strategy that keeps ratios.** `round` is applied per call, so a 114 and a 1.2 do not
  stay in a fixed ratio at small sizes. The hard part is a rounding rule that preserves relative
  relationships without a global layout pass, and deciding whether that is even the package's
  business.
- **A declared face set.** Today the package cannot know which faces use it. The hard part is
  offering a registry — "these faces, these multipliers" — while staying the package that does not
  own your faces.

## New features that would be worth having

- **A preview buffer.** Render the whole ladder side by side, in the current theme, so a size is
  chosen by looking rather than by remembering what `1.15` felt like. It is one temporary buffer and
  the existing `mk-font-size`, and it is the feature that sells the package.
- **A stepping UI that names the rung.** A transient or hydra showing "large (1.15×)" with the
  neighbours either side, so `+` and `-` are obvious rather than remembered.
- **Named configurations.** `(coding)`, `(presentation)`, `(terminal)` as complete ladders rather
  than single multipliers, chosen by context. This is where the per-frame idea becomes usable
  without new machinery.
- **An exported table of the ladder.** A command that writes the sizes and multipliers as an
  org-mode or Markdown table, for a README, a blog post or a screenshot — the documentation this
  project keeps having to write by hand.
- **A `use-package` keyword.** `:tekengrootte-size large` in a `use-package` declaration, so the
  common case is one line and the hook wiring is not the user's problem.
- **Composition with `text-scale-adjust`.** Document and test that the buffer-local remapping of
  `C-x C-+` multiplies cleanly on top of a global ladder, including what happens when a buffer is
  zoomed and the global scale then changes under it.

## Contributions that would move the needle

1. **Derive the per-size commands from the ladder.** Small, removes a hole the README apologises
   for, and it is a good first patch: one macro, one autoload cookie per command, one test that a
   custom name works.
2. **Persist the chosen rung through `savehist`,** with a test that a configuration file still wins.
3. **An archive recipe** — MELPA first — which is the difference between a package people read about
   and a package people install. The quality gate MELPA asks for already exists in `maak lint`.
4. **A preview buffer,** which makes the ladder legible to someone who has never used the package.
5. **Per-frame scale,** the largest idea here and the one that needs a decision record before code.
6. **The exported ladder table,** which halves the cost of documenting a release.

## Compared to related projects

| Project | What it is | Where tekengrootte differs |
| --- | --- | --- |
| `text-scale-adjust` (built-in) | Buffer-local face remapping on `C-x C-+`/`C-x C--`, multiplicative, per-buffer | Built-in and immediate, but it remaps the buffer's display rather than the faces themselves, so it does not travel with new frames or into a freshly created buffer, and it cannot express ratios between faces. |
| `default-text-scale` | MELPA package that zooms the default face globally in steps | Closest in spirit and keyboard feel. It scales one face; tekengrootte scales any face you express as a multiple, keeping headings and body text in proportion. |
| `fontaine` | Protesilaos Stavrou's package of named font presets: families and sizes per preset, optionally per mode | Fontaine manages presets of whole font configurations, which is a superset in appearance and a different unit of change. tekengrootte has no opinion about families and no mode awareness. |
| `mixed-pitch` | Protesilaos Stavrou's package that puts fixed-pitch and variable-pitch faces to work together | Complementary: it decides which face is proportional, tekengrootte decides how big each one is. |
| `zoom-frm` | Drew Adams' library for zooming frames and buffers in and out | Frame-level zooming at the display layer. tekengrootte changes the faces, so the result is what a fresh frame and a new buffer inherit. |
| `doom-big-font-mode` | Doom Emacs' presentation toggle that enlarges the font globally | A single on/off gesture, hard-wired to one large size and to Doom's own face setup. The ladder here is data, and the gesture is `+`/`-` through named rungs. |
| `buffer-face-mode` / `variable-pitch-mode` (built-in) | Switch a buffer to a different face or to proportional text | Orthogonal: those choose which face applies, tekengrootte chooses how tall it is. |

What the others do that tekengrootte could still add: presets bound to contexts (fontaine), a
one-key big-font gesture for presentations (`doom-big-font-mode`), display-level remapping that
needs no re-application (the built-in text scale), and the instant feedback of a preview. Where
tekengrootte is ahead and should stay ahead: proportional relationships survive a change because
every face is a multiple of one number; absolute heights such as `114` remain valid, which matters
on pixel-grid fonts; the package never repaints a face you did not ask it to; and the whole story
is one file with no dependency, which is why it can be read, trusted and vendored in an afternoon.

## In the long run

The long bet is that **a scale is an interface**: `tekengrootte-scale` is a number a theme, a
presentation mode or another package could read and honour, so "make everything bigger" stays one
concept across the editor instead of one per package. The second bet is that **small and auditable
wins**: the forty-year-old parts of Emacs keep working because they are boring, and this package
should age the same way — no dependencies, no timers, no advice, one hook. The third is that
**accessibility is a keystroke away**: a package that can move a whole configuration from `nano` to
`colossal` in one command is a practical answer for anyone who finds their editor unreadable, and
documenting it that way is more useful than another screenshot of a font.

## What this document is for

Use it to decide whether a proposed change belongs in the package. Anything that touches a face the
user did not assign, adds a dependency, or turns a name into a number is out of scope. Anything that
makes the ladder easier to inspect, easier to extend, or easier to install is welcome — and a patch
that removes a special case while keeping the behaviour is the best kind.

*This document describes intent, not commitments; the code, the release notes and the issue tracker
say what is actually true today.*
