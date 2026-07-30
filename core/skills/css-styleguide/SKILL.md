---
name: "css-styleguide"
description: "UI/CSS styling conventions for React or Angular frontends: design tokens, responsive rules, component-scoped styles, accessibility states. Use when writing or reviewing CSS/SCSS, styled components, Tailwind classes, or Angular templates."
paths:
  - "**/*.{css,scss,tsx,jsx}"
---

# CSS & UI Styling Guidelines

## 1. Stack & Core Approach
* **Framework:** Angular / React - Adapt the CSS framework to the project's frontend stack (eg. Tailwind CSS, SCSS, Angular Material...).
* **Methodology:** Component-scoped styles
* **Responsive Approach:** Mandatory Mobile-first (`min-width`).

## 2. Design Tokens & Variables
> **Golden Rule:** Never hardcode colors, spacing, or fonts.

* **Colors:** Exclusively use global CSS variables or design tokens:
  * Use: `var(--color-primary)` or Tailwind class `bg-primary`
  * Never use direct values: `#FF5733` or `rgb(255, 87, 51)`
* **Spacing (Padding/Margin):** Use multiples of 4px / system scale (`gap-4`, `p-6`, `var(--space-md)`).
* **Typography:** Adhere to the typographic scale defined in the tokens (`text-sm`, `text-lg`, `font-semibold`).
* **Design System:** Adapt the rules to existing design systems if present.

## 3. React Best Practices
* **Dynamic Classes:** Use helper utilities like `clsx` or `cn()` (`tailwind-merge`) to conditionally join class names instead of raw string concatenation or heavy ternaries.
  * `className={cn("btn", isActive && "btn-active")}`
  * Avoid: `className={"btn " + (isActive ? "btn-active" : "")}`
* **CSS Modules:** Use named imports and `styles.class` syntax (e.g., `import styles from './Button.module.css'`).
* **Component Encapsulation:** Co-locate styling files directly next to their React components (e.g., `Button.tsx` and `Button.module.css` or `Button.styles.ts`).

## 4. Angular & Structure Best Practices
* **Component Scoping:** Keep styles inside the component's `.scss`/`.html` file. Use `:host` to target the host element.
* **Dynamic Classes:** Prefer modern Angular syntax `[class.is-active]="condition"` or `[ngClass]` over direct style manipulation.
* **Readability:** Extract reusable utility classes or components whenever a layout pattern repeats 3 times.
* **Animations:** Use Angular Animations (`@trigger`) for complex state transitions, or GPU-accelerated CSS properties (`transform`, `opacity`) for basic hovers.

## 5. Accessibility (A11y) & States
* **Interactivity:** Every interactive element must include explicit `:hover`, `:focus-visible`, and `:active` states.
* **Focus:** Never remove `outline: none` without providing a clearly visible replacement focus style.
* **Contrast:** Text must guarantee a minimum WCAG AA contrast ratio.
* **Dark Mode:** Account for dark mode (e.g., using `.dark-theme` classes or CSS variables).

## 6. Strict Rules (DON'TS)
* **NO `::ng-deep`** - It bypasses view encapsulation and pollutes global scope. Use CSS Custom Properties for child component overrides instead.
* **NO `!important`** unless explicitly overriding isolated 3rd-party library styles.
* **NO INLINE `style="..."` or `[style]="..."`** in template HTML for static properties.
* **NO Z-INDEX HACKS:** Use defined layer tokens (`z-10`, `z-20`, `z-50` for overlays/dialogs).
