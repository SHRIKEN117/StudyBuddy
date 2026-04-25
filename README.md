# Handoff: StudyBuddy Redesign — Warm Indigo + Amber

## Overview

This bundle is a complete visual redesign of the **StudyBuddy** web app, moving it from a generic blue-teal glassmorphic look to a focused **Warm Indigo + Amber** academic palette. The redesign covers every primary surface: auth, dashboard, document view (Content / Chat / Flashcards / Quizzes), the dark sidebar, and all reusable components (buttons, inputs, tabs, badges, stat cards).

Implement these screens in the existing StudyBuddy app, replacing the current teal/emerald primary, white sidebar, and slate neutrals.

## About the Design Files

The files in this bundle are **design references created in HTML/JSX** — prototypes showing intended look and behavior, **not production code to copy directly**.

Your task is to **recreate these HTML designs in the StudyBuddy codebase's existing environment** (React + Tailwind, based on the audit notes — `@theme` blocks, `text-slate-*`, `bg-emerald-*` etc.) using the codebase's established patterns. Don't import the JSX files into the app. Read them, match the visuals exactly, and write the components in the codebase's idiomatic style.

If you discover the codebase uses something different (e.g. CSS modules, styled-components, Vue), adapt — the visuals are the source of truth, not the framework choice.

## Fidelity

**High-fidelity.** Pixel-perfect mockups with final colors, typography, spacing, and interactions. Match the design exactly:
- Use the exact hex values listed in **Design Tokens** below.
- Use Sora for headings, Urbanist for body, JetBrains Mono for code.
- Match radii, shadows, and motion timings exactly — they're tuned to feel "warm academic," not "cold fintech."

## Screens / Views

### 1. Auth (Sign in)
- **Purpose:** Sign in / sign up.
- **Layout:** Split-screen, 5fr / 6fr.
  - **Left panel:** Indigo-950 → Indigo-900 gradient background with two soft radial glows (amber top-right, indigo bottom-left). Brand at top, pitch in middle ("Drop a PDF. Chat, drill, master it." with "master it" in amber-300), testimonial card at bottom.
  - **Right panel:** Stone-50 background with the mesh-gradient. Form max-width 380px, vertically centered. Email field, password field, remember-me + forgot-password row, primary "Sign in" button (full width), divider, Google + SSO oauth buttons, footer "Create an account" link.
- **Reference file:** `ui_kits/web_app/Screens.jsx` → `AuthScreen`.

### 2. Dashboard
- **Purpose:** Landing after sign-in. See progress at a glance, jump to a recent document, upload a new one.
- **Layout:** 240px dark sidebar, top bar with breadcrumb + search + bell + user chip, main content max-width 1120px with 36px horizontal padding.
- **Components, top to bottom:**
  - **Page head:** "Welcome back, Shriken" (h1, Sora 700 / 30px, letter-spacing −0.02em). Sub: "You have 3 flashcard decks due today. Keep the streak going." (14px, stone-500). Right side: "Upload PDF" (secondary) + "New document" (primary indigo).
  - **Stat grid:** 4 colored gradient cards. Documents (indigo `#6366F1 → #4338CA`), Flashcards (amber `#FBBF24 → #F97316`), Quizzes (emerald `#10B981 → #0D9488`), Streak (rose `#F43F5E → #BE123C`). 16px gap, min-height 132px, white text, 36px white-rgba-18 icon box top-left, big number (Sora 800 / 36px) + label + delta line at bottom.
  - **Section header:** "Recent documents" (h2, Sora 700 / 18px) with right-aligned "View all →" link.
  - **Doc grid:** 3 columns × 2 rows. Each card has a paper-style thumbnail (8/5 ratio, stone-100 → white gradient, 6 placeholder text lines, course-code badge top-right indigo-100/700), then title (Sora 600 / 15px) and meta line.
- **Reference file:** `ui_kits/web_app/Screens.jsx` → `DashboardScreen`.

### 3. Document View
- **Purpose:** Read a PDF, chat about it, drill its flashcards, take its quizzes.
- **Layout:** Same shell as dashboard. Page-head shows back button + course chip on a row above; title + page count + "Generate flashcards" amber AI button. Below: tabs (Content / Chat / Flashcards / Quizzes) with counts. Selected tab content fills remaining height.
- **Tabs:** Underline style. Active = indigo-600 text + indigo-600 underline. Inactive = stone-500. Counts in pill: indigo-100/700 when active, stone-100/500 when inactive.
- **Content tab:** White card, 16px radius, 40px padding, 540px min-height. Meta row + h2 + paragraphs.
- **Chat tab:** Card containing scrollable stream + quick-prompt chips + composer.
  - User bubble: indigo-600 bg, white text, max 70% width, right-aligned, radius `18 18 4 18`, indigo box-shadow.
  - AI bubble: 30px amber sparkle avatar + white card bubble, border stone-200, radius `4 18 18 18`, optional source chips below a 1px stone-200 divider.
  - Composer: white pill, indigo focus ring, 36px amber gradient send button.
- **Flashcards tab:** Centered card stage, max-width 540px. Progress bar (amber gradient fill). 3D-flip card on click (`rotateY` 600ms `cubic-bezier(0.4, 0, 0.2, 1)`). Front: amber pin top-left, big question, hint footer. Back: amber tinted bg, indigo pin "Answer", answer text. Below: Again / Hard / Good / Easy spaced-repetition buttons with semantic colors.
- **Quizzes tab:** Centered card, max-width 720px. "Question N of M" caption, big question, 4 options as rows (28px mono key A/B/C/D, label, optional check icon). Selected = indigo border + soft indigo bg + key flips to indigo-600 white. Footer: Previous · pager · Next.
- **Reference file:** `ui_kits/web_app/Screens.jsx` → `DocumentScreen`.

### 4. Sidebar (global)
- **Purpose:** Primary nav.
- **Layout:** 240px wide, indigo-950 bg, full height. Brand at top (32px amber sparkle box + "studybuddy" wordmark Sora 700 / 16px). Items: Dashboard, Documents, Profile. "Account" section header (10px uppercase, indigo-200 65% opacity), then Logout (rose tint). Bottom-pinned "StudyBuddy Pro" upsell card (amber-tinted bg, amber gradient button).
- **Item states:**
  - Default: indigo-200 text, no bg.
  - Hover: rgba(255,255,255,0.08) bg, white text.
  - Active: rgba(245,158,11,0.15) bg, rgba(245,158,11,0.30) border, amber-300 text, amber glow shadow.
- **Reference file:** `ui_kits/web_app/Shell.jsx` → `Sidebar`.

### 5. Top bar (global)
- **Layout:** 16px / 36px padding, bottom border stone-200, semi-transparent stone-50/85 + 8px backdrop blur. Left: breadcrumb crumbs. Right: search icon-button, bell icon-button (amber dot for unread), user chip (28px indigo avatar + name/email).
- **Reference file:** `ui_kits/web_app/Shell.jsx` → `TopBar`.

## Interactions & Behavior

| Surface | Behavior |
|---|---|
| **All buttons** | Hover: `translateY(-1px)`, ease-out 180ms. Active: `scale(0.98)`. Primary adds indigo box-shadow on hover, AI buttons get brighter + bigger amber shadow. |
| **Cards (doc, stat)** | Hover: `translateY(-1px)` (doc) or `-2px` (stat), shadow bumps sm → md, border tints to indigo-200 (doc cards). |
| **Sidebar nav** | Click → set active. Active item gets amber pill instantly, no animation. |
| **Tabs** | Click → switch active tab. Underline animates only via the color/border change (no sliding pill). |
| **Chat composer** | Enter key sends if value is non-empty. Send button disabled when empty. New message slides in from below (240ms ease-out). |
| **Flashcard** | Click anywhere on the card → 3D `rotateY` flip, 600ms `cubic-bezier(0.4, 0, 0.2, 1)`. Spacebar should also flip. |
| **Quiz options** | Click → select. Selected option gets indigo border + soft bg + check icon. Clicking another deselects the previous. Submit on last question's "Next". |
| **Auth → Dashboard** | "Sign in" routes to dashboard. "Logout" in sidebar routes back to auth. |
| **Upload PDF** | Hook to existing upload flow. Visual target: a stone-300 dashed border zone that turns indigo-400 on hover. See `.upload` in `app.css`. |

## State Management

This is unopinionated — use whatever the codebase already uses (Redux, Zustand, React Query, plain useState). The mock-up uses local `useState` only because it's a static prototype. Real state needed:

- `auth.user` — current signed-in user (drives user-chip + protected routes)
- `documents` — list of uploaded PDFs (drives dashboard grid + nav)
- `documents[id].chat` — array of `{role: 'user' | 'ai', text, sources}`
- `documents[id].flashcards` — array of `{id, q, a, due, srsState}` for spaced repetition
- `documents[id].quizzes` — array of `{question, options, correctIndex}`
- `ui.activeNav` — sidebar active state
- `ui.documentTab` — `'content' | 'chat' | 'flashcards' | 'quizzes'` per-document

## Design Tokens

All in `colors_and_type.css`. Drop this into the codebase and import once at the root, OR translate to your Tailwind config.

### Colors

| Token | Hex | Use |
|---|---|---|
| **indigo-600** | `#4F46E5` | **Primary.** Buttons, active nav text, links, focus ring. |
| indigo-700 | `#4338CA` | Primary hover |
| indigo-100 | `#E0E7FF` | Soft surface, badge bg |
| indigo-950 | `#1E1B4B` | Sidebar background |
| **amber-500** | `#F59E0B` | **AI accent only.** Generate buttons, AI avatar bg, active sidebar pill. |
| amber-400 | `#FBBF24` | AI gradient start |
| amber-100 | `#FEF3C7` | Soft amber bg (badges, flashcard back) |
| stone-50 | `#FAFAF9` | App background |
| stone-100 | `#F5F5F4` | Hover surface |
| stone-200 | `#E7E5E4` | Default border |
| stone-500 | `#78716C` | Meta text |
| stone-700 | `#44403C` | Body text |
| stone-900 | `#1C1917` | Headings |
| emerald-500 | `#10B981` | Success / Quizzes gradient start |
| teal-600 | `#0D9488` | Quizzes gradient end |
| rose-500 | `#F43F5E` | Streak gradient start |
| rose-700 | `#BE123C` | Streak gradient end / urgent text |
| red-600 | `#DC2626` | Error |

### Stat-card gradients (135deg)

- Documents: `#6366F1 → #4338CA`
- Flashcards: `#FBBF24 → #F97316`
- Quizzes: `#10B981 → #0D9488`
- Streak: `#F43F5E → #BE123C`

### Typography

| Family | Use | Weights |
|---|---|---|
| Sora | Headings, display, brand | 600/700/800 |
| Urbanist | Body, UI, buttons | 400/500/600/700 |
| JetBrains Mono | Code, document IDs, kbd | 400/500 |

Load via Google Fonts:
```html
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700;800&family=Urbanist:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

Scale: display 44 / h1 32 / h2 24 / h3 20 / h4 17 / body 16 / ui 14 / meta 12.

### Spacing (4px base)

`--sp-1`=4, `--sp-2`=8, `--sp-3`=12, `--sp-4`=16, `--sp-5`=20, `--sp-6`=24, `--sp-8`=32, `--sp-10`=40, `--sp-12`=48, `--sp-16`=64, `--sp-20`=80.

### Radii

4 (xs), 6 (chips), 10 (buttons/inputs), 16 (cards), 24 (modals), 9999 (pills).

### Shadows (warm-tinted, no cool blue)

- `--shadow-sm`: `0 1px 2px rgba(28,25,23,0.04), 0 1px 1px rgba(28,25,23,0.03)` — cards at rest
- `--shadow-md`: `0 4px 12px rgba(28,25,23,0.06), 0 1px 3px rgba(28,25,23,0.04)` — card hover, menus
- `--shadow-lg`: `0 12px 32px rgba(28,25,23,0.08), 0 4px 8px rgba(28,25,23,0.04)` — modals, popovers
- `--shadow-amber`: `0 8px 24px rgba(245,158,11,0.25)` — amber/AI buttons only
- `--shadow-indigo`: `0 8px 24px rgba(79,70,229,0.18)` — primary button hover

### Motion

- Default ease: `cubic-bezier(0.2, 0, 0, 1)` (decelerated, calm)
- Durations: `--dur-fast`=180ms (hover), `--dur-base`=240ms (state), `--dur-slow`=320ms (layout)
- **No spring physics. No bounce. Press = scale 0.98 (shrink, not darken).**

### App background

```css
body {
  background: #FAFAF9;
  background-image:
    radial-gradient(at 20% 20%, rgba(79,70,229,0.06) 0, transparent 50%),
    radial-gradient(at 80% 80%, rgba(245,158,11,0.05) 0, transparent 50%);
  background-attachment: fixed;
}
```

## Voice & Copy

- **Sentence case** for every UI label, button, heading, menu item. (The wordmark "studybuddy" is the only exception and is already lower-case.)
- Speak directly to the student in second person ("you"). Avoid "users."
- Empty states are encouraging, not apologetic. Loading states are specific ("Reading your document…", not just a spinner).
- **No emoji** in product UI. Use Lucide icons.

## Iconography

Use **Lucide** outline icons, 1.5px stroke weight, 20px default. Sizes: 16 (inline), 20 (UI default), 24 (nav, page actions), 32+ (empty states).

The current codebase already appears to use Lucide-style icons — just keep that and unify on `lucide-react` if it's not already used.

Color rules:
- Inline in body text → `currentColor`
- Sidebar (dark) inactive → indigo-200
- Sidebar active → amber-300
- Stat-card icons → white (over the gradient)

## Assets

Included in `assets/`:
- `logo.svg` — full lockup (sparkle + wordmark)
- `mark.svg` — square sparkle mark only

Both are placeholders — if there's a real StudyBuddy logo, swap them. The geometry (44px rounded square, indigo-950 bg, amber gradient star) is the visual target either way.

## Files in this bundle

```
README.md                                 — this file
colors_and_type.css                       — drop-in stylesheet, all design tokens
SKILL.md                                  — Claude-Code skill manifest
assets/
  logo.svg                                — full lockup
  mark.svg                                — sparkle mark
preview/                                  — design-system reference cards
  colors-core.html                        — indigo + amber scales
  colors-neutrals.html                    — stone scale + semantic
  colors-stat-gradients.html              — the 4 dashboard gradients
  type-display.html                       — Sora display + headings
  type-body.html                          — Urbanist body + UI + meta + mono
  spacing-radii.html                      — spacing & radius tokens
  shadow-elevation.html                   — shadow levels
  components-buttons.html                 — button variants
  components-inputs.html                  — form inputs
  components-sidebar.html                 — dark sidebar
  components-chat-cards.html              — chat bubbles + flashcard
  components-tabs-badges.html             — tabs + badges + avatars
  brand-logo.html                         — logo on light & dark
ui_kits/web_app/                          — interactive recreation
  index.html                              — full click-thru: Auth → Dashboard → Document
  app.css                                 — all the component CSS
  Icon.jsx                                — inlined Lucide-style icons
  Shell.jsx                               — Sidebar, TopBar, StatCard, Button, DocCard, Tabs
  Chat.jsx                                — Chat bubbles, Composer, Flashcard, QuizCard
  Screens.jsx                             — DashboardScreen, DocumentScreen, AuthScreen
  README.md                               — UI kit notes
```

## Implementation order (recommended)

1. **Drop in `colors_and_type.css`** at the app root and import it once. This gives you every token immediately.
2. **Replace tokens in existing Tailwind/CSS:** `slate-*` → `stone-*`, the teal-emerald primary → `indigo-*`, the `#00d492` spinner → `var(--color-indigo-600)`.
3. **Sidebar redesign first** — biggest visual lift. See `Sidebar.jsx`.
4. **Stat cards next** — second-biggest lift. See `StatCard` in `Shell.jsx`.
5. **Auth split-screen** — see `AuthScreen` in `Screens.jsx`.
6. **Buttons** — switch primary to indigo; introduce the amber AI button for "Generate flashcards", "Generate quiz", and any "Ask AI" entry points.
7. **Flashcard 3D flip** — see `.fc-card` in `app.css` (5 lines of CSS).
8. **Polish:** chat bubbles, quiz options, doc cards, top bar.

Open `ui_kits/web_app/index.html` in a browser to click through the live target while you build.
