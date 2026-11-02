# Kera Spare Tracker — Design System & UI Architecture Specification

**Document Version:** 1.0.0  
**Source:** Google Stitch Design Project `Kera Tracker Design System` (`projects/18265425042522896944`, Screen ID: `b02c232101c64182a77ebd03c3cd6e61`)  
**Target:** Flutter Client Design Foundation (`lib/core/design/` & `lib/core/theme/`)

---

## 1. Design Philosophy: Pragmatic Modern-Industrial

The Kera Spare Tracker design system is purpose-built for the high-intensity, dust-heavy, fast-moving automotive spare parts retail market in Kera, Addis Ababa.

### Core Principles
1. **High Optical Legibility**: High-contrast text, clear borders, and solid visual hierarchy ensure split-second readability under direct sunlight and on grease-smudged smartphone displays.
2. **Bilingual Equilibrium**: Natural, dignified coexistence of Ge'ez (Amharic) and Latin typography without vertical baseline clipping or optical overcrowding.
3. **Tactile Touch Targets**: Every interactive element (buttons, cards, chips, stepper counters) has a minimum touch target of $\ge 48\times 48\text{ px}$ to eliminate mis-taps during hurried counter sales.
4. **Immediate Data Discrimination**: Instant visual separation of parts availability (In-Stock, Low Stock, Out of Stock) and network status (Synced vs. Pending Local Queue).

---

## 2. Color Palette & Tonal System

### 2.1 Brand & Structural Palette

```
┌────────────────────────────────────────────────────────┐
│ PRIMARY NAVY: #172B4D       ACTION BLUE: #2563EB       │
│ Surface Canvas: #F8FAFC     Surface Pure: #FFFFFF      │
│ Utility Teal: #0D9488       Text Primary: #191C1E      │
└────────────────────────────────────────────────────────┘
```

| Token Name | Hex Code | Flutter `Color` | Usage & Semantic Role |
|---|---|---|---|
| `primaryNavy` | `#172B4D` | `const Color(0xFF172B4D)` | Top App Bar, master category headers, primary action buttons, structural anchors |
| `primaryNavyLight` | `#1E3A8A` | `const Color(0xFF1E3A8A)` | Active states for navy surfaces, secondary containers |
| `actionBlue` | `#2563EB` | `const Color(0xFF2563EB)` | Interactive triggers, primary call-to-actions, focus rings, active navigation items |
| `actionBluePressed`| `#1D4ED8` | `const Color(0xFF1D4ED8)` | Pressed / focused button states |
| `utilityTeal` | `#0D9488` | `const Color(0xFF0D9488)` | POS sales indicators, cart triggers, successful sync confirmation, wholesale tier |
| `surfaceCanvas` | `#F8FAFC` | `const Color(0xFFF8FAFC)` | Root background (Level 0), anti-glare canvas |
| `surfacePure` | `#FFFFFF` | `const Color(0xFFFFFFFF)` | Card surfaces (Level 1), input containers, bottom sheets |
| `surfaceMuted` | `#F1F5F9` | `const Color(0xFFF1F5F9)` | Table header backgrounds, secondary pill surfaces, disabled containers |
| `outlineBorder` | `#E2E8F0` | `const Color(0xFFE2E8F0)` | 1px card borders, list item dividers, input borders |
| `outlineVariant` | `#CBD5E1` | `const Color(0xFFCBD5E1)` | Subtle divider lines, inactive tabs |
| `textPrimary` | `#191C1E` | `const Color(0xFF191C1E)` | High-contrast headers, part names, primary currency amounts |
| `textSecondary` | `#64748B` | `const Color(0xFF64748B)` | Part numbers, shelf locations, bilingual sub-labels, timestamps |
| `textMuted` | `#94A3B8` | `const Color(0xFF94A3B8)` | Form placeholders, helper hints, disabled labels |

### 2.2 Semantic & Status Colors

| State | Background Hex | Text / Icon Hex | Flutter Implementation | Meaning in Kera App |
|---|---|---|---|---|
| **In-Stock** | `#DCFCE7` | `#16A34A` | `Color(0xFFDCFCE7)` / `Color(0xFF16A34A)` | Part in stock (በክምችት አለ) |
| **Low-Stock** | `#FEF3C7` | `#D97706` | `Color(0xFFFEF3C7)` / `Color(0xFFD97706)` | Stock at or below reorder threshold (አነስተኛ ክምችት) |
| **Out of Stock**| `#FEE2E2` | `#DC2626` | `Color(0xFFFEE2E2)` / `Color(0xFFDC2626)` | Zero or depleted stock (አልቋል) |
| **Offline Active**| `#FEF3C7` | `#B45309` | `Color(0xFFFEF3C7)` / `Color(0xFFB45309)` | Unsynced local modifications pending (ያልተላከ) |
| **Online Synced**| `#DCFCE7` | `#15803D` | `Color(0xFFDCFCE7)` / `Color(0xFF15803D)` | All local records synced to cloud (የተገናኘ) |
| **Error / Alert**| `#FEE2E2` | `#B91C1C` | `Color(0xFFFEE2E2)` / `Color(0xFFB91C1C)` | Sync conflict, form validation error, negative stock |

---

## 3. Typography System & Bilingual Harmony

### 3.1 Font Pairing
- **Amharic (Ge'ez Script)**: `NotoSansEthiopic` (bundled locally in `assets/fonts/NotoSansEthiopic.ttf`).
- **Latin & Numerals**: `Inter` / system fallback with OpenType `tnum` (Tabular Numbers enabled for financial figures).

### 3.2 Typography Scale

```
Headline Large (28px Bold)    ─── Screen Titles & Total Revenue
Headline Medium (22px SemiBold) ── Dialog Titles & Section Headers
Headline Small (18px SemiBold)  ── Card Titles & Large Amounts
Title Medium (16px SemiBold)   ── Part Display Names & Form Group Headers
Body Large (16px Regular)      ── General Body & Description Text
Body Medium (14px Regular)     ── Subtitles, Shelf Locations, Notes
Body Small (12px Regular)      ── Part Numbers & Metadata
Label Large (14px SemiBold)    ── Primary Action Buttons
Label Medium (12px Medium)     ── Filter Chips & Stock Badges
Label Small (11px SemiBold)    ── Category Tags & Status Indicators
Numeric Stat (24px Bold)       ── Currency Figures (ETB / ብር)
```

| Style Name | Font Size | Line Height | Weight | Letter Spacing | Flutter `TextStyle` |
|---|---|---|---|---|---|
| `headlineLarge` | 28 px | 36 px | Bold (700) | -0.02 em | `TextStyle(fontSize: 28, height: 36/28, fontWeight: FontWeight.w700)` |
| `headlineMedium`| 22 px | 30 px | SemiBold (600) | -0.01 em | `TextStyle(fontSize: 22, height: 30/22, fontWeight: FontWeight.w600)` |
| `headlineSmall` | 18 px | 26 px | SemiBold (600) | 0.0 em | `TextStyle(fontSize: 18, height: 26/18, fontWeight: FontWeight.w600)` |
| `titleMedium` | 16 px | 24 px | SemiBold (600) | 0.0 em | `TextStyle(fontSize: 16, height: 24/16, fontWeight: FontWeight.w600)` |
| `bodyLarge` | 16 px | 24 px | Regular (400) | 0.0 em | `TextStyle(fontSize: 16, height: 24/16, fontWeight: FontWeight.w400)` |
| `bodyMedium` | 14 px | 22 px | Regular (400) | 0.0 em | `TextStyle(fontSize: 14, height: 22/14, fontWeight: FontWeight.w400)` |
| `bodySmall` | 12 px | 18 px | Regular (400) | 0.0 em | `TextStyle(fontSize: 12, height: 18/12, fontWeight: FontWeight.w400)` |
| `labelLarge` | 14 px | 20 px | SemiBold (600) | 0.01 em | `TextStyle(fontSize: 14, height: 20/14, fontWeight: FontWeight.w600)` |
| `labelMedium` | 12 px | 16 px | Medium (500) | 0.0 em | `TextStyle(fontSize: 12, height: 16/12, fontWeight: FontWeight.w500)` |
| `labelSmall` | 11 px | 14 px | SemiBold (600) | 0.02 em | `TextStyle(fontSize: 11, height: 14/11, fontWeight: FontWeight.w600)` |
| `numericStat` | 24 px | 30 px | Bold (700) | 0.0 em | `TextStyle(fontSize: 24, height: 30/24, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])` |

---

## 4. Spacing, Elevation & Shape Standards

### 4.1 Spacing Scale
- `space-xs`: `4 px` (micro element padding, tag gaps)
- `space-sm`: `8 px` (list item gaps, icon-to-text spacing)
- `space-md`: `12 px` (card inner padding, row separation)
- `space-lg`: `16 px` (screen gutters, standard container padding)
- `space-xl`: `24 px` (section margins, dialog padding)
- `space-2xl`: `32 px` (hero headers, empty-state vertical spacing)

### 4.2 Border Radius Standards
- **Micro / Tags (`6 px`)**: Status pills, category badges, inline code tags, quantity stepper buttons.
- **Medium / Surfaces (`10 px`)**: Product cards, search fields, metric tiles, action buttons, dialogs.
- **Large / Drawers (`16 px`)**: Top edge of modal bottom sheets, filter drawers, checkout panels.
- **Fully Rounded (`9999 px`)**: Online/Offline status chips, avatar bubbles, floating pills.

### 4.3 Layering & Elevation
- **Level 0 (Canvas)**: Background color `#F8FAFC`. Zero elevation.
- **Level 1 (Resting Cards)**: Surface `#FFFFFF`, 1px border `#E2E8F0`, subtle shadow `0 1px 2px rgba(23, 43, 77, 0.05)`.
- **Level 2 (Raised Controls)**: Search bar, active filter chips, Floating Action Button. Shadow `0 4px 6px -1px rgba(23, 43, 77, 0.08)`.
- **Level 3 (Modal Overlays)**: Bottom sheets, confirmation alerts. Shadow `0 10px 15px -3px rgba(23, 43, 77, 0.12)` with `40%` dark scrim (`#0F172A` with `40%` opacity).

---

## 5. Reusable Component Specifications

### 5.1 Reusable Buttons (`KeraButton`)
- **Primary Action**: Background `#2563EB`, text `#FFFFFF`, radius `10px`, min height `48px`. Active press transitions to `#1D4ED8`.
- **Secondary Navy**: Background `#172B4D`, text `#FFFFFF`, radius `10px`, min height `48px`. Used for checkout finalization and master catalog actions.
- **Outlined Action**: Background `Colors.transparent`, border `1.5px solid #E2E8F0`, text `#172B4D`.
- **Destructive Action**: Background `#DC2626`, text `#FFFFFF`. Used for deleting parts and clearing cart.
- **Disabled State**: Background `#E2E8F0`, text `#94A3B8`, no click response.
- **Loading State**: Displays centered 20px `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` maintaining button dimensions.

### 5.2 Reusable Input Fields (`KeraTextField`)
- **Stacked Label Pattern**: 12px bold label placed directly above the input container.
- **Surface**: Solid `#FFFFFF`, 1px border `#E2E8F0`, radius `10px`, min height `48px`.
- **Focus State**: 2px outer ring in `#2563EB`.
- **Error State**: 1.5px border in `#DC2626`, error text in 12px `#DC2626`.
- **Bilingual Placeholders**: E.g., `የዕቃው ስም / Part Name...`

### 5.3 Product Card (`KeraProductCard`)
- **Dimensions**: Full width, horizontal padding `14px`, vertical padding `10px`.
- **Layout**:
  - **Left**: `64x64 px` rounded thumbnail or auto-part icon container (`#F1F5F9`).
  - **Center**:
    - Primary line: Part Title (e.g. `CAT 320D Oil Filter`) in 15px SemiBold text.
    - Secondary line: `#` Part Number + Brand badge pill (`CAT`, `Doosan`, `CTP`).
    - Tertiary line: Shelf location (`Shelf B-4 / መደርደሪያ B-4`).
  - **Right**:
    - Bold Tabular Price (`3,450 ብር`).
    - Stock Status Badge (`በክምችት አለ: 12`).
    - Fast `+` cart addition button (in POS mode).

### 5.4 Top App Bar (`KeraAppBar`)
- **Background**: Solid `#172B4D` (Navy).
- **Title**: White 18px SemiBold text with shop logo or back arrow.
- **Right Action / Sync Chip**:
  - If synced: Green dot + `የተገናኘ / Synced`.
  - If pending offline: Amber dot + `ያልተላከ (4) / Offline`.
  - Tap opens the dedicated **Sync Center & Queue** screen.

### 5.5 Modal Bottom Sheet (`KeraBottomSheet`)
- **Shape**: Top corners rounded at `16px`.
- **Header**: Centered drag handle (`36x4 px`, color `#E2E8F0`, margin `8px`).
- **Action Footer**: Pinned at the bottom with safe area insets to prevent keyboard or system bar obstruction.

