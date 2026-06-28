# Anjali — App Icon Specification

The icon should feel like the app: a warm, quiet, sacred pause. A small flame or
**diya** (oil lamp) glowing on a warm gradient — calm, centred, instantly
readable.

## Visual direction

- **Motif:** a single small flame, or a diya (oil lamp) with one flame.
- **Background:** a warm gradient drawn from the app's **dawn palette** —
  rose/plum into amber. Suggested stops:
  - deep indigo/plum `#20265F` → muted rose `#6E3F5C` → warm amber `#D08A57`
  - flame/accent highlight in gold `#F3B85E`
- **Tone:** soft glow, gentle warmth. Reverent, not flashy. No harsh edges.
- **Composition:** the flame **centred** and simple, with generous breathing
  room. The single brightest point is the flame.
- **No text** in the icon. No wordmark, no letters.
- Avoid fine detail, thin lines, or busy texture — they vanish at small sizes.

## Size & legibility requirements

Deliver a master at **1024×1024** (PNG, no alpha, no rounded corners — the
system masks the corners). It must remain clearly readable when scaled down:

| Size | Use | Legibility note |
| --- | --- | --- |
| 1024×1024 | App Store | Master artwork. |
| 512×512 | Large listings | Flame still distinct from background. |
| 256×256 | Finder/large | Glow reads; no detail loss. |
| 60×60 | iPhone home screen | Flame is the dominant, recognisable shape. |
| 40×40 | Spotlight | Reads as "a flame on warm light." |
| 29×29 | Settings | Silhouette still legible; no clutter. |

Test by viewing the 1024 master shrunk to 29×29 — the flame should still read.

> **Current state:** `Anjali/Anjali/Assets.xcassets/AppIcon.appiconset` is a
> placeholder (single universal 1024 slot, no image). Drop the final 1024 PNG
> in and Xcode generates the rest. **Add real artwork before any external
> build** (it's on the pre-TestFlight checklist).

## Concepts (pick one to develop)

### Concept A — Single Flame
A lone, soft flame centred on the rose→amber gradient, with a gentle glow halo.
The simplest, most scalable option; the flame is the same motif used in the
completion screen, tying the brand together. **Recommended for small-size
legibility.**

### Concept B — Diya (oil lamp)
A minimal, stylised diya silhouette holding one flame, sitting low-centre on the
warm gradient. More explicitly devotional and culturally specific; keep the lamp
shape bold and simple so it survives at 29×29. Slightly more detail risk than A.

### Concept C — Flame within Añjali hands
A very abstract suggestion of cupped "añjali" hands (the namaste gesture the app
is named for) cradling a single flame — rendered as two soft curved forms, not
literal hands. The most conceptual and on-name; hardest to keep legible when
small, so it needs a confident, minimal execution.

## Acceptance checklist

- [ ] 1024×1024 PNG, sRGB, no alpha, square (no pre-rounded corners).
- [ ] Flame is the clear focal point; reads at 29×29.
- [ ] Warm dawn-palette gradient (rose/amber); matches in-app theme.
- [ ] No text, no thin lines, no busy detail.
- [ ] Looks good on both light and dark device wallpapers.
- [ ] Dropped into `AppIcon.appiconset`; project builds with no missing-icon
      warnings.
