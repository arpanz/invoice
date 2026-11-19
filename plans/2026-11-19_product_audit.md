# Invoice Maker Pro: product audit, competitor study and overhaul plan

Date: 2026-11-19. App version audited: 1.1.0+2 (`com.livinlabs.invoice`), commit `66a8faa` on `main`.

This report has five parts:

1. Four theses: what is wrong at the level of ideas, not lines.
2. **Fixes**: defects in the current code, ranked P0 to P2, with file and line.
3. **Gaps**: features the market asks for that the app lacks, ranked by review evidence.
4. **Overhauls**: areas that need a redesign, not a patch.
5. Appendices: competitor evidence, an animation inventory, a settings and preferences inventory, and what this audit did and did not cover.

## How to read the tags

| Tag | Meaning |
|---|---|
| **[Code]** | Traced in the source. The file and line are given. |
| **[Review]** | Supported by Play Store (or other) user reviews of competitors. |
| **[Inference]** | My judgement from the code or the market. Not proven. Test it. |
| **[Code, sweep]** | Found by the verification sweep (Appendix D) and confirmed in source by an independent skeptic agent. Not re-traced line by line by me unless marked. |
| **P0** | Wrong money, lost data, or broken purchases. Fix before the next release. |
| **P1** | Broken promises, misleading UI, real friction. Fix within one or two releases. |
| **P2** | Polish, hygiene, accessibility. |

`flutter analyze` reports no issues, and all 79 tests pass. No test covers invoice numbering, PDF arithmetic, or data integrity, and every P0 defect below lives in those areas. Static cleanliness is not the same as correctness here.

---

## Implementation status (updated 2026-11-19)

The Tier 1 fixes (F1–F75) were worked through in the code. Gaps (G1–G15) and overhauls (O1–O7) were not started, except where a fix needed a small part of one (payments for O1, dark mode for O7). Nothing has been committed yet. At the end: `flutter analyze` is clean and 125 tests pass.

**Done:**
- F1–F9, F11–F15, F17–F24, F27–F30, F32–F34, F37–F42, F44–F69, F71, F73, F75.
- **F16**: The Privacy Policy link was removed from the paywall (the owner chose to drop policy and terms there). Only "Restore purchase" remains.
- **Client limit**: The free plan now allows 10 saved clients (was 5).
- **F38**: Font weights are 400/500/600 only and radii follow the DESIGN.md scale (4/8/12/16/pill). Sheets use 16.
- **F39**: Dark mode. Settings → Appearance offers "Same as device", Light and Dark. PDF pages, theme thumbnails and the signature canvas stay white (they are paper).
- **F46**: Invoice History is gone. Its extra actions (save to device, print) moved into the Invoices tab card menu.
- **F73**: Each invoice now has a payment history (date, amount, method, note). The paid amount is the sum of payments, and status follows from it. Older paid amounts were carried over as one payment each.

**Done in part:**
- **F10**: Export now includes estimate lines, payments, and the business and default settings. It is renamed "Export Data (JSON)" and says it cannot be restored yet. Restore needs O5.
- **F25/F26**: PDF fonts for Devanagari, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada, Malayalam and Sinhala download the first time a document needs them and are kept on the device. The app size is unchanged. The PDF library cannot shape these scripts, so some conjuncts and vowel signs may print imperfectly. The UI font (Inter) is still fetched at run time.
- **F31**: The status pills have screen-reader labels and larger touch areas. A full Semantics pass belongs to O7.
- **F35**: The Settings icon, the Items icon and the permanent red dot are fixed.
- **F36**: The business website now prints on documents. The tagline, business type and onboarding goal are still unused.
- **F43**: Thousands separators are in. Page numbers show when a document runs past one page. Amount in words is printed for INR only.
- **F70**: Validation, category reset, sort order, picker currency, tap order and the listener leak are fixed. The item description is still not printed.
- **F72**: The template header, stale preview, keyboard cover and the redundant "Set as default" checkbox in Settings are fixed. The studio still previews sample data.
- **F74**: The Back prompt, readiness rounding, signature cropping, signature messages and the editors' currency tick are fixed. The profile's currency pill still changes the app-wide currency (now the expected place to change it, but not labelled as such).

## 0. Executive summary

The app's surface is better than most of the category. It has a calm design system, ten free PDF themes, a real customization studio, a good preview, and offline-first storage. The core is not yet trustworthy as a **financial record**:

- The invoice number sequence can silently delete an existing invoice.
- Real invoices print a fake "APEX GLOBAL TECH" logo when the user has no logo.
- The PDF's tax lines do not add up to its total when there is a discount.
- Shipping is hidden inside the total with no line of its own, and disappears when the invoice is reopened.
- A "No Tax" choice in onboarding is ignored, so those users are charged 18% GST on every invoice.
- A duplicated invoice goes out showing the original's payment as already received.
- Old invoices are redrawn with today's business details.
- A sent PDF can differ from the previewed one.
- Monthly subscribers are not recognised by the UI until a restart. A pending (UPI) monthly purchase can be refunded automatically by Google.
- Backup has no restore.
- **The Estimates tab never finishes loading** once any estimate has a line item: a type cast in the shared line-item parser throws.
- **Every app start deletes the saved bank name** of anyone who banks with State Bank of India (it matches an old demo value).
- Converting an estimate twice empties the first invoice, and editing an estimate rounds 2.5% GST up to 3%.

Across twelve competitors and about 340 Play reviews, the 1-star reviews are rarely about missing features. They are about **broken trust**: price hikes, surprise paywalls, lost drafts, wrong amounts, and charges after cancelling. The 3- and 4-star reviews ask for features.

So the order of work is:

1. Make every invoice a correct, immutable, recoverable record (P0 fixes plus Overhaul O1).
2. Make every promise true (P1 fixes plus Overhauls O2 and O4).
3. Only then add the features the market asks for (the Gaps).

The strongest positioning available is the one the README already wrote and the code later abandoned: **an honest, offline, one-time-purchase GST invoice app**. That is a hole the incumbents' business models stop them from filling.

---

## 1. Four theses

Thesis 2 (the invoice is not treated as a record) is the best supported by the code and the most urgent. Theses 1 and 4 are well supported. Thesis 3 rests on smaller review samples and is the one to test before acting on it.

### Thesis 1: The app says more than it does (the promise–reality gap)

Many surfaces promise behaviour that does not exist.

| Promise | Where | Reality |
|---|---|---|
| Overdue alerts and monthly growth charts | Onboarding goal page feedback | No notifications, no charts. `InvoiceModel.isOverdue` is never called. **[Code]** |
| "Customize templates" based on business type | Onboarding business-type page | `business_type` and `onboarding_goal` are saved and never read. **[Code]** |
| "10 Premium PDF Themes" | Paywall `paywall_screen.dart:305` | All ten themes are already free. **[Code]** |
| "Fast-track help & automatic backups" | Paywall `paywall_screen.dart:316` | No automatic backup exists. Export has no import. **[Code]** |
| "Client & Inventory Manager" as a Pro feature | Paywall | Free users already have it. Its 5-client limit is never disclosed, and neither is the 5-invoice limit on Invoice History (F58). **[Code]** |
| ₹299 one-time, unlimited invoices, ads | README | The code has monthly plus ₹2,999 lifetime, 10 invoices a month, and no ads. **[Code]** |
| 100% offline | README / positioning | Inter, JetBrains Mono and the PDF fonts are downloaded at runtime by `google_fonts` / `PdfGoogleFonts`. **[Code]** |
| A payment method, attachments and a "Show PAID stamp" toggle | Create Invoice | None is saved, and none changes the PDF. **[Code]** |
| A default payment term chosen in onboarding | Onboarding payment-terms page | The due date is always +7 days (`create_invoice_screen.dart:201`). **[Code]** |
| "Help & Guide" | Settings | Re-runs onboarding, which resets currency and tax and stacks a second home screen. **[Code]** |
| "Share Invoice Link / File" | Preview | There is no link. **[Code]** |
| A sample invoice that adds up | Onboarding welcome animation | 1,800 plus tax shows 2,450 and a "PAID & SENT" badge. **[Code]** |

**Why it matters (abstract).** In this category users forgive a missing feature, but not a broken promise. The harshest reviews of Joist, Moon Invoice and Invoice Simple are about something that used to be free, or was said to be included, and then was not. **[Review]**

Every row above is a small refund request or 1-star review waiting to happen. The cheapest fix is subtraction: delete each promise that is not backed by code. Keep only the promises that are true.

### Thesis 2: The invoice is treated as a screen, not as a financial record

An invoice is a legal record. It must be:

- uniquely numbered,
- arithmetically consistent,
- immutable once issued (changes go through credit notes or versions),
- reproducible (the same PDF every time), and
- recoverable.

The app instead treats the invoice as an editable form that is redrawn from whatever is in memory or preferences now:

- **Numbering** uses `COUNT(*)+1` (`db_provider.dart:347`), and inserts use `ConflictAlgorithm.replace` (`db_provider.dart:264`). After any delete, the next number collides with an existing invoice, and REPLACE deletes that invoice. **[Code]**
- **The issuer is not snapshotted.** Every PDF render reads the live `biz_*` preferences (`invoice_history_screen.dart:471`, `invoice_preview_screen.dart:81`). Change your address, GSTIN or bank details, and every past invoice changes too. Becoming Pro removes the watermark from old invoices; a lapsed subscription adds it back. **[Code]**
- **The design is not part of the record.** The per-invoice design lives in SharedPreferences (`invoice_customization_<id>`), not in the database. Sharing from the Invoices list or History ignores it (`dashboard_screen.dart:470`, `invoice_history_screen.dart:389` pass only a theme), so the PDF sent from a list can differ from the one previewed. **[Code]**
- **Fields are lost.** Shipping has no column of its own (it survives only inside the total), and payment method, attachments and the PAID stamp toggle are not stored. **[Code]**
- **Saves are not atomic.** A save inserts the invoice, deletes its lines, then inserts lines one by one, with no transaction. `PRAGMA foreign_keys` is never enabled, so `ON DELETE CASCADE` never runs and deleted invoices leave orphan line items. **[Code]**
- **Money is stored as `double`**, and the PDF uses `toStringAsFixed` without thousands separators. **[Code]**
- **The second document type is not even readable.** Estimates are saved fine but cannot be loaded back into the list (F47), converting one twice empties an invoice (F49), and editing one rounds its tax (F50). **[Code]**
- **Nothing can be restored.** Backup is export-only and omits estimate line items, all preferences (the whole business profile and every design), the logo and the signature. **[Code]**

**Why it matters (abstract).** The app optimises the moment of creation, where all the craft is (coachmarks, 15 haptic points in onboarding, a skyline painter). It neglects the record's lifetime: month 12, the tax audit, the new phone.

Competitor reviews show the same asymmetry. Users tolerate a clunky editor. They leave, angrily, over lost drafts, lost data and wrong amounts. Invoice Simple reviewers in 2026 describe erased drafts and a wrong payment-link amount. Bookipi reviewers describe two months of server errors. Vyapar reviewers say backup was their own problem. **[Review]**

### Thesis 3: The monetization copies the model the market is punishing

The commonest 2025–26 complaint across the category is pricing hostility:

- Invoice Simple: monthly price roughly tripled, yearly price up about 5×, and the free cap cut from 10 to 3 invoices a month.
- Bookipi: free access removed suddenly.
- myBillBook: renewals 5–6× the first-year price.
- Moon Invoice: one-time buyers pushed onto a subscription.
- Joist: the logo and other free features moved behind a paywall.
- Invoice2go: a jump from about $99 to about $400 a year.

**[Review]**

This app moved towards that model:

- A monthly subscription, plus a monthly cap on invoices and estimates.
- Undisclosed limits: 5 clients (which the user can get around by deleting a client) and only the first 5 invoices visible in History, search included (F58). The monthly cap also leaks through three side doors (F57).
- A logo paywall that appears **only in onboarding** (`BusinessProfileScreen` has no gate). This is the exact thing Joist's users revolted over.
- Paywall copy that sells features the free user already has.

The plumbing is also broken:

- `_grantPremium()` (`paywall_screen.dart:148`) updates only `AdManager`, but the UI watches `BillingService`, which knows only the lifetime and yearly IDs. A monthly buyer sees "Pro Activated!" and stays free until restart. **[Code]**
- Only the paywall's own listener acknowledges a monthly purchase. If the user closes the paywall while the payment is pending (common with UPI), nothing acknowledges it later. Google refunds unacknowledged purchases after 3 days. **[Code + Play Billing policy]**
- `BillingService` never sets Pro to false. Revocation depends on `AdManager._validatePremiumState` getting a restore event, and even then `BillingService` keeps its in-memory `true` for the session. **[Code]**
- Prices fall back to hard-coded ₹ amounts for every locale, there is no subscription terms disclosure, and "Privacy Policy" is plain text, not a link (`paywall_screen.dart:481`). This is a Play policy risk. **[Code]**

**Why it matters (abstract).** The incumbents (Vyapar, myBillBook, Zoho, Swipe) out-feature this app by years, so it cannot win on features. Their weakness is their business model: subscriptions, upsell calls, renewal hikes and cloud lock-in. Reviewers say this loudly.

**The strongest counter-argument.** The same incumbents hold 4.7–4.8 ratings at 10M+ installs on the subscription model, so angry reviews show a loud minority, not proof that a one-time price wins. Offline, one-time and India-first also means the lowest willingness to pay, strong free competitors (Zoho, Refrens), and no recurring revenue to fund GST upkeep. An offline app also cannot easily do e-invoicing or hosted payment links, which is where a growing customer goes next. Treat Thesis 3 as a hypothesis: test pricing (for example, lifetime versus yearly) before removing the monthly plan. **[Inference]**

An offline app with a fair one-time price is a position the incumbents structurally cannot copy without hurting their own revenue. The README described exactly that, and the code walked away from it. **[Inference]**

### Thesis 4: The app has not decided who it is for (currency is not jurisdiction)

The schema is Indian GST (`sgst/cgst/igst`, `gstin`, `ifsc`, `upi`, `hsn_code`). But:

- The default currency is `SupportedCurrencies.all.first`, which is USD with an 8.875% New York sales tax.
- EUR is one "European Union" entry with a flat 20% VAT.
- Currency drives the tax names, the invoice title, the bank-field labels and the locale.
- An Indian business that bills a US client in USD gets "Sales Tax" and "EIN" labels on its own invoice.
- For non-Indian currencies the single tax is stored in the `igst_rate` column.
- `thousandSeparator` and `decimalSeparator` are stored but ignored, and `CurrencyFormatter` uses the `en_US` locale for everything except INR.
- `parseAmount` keeps only digits and dots, so "1,5" becomes 15 and a minus sign is lost.

**[Code]**

**Why it matters (abstract).** Currency is a property of a document. Jurisdiction (tax regime, labels, legal fields) is a property of the **issuing business**, and partly of the client (place of supply). Merging them gives an app that is half-right everywhere and fully right nowhere.

The decision is strategic, not technical:

- **Option A — India first** (recommended, given the schema, UPI, and the INR price anchors). Do GST properly: HSN/SAC per line, per-line tax, place of supply, automatic CGST+SGST versus IGST from the two state codes, and the amount in words. Treat other countries as "simple mode". Confirm this with the Play Console's installs-by-country split before committing: India-first is inferred from the schema, and the shipped default currency is USD.
- **Option B — truly global.** Model the jurisdiction separately and accept a much larger job.

**[Inference]**

### A cross-cutting observation: craft is spent at the edges

Most of the polish sits where the user spends the least time or money:

- the onboarding fake invoice with 15 haptics,
- the paywall skyline `CustomPainter`,
- staggered list entrances, and
- ten PDF themes.

The parts every invoice depends on (numbering, tax arithmetic, persistence, backup) have no tests. This is the usual failure of a small team that cares about quality: craft goes where it is visible. The correction is to put the same care, and a test suite, on the invisible core. **[Inference]**

---

## 2. Tier 1: Fixes (defects in the current code)

### Patterns behind the defects

The 75 defects are not independent. Five root patterns produce most of them, and fixing a pattern removes a family of bugs at once:

| Pattern | Defects it produces | Root fix |
|---|---|---|
| **REPLACE used as insert.** `DbProvider.insert` uses `ConflictAlgorithm.replace` for everything, so any key collision silently deletes or moves data. | F1, F18, F49 | Insert with `abort`, use `update` for edits, and generate fresh UUIDs on copy (O1). |
| **Estimates are a forked copy of invoices that has drifted.** The estimate editor, list and preview duplicate about 1,400 lines and have fallen out of step: a parser that does not fit the table, different rounding, different defaults, a different theme ID format, invoice labels on the PDF. | F47, F50, F52–F56, F67 | One document editor and one model with a `type` (O1, O6). |
| **Number formatting is improvised at every call site** (`replaceAll('.0','')`, `toStringAsFixed(0/1)`, `toStringAsFixed` without grouping). | F7, F43, F50, F51, F62, F71, F27 | One `formatQuantity` / `formatRate` / `formatMoney` utility with tests. |
| **Gating is scattered.** Each screen checks Pro, or does not, on its own. | F17, F18, F23, F57, F58 | One `EntitlementService.canCreate(type)` gate (O2). |
| **State lives in two places.** Preferences and the database both hold parts of a document; two services both hold Pro. | F6, F8, F9, F19, F52, F59, F60 | The document row is the single source of truth (O1); one entitlement service (O2). |

### P0: wrong money, lost data, broken purchases

| # | Defect | Where | Evidence | Fix |
|---|---|---|---|---|
| F1 | **New invoices overwrite existing ones.** The create screen numbers with its own `COUNT(*)+1` query, formatted as `INV%05d`. Delete any invoice except the latest and the next number equals one that already exists (create 1–3, delete #2 → the next number is INV00003). Saving goes through `DbProvider.insert` with `ConflictAlgorithm.replace`, so the UNIQUE `invoice_number` makes SQLite delete the old row. The same happens with a typed duplicate number, the `'INV00001'` fallback, estimate→invoice conversion (`getNextInvoiceNumber`), and the same pattern for estimates. Edits also go through REPLACE. | `create_invoice_screen.dart:235–239, 293, 345, 648`; `core/database/db_provider.dart:264, 340, 347` | [Code] | Keep a `number_series` table (prefix, next value) and allocate inside a transaction. Insert with `ConflictAlgorithm.abort` and show a clear "number already used" error. Use `update` for edits. Add a regression test: create 3, delete #2, create → #4. |
| F2 | **A fake "AP / APEX GLOBAL TECH" logo is printed on real invoices** whenever no logo image loads. That covers every user who skipped the logo, every free user stopped by the onboarding logo paywall, **and users who did set a logo whose cached file has since vanished** (see F24). | `invoices/services/pdf_generator_service.dart:177–184` (load), `417, 554, 591, 847` (and the inline "AP" variant near 669) | [Code] | Draw the vector logo only when `isSamplePreview`. Otherwise show the business initials or nothing. (The signature is already guarded correctly.) |
| F3 | **The PDF's tax lines do not add up to its total.** SGST, CGST and IGST are printed as `invoice.subtotal * rate`, but the grand total uses the post-discount taxable amount. Any discount makes the document inconsistent. | `pdf_generator_service.dart:1335, 1344` (IGST likewise) | [Code] | Compute every printed figure from one `InvoiceTotals` value object, the same one the editor uses. Golden-test the PDF numbers. |
| F4 | **Shipping is folded into the total as an unlabelled amount, and is lost on reopening.** `_grandTotal` includes `_shippingFee` and is stored as `grand_total`, so the PDF total includes shipping, but no line shows it and the breakdown does not add up. There is no shipping column, so reopening the invoice sets shipping to 0, and re-saving silently lowers the total. | `create_invoice_screen.dart:97, 268, 1394–1423`; no column in `invoices` | [Code] | Add a `shipping` column (migration v5) and a labelled PDF line. For existing rows, back-fill shipping as `grand_total − (taxable + tax)` when that difference is positive. Include it in `InvoiceTotals`. |
| F5 | **Per-line tax is baked into the unit price, then the invoice-level tax is applied again** (double tax). It also hides the tax, which GST invoices must show separately. **Saved items lose their own tax rate, HSN and unit** when picked: the invoice-wide rate (18% by default in India) is used instead. | `create_invoice_screen.dart:848, 1056`; `items/screens/item_picker_sheet.dart:84–91` | [Code] | Add `tax_rate`, `hsn_sac`, `unit` and `discount` to `line_items`. Tax per line, and sum per rate on the PDF. Remove the "effective unit price" trick. |
| F6 | **Monthly subscribers stay free in the UI until restart, and pending monthly purchases may never be acknowledged.** `_grantPremium` updates only `AdManager`, and no UI reads `AdManager.isPro`. `BillingService` knows only the lifetime and yearly IDs, so the startup restore ignores monthly. Only the paywall's own listener calls `completePurchase` for monthly. If the paywall closes while a UPI payment is pending, nothing acknowledges it automatically (only a manual tap on the paywall's Restore button would), and Google refunds unacknowledged purchases after 3 days. **The legacy lifetime ID (`invoice_maker_pro_lifetime`) has the same gap:** a legacy buyer on a new phone stays free until they open the paywall and tap Restore. | `paywall/paywall_screen.dart:135–148`; `core/billing/billing_service.dart:76`; `core/ads/ad_manager.dart:15–18` | [Code] | Use one `EntitlementService` that knows every product ID (including legacy), listens for the app's whole lifetime, always acknowledges, and is the only thing the UI watches. Delete `AdManager`'s Pro logic. |
| F7 | **Quantity 1.05 shows as "15".** The edit sheet pre-fills with `quantity.toString().replaceAll('.0','')`. The same pattern on the tax fields is safe only because of `toStringAsFixed(1)`. | `create_invoice_screen.dart:823`; the estimate editor has the same bug | [Code] | Use a number formatter that trims trailing zeros properly. Add a unit test. |
| F8 | **Old invoices are rewritten.** Every render reads the live business profile and the live Pro state. | `invoice_history_screen.dart:471`; `invoice_preview_screen.dart:81`; dashboard share | [Code] | Snapshot the issuer (name, address, GSTIN, bank, logo hash) and the design onto the invoice when it is issued. Render from the snapshot. |
| F9 | **A PDF shared from a list differs from the previewed one.** The list and history share paths pass only a `PdfTheme` and ignore the saved `invoice_customization_<id>` (fonts, density, toggles, footer). | `dashboard_screen.dart:470`; `invoice_history_screen.dart:387–399` | [Code] | Use one `renderInvoicePdf(invoiceId)` entry point for every path. Better: persist the design in the database (see O1). |
| F10 | **Backup cannot be restored and is incomplete.** It is a JSON export only. It omits `estimate_line_items`, every preference (the whole business profile, every design, numbering), and the logo and signature images. | `settings/screens/settings_screen.dart` (Data & Backup) | [Code] | See O5: a full archive plus restore. Until then, rename it "Export data (JSON)" so it does not promise a backup. |
| F11 | **Foreign keys are off and saves are not atomic.** Deleted invoices leave orphan line items. A crash mid-save leaves an invoice with no lines. | `db_provider.dart` (no `PRAGMA foreign_keys = ON` in `onConfigure`); the create and edit save paths | [Code] | Wrap every multi-row write in `db.transaction` first. **Before** enabling foreign keys, give `invoices.client_id` and `estimates.client_id` an `ON DELETE SET NULL` rule (a table rebuild in migration v5). Otherwise, once foreign keys are on, deleting any client who has invoices will throw (`client_list_screen.dart:252` is a bare delete). Clean up orphans in the same migration. |
| F12 | **"No Tax (0%)" chosen in onboarding is never saved** (`if (_taxRate > 0)`). New invoices start with tax on at the currency default (`create_invoice_screen.dart:203`), so a user who said "No Tax" gets 18% (India) on every invoice. *(Moved up from P1.)* | `onboarding/screens/onboarding_screen.dart:169` | [Code] | Always save the chosen rate, including 0. |
| F18 | **A duplicated invoice goes out marked as paid.** Duplicate copies `paidAmount` (`invoice_preview_screen.dart:726`), and the PDF prints "Amount Paid" whenever it is above 0. It also keeps the old date, uses `'INV'` plus the last six digits of epoch millis as the number (which breaks the series and, with REPLACE, can rarely overwrite an invoice), uses `'li-<micros>'` line IDs, and bypasses the free monthly cap. *(Moved up from P1.)* | `invoice_preview_screen.dart:723–740` (Duplicate) | [Code] | Duplicate as a new draft: next series number, today's date, paid 0, UUID line IDs, through the same cap check. |
| F47 | **The Estimates tab never finishes loading once any estimate has a line item.** Estimate lines live in `estimate_line_items`, which has `estimate_id` and no `invoice_id`, but they are parsed with the invoice `LineItemModel.fromMap`, which does `map['invoice_id'] as String`. That throws, `_loadEstimates` never reaches `_isLoading = false`, and the tab shows a spinner for ever. Editing from Estimate Preview hits the same parser. No test loads an estimate from the database. | `features/invoices/models/line_item_model.dart:23`; `estimate_list_screen.dart:85`; `estimate_preview_screen.dart:482` | [Code] (verified by me) | Give estimate lines their own `fromMap` (or read `estimate_id`). Wrap list loads in try/finally so a bad row cannot hang the screen. Add a database round-trip test for estimates. |
| F48 | **Startup deletes real users' bank details and other profile fields on every launch.** `_cleanupLegacyMockData()` runs on every cold start with no one-time flag, and removes each `biz_*` key on its own when it equals an old demo value. Any user whose bank is "State Bank of India" (India's largest bank) or "Chase Bank" loses the bank name every time the app starts, so their invoices print without it. The same applies to the other demo values (names, addresses, phones, IFSC). | `main.dart:44, 97–124` | [Code] (verified by me) | Run the cleanup once, behind a preference flag, and only when **all** demo fields match together. Ship it as an urgent patch. |
| F49 | **Converting an estimate a second time strips every line item from the first invoice.** Both conversion paths copy the estimate's line IDs into `line_items` (`'id': item.id`), and the insert uses REPLACE on the primary key. A converted estimate can be set back to Accepted/Pending from the card menu or the preview status picker, which brings back "Convert to Invoice". The second conversion moves the line rows to the new invoice, and the first invoice keeps its total but has an empty body. | `estimate_list_screen.dart:188–189, 832–845`; `estimate_preview_screen.dart:253–293, 389–390`; `estimate_model.dart:157` | [Code, sweep] | Give converted lines fresh UUIDs. Block conversion when `converted_invoice_id` is set, and lock status changes on converted estimates. Convert in one transaction. |
| F50 | **Editing an estimate rounds its tax rates and discount to whole numbers, and re-saving changes the total.** Edit mode pre-fills with `toStringAsFixed(0)`, so SGST 2.5 + CGST 2.5 becomes 3 + 3, and a ₹99.50 discount becomes ₹100. Opening Preview PDF in edit mode also saves. Conversion carries the wrong figures into the invoice. | `create_estimate_screen.dart:144, 148–150` | [Code, sweep] | Pre-fill with a formatter that keeps decimals, as the invoice editor does. Add an open-and-re-save test. |
| F51 | **Editing a saved item changes its price when the price has a `.0x` decimal.** The item sheet pre-fills price, default quantity and discount with `toString().replaceAll('.0', '')`, so a ₹10.05 item reopens as ₹105 and is saved that way. | `items/screens/create_edit_item_sheet.dart:103–110` | [Code] (verified by me) | Same formatter fix as F7, with a unit test. |

### P1: broken promises, misleading UI, real friction

| # | Defect | Where | Evidence | Fix |
|---|---|---|---|---|
| F13 | First-run "Create my first invoice" CTA races with itself. `completeOnboarding()` notifies listeners **before** its awaited preferences write, and `AppStartup` then swaps `OnboardingScreen` for `MainNavigationShell`. If the next frame wins, `mounted` is false and the user lands on the dashboard instead of the editor. If the write wins, `pushReplacement` puts Create Invoice in place of the root route, so Back exits the app. | `onboarding_screen.dart:160–182`; `main.dart:142–165`; `currency_provider.dart:112` | [Code path; which outcome happens needs a device run] | Navigate first and complete onboarding last, or route through the shell with an "open create" argument. |
| F14 | "Help & Guide" re-runs the full onboarding. Finishing it resets the currency to the page default and the tax rate (unless the user re-picks them), and `pushReplacementNamed('/home')` stacks a second shell on the first. | Settings → Help & Guide; `onboarding_screen.dart:180` | [Code] | Make it a read-only guide, or start onboarding pre-filled from current settings and end with `popUntil(isFirst)`. |
| F15 | The due date ignores `default_payment_terms` (always +7 days). | `create_invoice_screen.dart:201, 590` | [Code] | Derive the due date from the saved terms. Show the terms on the PDF. |
| F16 | Paywall claims that are false or misleading (premium themes, automatic backups, client manager). The 5-client cap and the 5-invoice History limit (F58) are not mentioned. There is no privacy-policy link and no subscription terms text. | `paywall_screen.dart:305, 316, 481` | [Code] | Rewrite the copy from what the code actually gates. Add tappable Terms and Privacy links, plus renewal and cancel text next to the monthly price. |
| F17 | The onboarding logo picker opens the paywall for free users, but Business Profile lets them add a logo freely. The rule is inconsistent and repeats Joist's backlash. | `onboarding_screen.dart` (profile page) vs `business_profile_screen.dart` | [Code] [Review: Joist] | Remove the onboarding logo gate. A logo should never be a paid feature. |
| F19 | "Sent" is set when the share sheet opens and is stored in preferences (`invoice_sent_<id>`), not the database. | `invoice_preview_screen.dart:64–72` | [Code] | Ask "Mark as sent?" after sharing, and store the status in the database. |
| F20 | Download saves to the app-private documents folder, which the user cannot see. The "View" snackbar action does nothing. | `invoice_preview_screen.dart`; `invoice_history_screen.dart:450–468` | [Code] | Save through the Storage Access Framework or MediaStore (Downloads), and open the file on "View". |
| F21 | Overdue is never computed. `InvoiceModel.isOverdue` is unused, and the Overdue filter shows only invoices manually set to overdue. | `dashboard_screen.dart`; `invoice_model.dart` | [Code] | Derive overdue from the due date and the balance at read time. Do not store it. |
| F22 | Dashboard totals add up amounts in different currencies. | `dashboard_screen.dart` | [Code] | Group totals by currency, or show only the home currency with a "+2 other currencies" note. |
| F23 | Free-cap logic counts `created_at` per calendar month, but the paywall copy doesn't say "per month". Deleting a client frees a client slot, so the client cap is pure friction. | `create_invoice_screen.dart:40`; `client_list_screen.dart:71` | [Code] | See O2. |
| F24 | The logo and gallery-picked signature are stored as `image_picker` cache paths, which Android can clear. Picking a signature on an invoice overwrites the global one. | `business_profile_screen.dart`; `create_invoice_screen.dart` (signature) | [Code] | Copy the image into app documents (as the drawn signature already does). Store per-invoice signatures separately. |
| F25 | PDF font fallbacks cover only Arabic, Bengali and Thai. Devanagari, Tamil, Telugu, Gujarati and CJK client names or items print as boxes. | `pdf_generator_service.dart` (`_PdfFonts`) | [Code] | Bundle Noto Sans Devanagari, Tamil, Telugu and Gujarati, at least. |
| F26 | Fonts are downloaded at runtime (`GoogleFonts.inter`, `PdfGoogleFonts.*`). On a first run with no network the PDF falls back, and the app is not truly offline. | `core/theme/app_typography.dart`; `pdf_generator_service.dart` | [Code] | Bundle the fonts as assets and set `GoogleFonts.config.allowRuntimeFetching = false`. |
| F27 | `CurrencyFormatter.parseAmount` turns "1,5" into 15 and drops minus signs. Separators stored per currency are ignored. | `core/utils/currency_formatter.dart` | [Code] | Parse with a locale-aware `NumberFormat`. |
| F28 | The onboarding sample invoice does not add up (1,800 + tax → 2,450, "PAID & SENT"). | `onboarding_screen.dart` (welcome page) | [Code] | Compute the sample from real numbers. A finance app's first screen must not contain wrong arithmetic. |
| F29 | Raw exception strings reach users ("Purchase failed: PlatformException(...)", "Failed to share: ..."). | Paywall; history; preview | [Code] | Map errors to plain messages, and log the details. |
| F30 | Unsaved work is lost: Back on Create Invoice discards everything with no confirmation and no draft. Invoice Simple users complain loudly about the same thing. | `create_invoice_screen.dart` | [Code] [Review] | Autosave drafts (see O6). Until then, add a `PopScope` "Discard changes?" dialog. |
| F52 | Saving the estimate editor after using Preview undoes what Preview did. The editor stays under Preview with stale state. Saving rewrites `status` (back to Pending) and `converted_invoice_id` (to null) and the old line items. That wipes a conversion (which then enables F49), a status change, or an edit made through Preview → Edit. | `create_estimate_screen.dart:247, 286–312, 337–346`; `estimate_preview_screen.dart:461–466` | [Code, sweep] | Replace the editor route when opening Preview, or never write status and conversion fields from the editor. |
| F53 | New estimates ignore the Settings "Default Tax Rate" (they read the raw currency default) and round it to a whole number. USD's 8.875% becomes 9%. An Indian user who set 12% gets 18% on estimates but 12% on invoices. | `create_estimate_screen.dart:162–169` | [Code, sweep] | Use `currencyProvider.defaultTax`, as invoices do, without rounding. |
| F54 | For single-tax currencies, tax cannot be added when editing an estimate that was saved without tax: it always computes 0. | `create_estimate_screen.dart:147` | [Code, sweep] | Initialise the single-tax field and its toggle consistently in edit mode. |
| F55 | The PDF theme chosen in Create Estimate is never applied. It is saved as the Dart enum name (`emeraldExecutive`), which `PdfTheme.fromId` does not recognise, so every estimate renders as Classic. | `create_estimate_screen.dart:316–319`; `invoices/models/pdf_theme.dart:56–90` | [Code, sweep] | Save `id.value` (as invoices do) and migrate existing values. |
| F56 | Estimate PDFs are labelled as invoices: "Invoice #", the expiry shown as "Due Date", and an "UNPAID" badge. | `pdf_generator_service.dart:127, 137, 456, 462, 519, 525, 627, 630, 808` | [Code, sweep] | Pass a document type into the renderer and label from it. |
| F57 | More free-cap holes. "New Invoice" in the client detail sheet skips the monthly invoice cap, and so does estimate→invoice conversion. Duplicate (F18) is the third. | `client_list_screen.dart:746–755`; `estimate_preview_screen.dart:377` | [Code, sweep] | Route every invoice creation through one gate (see O2). |
| F58 | **An undisclosed paywall in Invoice History.** Free users see only the first 5 invoices, applied after search and filter, so searching for an older invoice finds nothing. The paywall does not mention it. | `invoice_history_screen.dart:518–523, 858, 884` | [Code, sweep] | Remove it: hiding a user's own records is the kind of gate reviewers punish (SpeedInvoice's trial lock-out). |
| F59 | A saved default design overrides the per-invoice template. Preview reads `invoice_customization_<id> ?? default_invoice_customization` and looks at `invoice_theme_<id>` only when both are missing, so a template picked in Create Invoice is ignored once any default exists. | `invoice_preview_screen.dart:97–117` | [Code, sweep] | One resolution order: per-invoice config, then per-invoice theme, then the default. Better: store the design on the document (O1). |
| F60 | Theme picker → "Customize Design & Typography" throws away fonts, density, layout, toggles, footer and colours: only a `PdfTheme` (ID, colours, paper style) is passed back. | `invoices/widgets/pdf_theme_picker_sheet.dart:173–180` | [Code, sweep] | Return the full `InvoiceCustomizationConfig`. |
| F61 | The Geometric Banner and Two-Tone Split headers drop the due date and the status badge, and Two-Tone also drops the uploaded logo. | `pdf_generator_service.dart:639–817` | [Code, sweep] | Render the same required fields in every header variant. Golden-test each theme. |
| F62 | The new-invoice tax pre-fill rounds to 1 decimal, so the default USD rate of 8.875% is charged as 8.9%. | `create_invoice_screen.dart:207–211` | [Code, sweep] | Use the decimal-preserving formatter. |
| F63 | Status and paid amount drift apart when items change after an invoice was marked Paid or Partially Paid (for example "Paid" with a balance due). | `create_invoice_screen.dart:1472` | [Code, sweep] | Derive status from payments and total (O1). |
| F64 | The PDF title comes from the currency, not the tax: "TAX INVOICE" prints on 0%-tax invoices, and CNY invoices are titled "FA PIAO". | `core/models/currency_model.dart:801` | [Code, sweep] | Title from the issuer's regime and whether tax applies (O3). |
| F65 | Signature pad: vertical strokes drag or dismiss the sheet (`enableDrag` is left at its default), and stroke starts are lost. | `settings/widgets/signature_pad_sheet.dart:12–17` | [Code, sweep] | `enableDrag: false`. Capture `onPanStart`. |
| F66 | Duplicating a saved item drops its tax rate and discount. | `items/screens/item_list_screen.dart:117` | [Code, sweep] | Copy every field. |

### P2: polish, hygiene, accessibility

| # | Issue | Where | Evidence |
|---|---|---|---|
| F31 | There are no `Semantics` widgets anywhere and only 11 tooltips. Screen-reader users cannot use the app. | app-wide | [Code] |
| F32 | No reduce-motion support (`MediaQuery.disableAnimations` is never read). | app-wide | [Code] |
| F33 | `StaggeredEntrance` delay is `index × 50 ms` with no limit. In Items and History, row 60 stays blank for 3 s when scrolled to, and rows re-animate every time they scroll back into view. | `core/theme/app_animations.dart:80`; four call sites | [Code] |
| F34 | Dead code: `_animCtrl` (2,400 ms) in onboarding and `AppAnimations.slideUpRoute` are unused. | `onboarding_screen.dart:95`; `app_animations.dart:14` | [Code] |
| F35 | The hamburger icon opens Settings, not a drawer. The Items card uses a chat-bubble icon. Preview "More" has a permanent red dot. | dashboard; create invoice; preview | [Code] |
| F36 | Saved but never used: `tagline`, `website` and profile `notes` (only as a notes fallback), `business_type`, `onboarding_goal`. | business profile; onboarding | [Code] |
| F37 | The empty state shows the raw key "partially_paid". | `dashboard_screen.dart` | [Code] |
| F38 | The design-system migration is half done. Sheets and dialogs still use radius 24–28, w800/w900 weights and slate colours, against DESIGN.md. | `app_dialog.dart`, onboarding, sheets | [Code] |
| F39 | Light theme only. No dark mode. | `main.dart` | [Code] |
| F40 | `READ_MEDIA_IMAGES` is declared, which is a Play photo-policy risk (the photo picker needs no permission). An AdMob `APPLICATION_ID` meta-data entry remains with no ads SDK. | `android/app/src/main/AndroidManifest.xml` | [Code] |
| F41 | `BillingService.setProForTesting` is public in release builds. | `billing_service.dart:104` | [Code] |
| F42 | `copyWith` cannot clear nullable fields (due date, notes, client email). | `invoice_model.dart`, `estimate_model.dart` | [Code] |
| F43 | The PDF has no thousands separators (`toStringAsFixed`), no page numbers, and no amount in words. | `pdf_generator_service.dart:1241–1344` | [Code] |
| F44 | N+1 queries: every reload, including every tab tap, queries each invoice's line items separately. There is no pagination. | `dashboard_screen.dart`; `invoice_history_screen.dart` | [Code] |
| F45 | The README contradicts the product (pricing, ads, invoice limits). | `README.md` | [Code] |
| F46 | Invoice History duplicates the Invoices tab with a different card design. | Settings → Invoice History | [Code] |
| F67 | Estimates: invoices converted from an estimate inherit its default note ("valid for 30 days"); renaming the client keeps the previous client's address, phone and email; Preview PDF opens an unsaved estimate when validation fails, and Convert then creates a real invoice from it. | `estimate_model.dart:318`; `create_estimate_screen.dart:339, 863` | [Code, sweep] |
| F68 | Client sheet: sums invoices in different currencies under the default currency's symbol; finds invoices by name or email, not `client_id` (which is written but never read); counts an overdue invoice's full total as due even after a part-payment. The Clients tab also does not reload after a client is added from the Select Client picker. | `client_list_screen.dart:515–545, 661`; `main.dart:320–322` | [Code, sweep] |
| F69 | Every status change in History and every edit in Items swaps the list for a full-screen spinner, so the user is thrown back to the top. | `invoice_history_screen.dart:59, 656–661`; `item_list_screen.dart:47` | [Code, sweep] |
| F70 | Items: removing the selected category leaves an empty list with no reset; no field validation (a negative price throws inside build); the description is collected but never used on documents; the picker shows prices in the app's default currency, not the invoice's; picked items are added alphabetically, not in tap order; sorting is case-sensitive; the category field adds a listener on every rebuild. | `item_list_screen.dart:248`; `create_edit_item_sheet.dart:194, 414`; `item_picker_sheet.dart:89, 97, 107`; `item_service.dart:11` | [Code, sweep] |
| F71 | PDF: the discount percentage is rounded to a whole number (2.5% prints as 3%), and the line-item table header does not repeat on page 2 and later. | `pdf_generator_service.dart:1219, 1320` | [Code, sweep] |
| F72 | Design studio: tapping a template keeps the old header layout; the live preview can show a stale render; the custom footer field sits under the keyboard; Settings' "Set as default style" checkbox does nothing; studio previews use sample data, so the user's own settings are not shown. | `invoice_customizer_studio_sheet.dart:114, 162, 586`; `settings_screen.dart:489–501`; `estimate_preview_screen.dart:134` | [Code, sweep] |
| F73 | Record Payment replaces the total paid instead of adding a payment (no payment history), and its amount field mangles pasted or comma-decimal amounts. Supports G8 and O1. | `shared_widgets/app_dialog.dart:302–304, 486, 553` | [Code, sweep] |
| F74 | Business Profile: Back discards unsaved edits with no prompt, and its currency pill silently changes the app-wide default. Signature pad snackbars appear behind the sheet. The drawn signature is exported as the whole blank canvas, so it prints small. The editors' currency picker ticks the app default, not the document currency. The readiness meter shows 44/54/64% for 45/55/65%. | `business_profile_screen.dart:454–518, 532, 785`; `signature_pad_sheet.dart:88, 120, 143`; `currency_picker_sheet.dart:56, 181` | [Code, sweep] |
| F75 | Housekeeping: a custom default tax rate survives a currency change; the v3 migration back-fills `paid_amount` with 0, so the fallback for older Paid invoices never runs; notes deliberately cleared come back as "Thanks for your business."; the update sheet returns on every cold start and shows the internal versionCode; the History status pill is about 20 dp tall; `_PdfRasterViewer` is dead code; the client sheet never disposes its 5 controllers. | `currency_provider.dart:86`; `db_provider.dart:220`; `create_invoice_screen.dart:175`; `main.dart:682`; `invoice_history_screen.dart:1009–1030, 1116`; `client_list_screen.dart:80–84` | [Code, sweep] |

---

## 3. Tier 2: Gaps (what the market asks for that the app lacks)

Ranked by how often and how strongly reviews ask for it, and by fit with the recommended India-first, offline, one-time position. "Signal" is a judgement (strong, medium or weak) from the review samples and listings named in each row. It is not a tally.

| Rank | Gap | Who has it | Signal | Why it matters | Recommendation |
|---|---|---|---|---|---|
| G1 | **A real backup and restore** (one file, plus optional automatic backup to the user's own Google Drive) | Vyapar (user-managed), Zoho, Swipe and myBillBook (cloud) | Strong. Lost-data and server-outage complaints are the angriest reviews (Bookipi, Vyapar, Invoice Simple drafts). | An offline app's single biggest fear is phone loss. This is the price of admission for an offline-first position. | Build in O5. Make it free: it is a trust feature, not an upsell. |
| G2 | **Getting paid: a UPI QR code and link on the PDF and in the share message** | Refrens, Swipe and Zoho (payment links); myBillBook (UPI QR) | Strong. Asked for (Invoice Simple: payment links, tips). Praised when present (Refrens). Feared when wrong (Invoice Simple's wrong-amount link). | "Get paid faster" is the job users hire an invoice app for. A UPI QR needs no server, just the `upi://pay?pa=&pn=&am=&tn=` URI from data the app already stores (`biz_upi`). | Free. Print a QR code with the exact balance. Test that it never splits the page (an Invoice Simple complaint). |
| G3 | **WhatsApp-first sharing** with an editable message template that includes the amount, due date and UPI link | Refrens, Swipe, myBillBook, Vyapar | Strong (Indian listings). Marketed by most Indian apps. | The current share text is just "Invoice X for Y". | A per-document-type template with placeholders. One-tap WhatsApp share. |
| G4 | **GST-correct documents**: HSN/SAC per line, per-line tax, place of supply, state codes with automatic CGST+SGST vs IGST, amount in words, reverse charge (RCM) | Vyapar, myBillBook, Swipe, Zoho | Strong (Indian listings and reviews). RCM and HSN are asked for in reviews. | Without these, invoices from this app may not be valid GST tax invoices. That is a structural blocker for the target market. | Overhaul O3. |
| G5 | **Payment reminders and real overdue status**: local notifications, plus a "remind on WhatsApp" with a template | Zoho, Swipe, Invoice Simple, Wave, Joist | Strong | The onboarding already promises this. | Local scheduled notifications plus a remind-via-WhatsApp template. No server needed. |
| G6 | **Reports**: sales by period, outstanding by client (party statement or ledger), tax summary for GSTR-1 | All Indian apps. QuickBooks (free tier: top 3 reports). | Medium. Indian reviews ask for date-range reports and party statements specifically. | This is what an accountant asks for at month end. | A good candidate for Pro value (O2). |
| G7 | **Recurring invoices** | Invoice Simple (asked), Wave, Zoho, FreshBooks | Medium | Retainers, rent, tuition. | Local schedule plus a "due today" notification that creates a draft. |
| G8 | **Credit notes, payment receipts and a payments ledger** (record several payments with date and method) | Vyapar, myBillBook, Zoho | Medium. Split payments are asked for in Indian reviews. | Today there is one `paid_amount` number, with no history of payments. | Part of O1 (a `payments` table). |
| G9 | **Regional languages** (Hindi first; then Gujarati, Tamil, Marathi, Bengali) for both the UI and the PDF labels | myBillBook, Vyapar | Medium (myBillBook, Vyapar listings). | Reaches the next 100M small merchants. Needs F25 (fonts). | Start with Hindi UI plus bilingual PDF labels. |
| G10 | **Thermal and A5/A6 printing** | Vyapar, myBillBook (asked for in reviews) | Weak | Retail counters. | Later. Only if retail is a target. |
| G11 | **Draft autosave** | Invoice Simple (a complaint when missing) | Weak in count, very strong in tone | See F30. | Part of O6. |
| G12 | **App lock** (biometric/PIN) | Vyapar, myBillBook | Low in reviews, high in expectation for finance apps | Business data on a shared phone. | `local_auth`, off by default. |
| G13 | **Import clients from contacts or CSV, and export CSV for the accountant** | Most | Medium | Moving off spreadsheets or a competitor. | CSV both ways. |
| G14 | **Item reordering, line photos, customer signature on estimates** | Invoice Simple (asked); Joist (photos and signatures are core for contractors) | Weak | Trades and contractors. | Reordering is cheap; do it now. Signatures and photos later. |
| G15 | **Dark mode, accessibility, text scaling** | Most big apps | Low in reviews | Hygiene. | See O7. |

**Deliberately not recommended:**

- **E-invoicing (IRN) and e-way bills.** These are mandatory only above ₹5 crore turnover, which is outside the target user, and they need a GSP integration and a server.
- **Full accounting or inventory.** Vyapar owns this, and it contradicts "simple".
- **AI voice-to-invoice.** It is a trend (Joist and others ship it), but it needs a server and a model, and it does not fix trust. Revisit after O1–O5.

**[Inference]**

---

## 4. Tier 3: Things that need a complete overhaul

### O1: The document data model (the ledger)

**Problem.** Theses 2 and 4, plus F1, F3, F4, F5, F8, F9, F11 and G8. Patching each one leaves the same fragile structure.

**Target model.**

- **`documents`**: one table for invoices, estimates, credit notes and receipts, with a `type` column. The invoice and estimate code paths duplicate roughly 1,400 lines today (`create_estimate_screen.dart` mirrors `create_invoice_screen.dart`).
- **`number_series`**: per type and per financial year, with a prefix such as `INV/2026-27/`, allocated in a transaction. Indian GST invoices typically restart each financial year.
- **Money as integer minor units** (paise or cents). Totals come from one pure `DocumentTotals` function that is unit- and golden-tested. The editor, list, PDF and reports all use it.
- **`line_items`** gains `hsn_sac`, `unit`, `tax_rate`, `discount` and `sort_order` (already present).
- **`payments`**: date, amount, method and note, many per document. Status is **derived** (draft → issued → partially paid → paid; overdue is computed; void), not typed by the user.
- **A snapshot at issue**: issuer JSON (profile plus logo hash), client JSON, and design config JSON are stored on the document row. After issue, editing creates a revision or a credit note; it never mutates silently.
- **Foreign keys on**, transactions everywhere, and migrations with tests from v1 through v5.
- **Move per-document state out of SharedPreferences** (`invoice_customization_*`, `invoice_theme_*`, `estimate_*`, `invoice_sent_*`) into the database.

### O2: Monetization and entitlements

**Problem.** Thesis 3, plus F6, F16, F17 and F23.

**Recommendation** **[Inference; price-test it]**:

- **Free**: unlimited invoices and estimates, all themes, the logo, UPI QR, backup and restore, and a small "Made with Invoice Maker Pro" footer. Free should be good enough to recommend. Zoho Invoice's free plan, with its "powered by" branding, is the pattern reviewers accept.
- **Pro (one-time, lifetime)**: no footer, reports and GSTR-1 summary, recurring invoices, automatic reminders, automatic Drive backup, multiple businesses, and app lock. These are value features, not identity features.
- **Monthly**: drop it, or keep only a yearly plan as a cheaper entry point with a clear promise that the price is locked for existing subscribers. The reviews show that monthly invoice-app subscriptions breed the cancellation and double-charge complaints that dominate 1-star reviews.
- **Never** gate the logo, client count or invoice count. Every competitor that did so, or later tightened it, collected backlash (Joist, Invoice Simple, Bookipi, Moon). **[Review]**
- **Engineering**: one `EntitlementService` (all product IDs, a lifetime listener, always acknowledge, revoke when a restore returns nothing); local prices only from `ProductDetails` (show a loading state, never a hard-coded ₹ amount); a restore-purchases button; and Terms, Privacy and renewal disclosure.
- **Sequencing.** Do not free the caps and gates (phase 2) before at least one Pro value feature ships. Either ship one of reports, reminders or recurring invoices together with the new tiers, or keep the current monthly cap until then. Otherwise revenue drops with nothing to replace it.

### O3: The jurisdiction and tax model (India first)

**Problem.** Thesis 4, plus G4.

**Target.**

- **The business** has a country, a tax regime, a state (India), a GSTIN (validated with its checksum and checked against the state code), and labels.
- **The client** has a state (place of supply), a GSTIN, and billing and shipping addresses.
- **Tax type is chosen automatically**: same state → CGST + SGST; different state → IGST; export → zero-rated with an LUT note; RCM flag available.
- **Currency** belongs to the document only. Labels come from the issuer's regime, not the currency.
- **The PDF** shows a GST summary table by HSN and rate, the amount in words (Indian numbering: lakh, crore), the place of supply, and the reverse-charge line.
- **Defaults come from the device locale** (en_IN → INR, India GST), not `SupportedCurrencies.all.first`.
- **Outside India**: "Simple tax" mode, which is honest about what it is. Per-region VAT rates replace the single EU 20% entry.

### O4: Onboarding

**Problem.** Seven pages, two of which collect data that is never used. It makes three false promises, has a paywall inside it, shows arithmetic that is wrong, and its last CTA probably does not do what it says (F13).

**Target: three steps, about 60 seconds.**

1. **"Where's your business?"** Country, then state. The currency and tax regime follow from the answer; the user can change them.
2. **"How should your invoice look?"** Business name, logo (free), and GSTIN (optional, validated). Show a live preview using their own name, never "Acme Studio".
3. **"Your first invoice"** goes straight into the editor, with a sample client the user can delete.

Keep the haptic feel and remove the unused `_animCtrl`. Track the time to the first shared invoice: that is the activation metric. Make "Help & Guide" a separate, read-only tips screen.

### O5: Backup, restore and portability

- **One `.imp` archive** (zip) containing the SQLite file (or a JSON dump), the preferences as JSON, the logo and signature images, and a manifest with the schema version.
- **Restore** with a preview ("17 invoices, 9 clients, from 12 Oct 2026"), a choice of merge or replace, and a schema migration on import.
- **Optional automatic backup** to the user's own Google Drive app folder (`drive.appdata` scope). There is no server of yours, which matches the offline and privacy promise.
- **CSV export** of invoices, items, clients and payments for the accountant.
- **A restore test in CI**: export, wipe, restore, then diff.

### O6: The editor (Create Invoice, 2,689 lines, plus Create Estimate, 1,432 lines)

**Problem.** One large `StatefulWidget` per document type. State lives in about 60 fields and controllers, with no model and no autosave. Some UI controls persist nothing.

**Target.**

- One `DocumentEditor` that works for every document type.
- A `DocumentDraft` immutable state object with a controller (provider or `ValueNotifier`), plus an autosave of drafts to the database every few seconds.
- Section widgets in separate files: Header, Parties, Items, Totals, Payments, Notes and Terms, Design.
- Remove controls that do nothing (attachments and payment method) until they are real.
- Item reordering by drag.
- A sticky total bar showing Subtotal, Tax and Total, which the user can tap to expand.

### O7: Design system, accessibility and motion

- Finish the Cal.com-style migration: one radius scale, one weight scale, no slate leftovers. Make sheets and dialogs consistent.
- Add dark mode (tokens already exist in `app_colors.dart`, so extend them).
- Add `Semantics` labels on every icon-only control, support dynamic text scaling up to 1.3× without overflow, and check contrast.
- **Motion rules:**
  - cap the stagger at the first 8 rows and play it once per screen load;
  - honour `disableAnimations`;
  - use one shared page transition (use or delete `slideUpRoute`);
  - give haptics a purpose (commit actions only) and a setting to turn them off.

---

## 5. Recommended positioning

**"The GST invoice app that respects you: works offline, your data stays on your phone (and your own Drive), and you pay once."**

| Pillar | What it means | What it beats (review evidence) |
|---|---|---|
| Correct | GST-valid documents. Numbers that never collide. Totals that add up. | Wrong amounts (Invoice Simple), breaking updates (Invoice2go, Bookipi) |
| Yours | Offline. Full backup and restore. Your own Drive. No account required. | Server outages (Bookipi), lost data (Vyapar backup), lock-in |
| Fair | Generous free tier, one-time Pro, no surprise paywalls. | Price hikes (Invoice Simple, Invoice2go, myBillBook renewals), features moved behind the paywall (Joist, Moon), support upsell calls (Vyapar) |
| Gets you paid | UPI QR, WhatsApp share with the amount and link, reminders. | Refrens and Swipe praise. The core job. |

**Who it is for:** Indian freelancers, consultants, agencies, tutors and small service businesses (1–50 invoices a month) who find Vyapar and myBillBook too heavy (inventory, accounting, sales calls) and Zoho too corporate.

**Who it is not for:** retail counters with inventory and thermal printers (Vyapar's home turf), or companies above ₹5 crore that need e-invoicing.

**[Inference]**

---

## 6. Suggested sequence

| Phase | Scope | Exit criteria |
|---|---|---|
| 1. Stop the bleeding (1 release) | Guards and one-line fixes only: F47 (estimate parser — the Estimates tab is unusable), F48 (startup cleanup deletes bank details — ship first), F49 (fresh line IDs on conversion), F50 and F51 (decimal pre-fill), F1 (abort-on-conflict numbering and MAX-based numbers), F2 (logo guard), F3 (PDF tax from one totals function), F4 (labelled shipping), F6 (acknowledge every product ID, including legacy), F7 (qty formatting), F12 (save 0% tax), F18 (duplicate as unpaid draft), F11 transactions only (foreign keys wait for the SET NULL migration). Rename "Backup" to "Export". Remove the false paywall claims. | New tests: load an estimate from the database; startup keeps a profile that matches a demo value; convert an estimate twice; re-save a 2.5% estimate; numbering after deleting a middle invoice; PDF totals with discount + shipping; monthly and legacy purchases flip the UI; duplicate starts unpaid. |
| 2. Keep every promise (1–2 releases) | F13–F17, F19–F30, F52–F66, O4 onboarding, O2 entitlement service and new tiers, O5 backup and restore. | Every claim on onboarding, the paywall, the README and the store listing maps to code. Restore round-trip test in CI. |
| 3. Become the record (larger) | O1 data model, with migration of existing users: it absorbs F5 (per-line tax), F8 (issuer snapshot), F9 (design in the database) and enabling foreign keys. O6 editor. | Issued documents are immutable; re-rendering gives the same bytes. |
| 4. Win India | O3 GST model, G2 UPI QR, G3 WhatsApp templates, G5 reminders, G6 reports, G9 Hindi. | A GST-valid tax invoice, checked against a CA's checklist. |
| 5. Polish | F31–F46, F67–F75, O7, G7, G8, G12–G15. | Accessibility scan passes. Dark mode. |

---

## Appendix A: Competitor evidence

### Data sources

- **Play data** comes from the public listing pages (en_IN storefront unless marked), fetched on 2026-11-19.
- **Play Store review samples** use Google's "most relevant" sort. That sort favours long reviews at both rating extremes, so frequencies are directional, not statistical.
- Reviews are paraphrased here. None is quoted.

### The apps

| # | App (package) | Rating / ratings | Installs | Review sample I read | Dates | Top themes (paraphrased) |
|---|---|---|---|---|---|---|
| 1 | Vyapar (`in.android.vyapar`) | 4.82 / ~200K | 10M+ | ~20 Play | 2025–26 | Praise for breadth. Support is slow, with upsell calls. Backup is the user's job. Asks: date-range reports, thermal printing, e-way bill on mobile. |
| 2 | myBillBook (`com.valorem.flobooks`) | 4.73 / ~150K | 10M+ | ~20 Play | 2025–26 | Renewal prices 5–6× the first year. Support unreachable. Praise for regional languages. Asks: split payments, party statements, RCM. |
| 3 | Swipe (`in.swipe.app`) | 4.71 / ~15.7K | 1M+ | ~20 Play | 2025–26 | Fast and simple. Annoyance at per-feature charges. WhatsApp sharing praised. |
| 4 | Zoho Invoice (`com.zoho.invoice`) | 4.76 / ~33K | 1M+ | ~20 Play | 2025–26 | Free with "powered by" branding, accepted. 500 invoices a year limit. Praise for polish. Some sync complaints. |
| 5 | Refrens (`com.refrens.RefrensApp`) | 4.64 / ~3.6K | 100K+ | ~20 Play | 2025–26 | Free payment links and WhatsApp share praised. Some complaints that it is web-first. |
| 6 | Invoice Simple (`com.aadhk.woinvoice`) | 4.78 / ~173K | ~7.6M (AppGoblin) | **120 Play** (read in-browser) | mostly 2026 | Strong anger at price hikes (monthly roughly tripled, yearly up about 5×, free cap cut 10 → 3). Double charges and charges after cancelling. Support is an AI chatbot only. Drafts erased on leaving. Sending fails after a few emails. Wrong payment-link amount. QR code splits onto a second page. Asks: per-invoice currency, recurring invoices, tips, item reordering, customer signatures. Praise: simplicity, read receipts, PDF quality. |
| 7 | Invoice2go (`com.invoice2go.invoice2goplus`) | 4.48 | ~3.5M (AppGoblin) | 20 Play | 2018–22 (old) | Price jump from about $99 to about $400 a year. Updates broke workflows. |
| 8 | Bookipi (`bookipi.invoice.maker.estimate.billing`) | n/a | ~1.7M (AppGoblin) | 20 Play | 2025–26 | Free access removed suddenly. About two months of server errors. Slow. Updates broke workflow. |
| 9 | SpeedInvoice (`au.com.speedinvoice.android`) | n/a | ~1.6M (AppGoblin) | 20 Play | mixed | Mostly positive. Locked out of your own invoices after the trial. Asks: delete saved items, attach files. |
| 10 | Moon Invoice (`com.moontechnolabs.miandroid`) | n/a | ~185K (AppGoblin) | 20 Play | mostly 2019 (old) | "Free" was really a trial. One-time buyers pushed to a subscription. **A direct warning about the lifetime → monthly move.** |
| 11 | Wave (`com.waveapps.sales`) | 3.3 / ~23.6K | 500K+ | 20 Play | mostly 2019 (old) | Cannot delete things. Slow loading. Payment holds. Labels cannot be translated. Rating drop linked to the 2024 paywall split (secondary source). |
| 12 | Joist (`com.joistapp.android.joist`) | 4.59 / ~13.6K | 1M+ | 20 Play | mostly 2019 (old) | Backlash when the logo and other free features moved behind a paywall. |
| 13 | QuickBooks (`com.intuit.quickbooks`) | 4.69 / ~90.7K | 5M+ | none on Play (iOS / Capterra summaries via research agent) | 2025–26 | Renewal hikes. Complexity. Free tier: 2 invoices a month. |
| 14 | FreshBooks (`com.freshbooks.andromeda`) | 4.13 / ~6K | 1M+ | none on Play (iOS / Capterra summaries via research agent) | 2025–26 | Client caps force upgrades. Reports are desktop-only. |

Directly sampled on Play: 12 apps, about 340 reviews in total. Rows 13–14 are context only.

### Category patterns (abstract)

1. **Trust is the product.** The 1-star reviews are about money and data (price changes, charges, lost drafts, outages), not features. Features show up in 3- and 4-star "please add" reviews.
2. **The ratings are inflated, and the pain is concentrated.** 4.7–4.8 averages hide clusters of very angry long reviews. Those are the ones prospective users read, because "most relevant" puts them first.
3. **Incumbents cannot be beaten on features, only on business model.** Vyapar and myBillBook have years of features. Their weakness is renewal hikes, upsell calls and cloud lock-in.
4. **India's job is "get paid on WhatsApp via UPI".** The West's job is "send by email, get paid by card". The app's share text and missing UPI QR show it is not yet built for the Indian job.
5. **Every surprise paywall is remembered for years.** The Joist and Moon reviews from 2019 still sit on top of their listings.

---

## Appendix B: Animation and motion inventory

| Where | What | Timing / curve | Notes |
|---|---|---|---|
| `main.dart` bottom navigation | Floating pill with `BackdropFilter` blur 20, height 66, opacity 0.90. Selected tab is an `AnimatedContainer`. The centre "+" is a 44 px black button. | 180 ms, `easeOutCubic` | Light haptic on tab tap; medium haptic on "+". Every tab tap reloads that screen's data (see F44). |
| "+" sheet | "Create New Document": New Invoice / New Estimate (Quote) | Material default sheet | — |
| Startup update sheet | Shows "Available version #code" (raw build number) | default | Should show the version name or "What's new". |
| `AppAnimations` constants | fast 180 ms, medium 300 ms, slow 450 ms, bounce `elasticOut` | — | — |
| `StaggeredEntrance` | Fade 0 → 1 plus slide 12% up | 350 ms, `easeOut` / `easeOutCubic`, delay `index × 50 ms` | Used in Clients, Estimates, Items, Invoice History. No delay cap, and it replays when rows rebuild (F33). |
| `AppAnimations.slideUpRoute` | 8% slide plus fade route | — | Unused (F34). |
| Onboarding `PageView` | 7 pages, step indicator, back button | `AnimatedContainer` ×6, `AnimatedScale` ×2 | 15 light, 1 medium and 1 selection haptic. |
| Onboarding welcome | A fake invoice assembles line by line | Every 450 ms, with a haptic per step | Its arithmetic is wrong (F28). `_animCtrl` (2,400 ms) is unused. |
| Onboarding cards | Selected card scales and recolours | `AnimatedScale` / `AnimatedContainer` | — |
| `PrimaryButton` | Press-scale feedback | `AnimatedScale` | Light haptic ×2. |
| Paywall | Fade-in of content; skyline `CustomPainter` header (static, `shouldRepaint` false) | 500 ms `AnimationController` | `AnimatedContainer` for plan selection. |
| Invoice Preview | PDF rasterised at 220 dpi into page images; double-tap zoom to 2.5×; collapsible bottom action panel | Panel 260 ms, `easeInOutCubic` | The PDF is regenerated and rasterised on every status change, which is heavy on low-end phones. |
| Dashboard filter pills | Selected pill fill | `AnimatedContainer` | 3 light and 1 medium haptic. |
| Estimates, Items, Item picker, Customizer, Theme picker, `AppDialog` | Selection-state `AnimatedContainer` | ~150–300 ms | — |
| Invoice History | Header `PageView`; card press | 150 ms | — |
| Signature pad | Stroke drawing; clear and save | — | Haptics: light, medium, selection ×2. |
| Business profile | Strength meter; image pick | — | Haptics: light ×4, medium, `vibrate` (heavy, on error). |
| Coachmarks (Create Invoice) | "Step x of 4", one at a time | — | Dismissal stored in `dismissed_invoice_tips`. |

**Missing across the app:** reduce-motion support, `Hero` transitions (FABs only have hero tags to avoid collisions), skeleton loading states (spinners are used), success feedback after save or share other than snackbars, and a haptics on/off setting.

---

## Appendix C: Settings and preferences inventory

### Settings screen (top to bottom)

| Section | Items |
|---|---|
| Pro card | Upsell banner (hidden for Pro) |
| Workspace | Business Profile → `BusinessProfileScreen`. Invoice History → `InvoiceHistoryScreen` (duplicates the Invoices tab). |
| Data & Backup | Export Data (JSON). There is no import (F10). |
| Preferences | Default Currency (currency picker sheet, 37 currencies). Default Tax Rate (chips plus a 0–100 field). Default Design → Customizer Studio. |
| About | Rate Us (in-app review). Help & Guide → re-runs onboarding (F14). |

**Missing from Settings:** Privacy policy, Terms, contact support, app version, restore purchases, numbering prefix and next number, default payment terms (set only in onboarding), default notes and terms, reminders, language, dark mode, haptics, app lock, delete all data.

### Business Profile fields

- **Identity:** name, tagline\*, address, phone, email, website\*, GSTIN
- **Bank:** bank name, account number, IFSC, UPI ID
- **Other:** notes\*, logo (camera or gallery), signature (draw or gallery)
- **Profile strength meter**

\* saved but never printed or used (F36). There is no state, PAN, or GSTIN validation.

### Customizer Studio (all free)

- **10 themes:** Classic Corporate, Modern Minimal, Emerald Executive, Slate Elegance, Warm Corporate, Nordic Frame, Left Accent Ribbon, Geometric Banner, Security Grid, Two-Tone Split.
- **4 fonts** (downloaded at runtime; see F26).
- **Layout:** density, header position, and address layout.
- **Toggles:** bank details, UPI, signature, notes, qty column, unit price column, custom footer.
- **Scope:** "Set as default" or this document only.

This is the app's most differentiated surface.

### SharedPreferences keys

| Key | Written by | Read by | Notes |
|---|---|---|---|
| `onboarding_complete` | onboarding | `AppStartup` | — |
| `user_currency` | onboarding, settings | everywhere | Default USD if unset. |
| `custom_default_tax_rate` | onboarding (only if > 0), settings | create screens | F12 |
| `default_payment_terms` | onboarding | profile notes fallback only | Not used for the due date (F15). |
| `business_type`, `onboarding_goal` | onboarding | **nobody** | F36 |
| `biz_name`, `biz_address`, `biz_phone`, `biz_email`, `biz_gstin` | profile, onboarding | PDF render (live) | F8: not snapshotted |
| `biz_bank_name`, `biz_account`, `biz_ifsc`, `biz_upi` | profile | PDF render (live) | Not in backup (F10) |
| `biz_tagline`, `biz_website`, `biz_notes` | profile | nobody (notes as fallback only) | F36 |
| `biz_logo_path`, `biz_signature_path` | profile, create invoice | PDF | Cache paths (F24). Not in backup. |
| `default_pdf_theme`, `default_invoice_customization` | settings, theme picker, studio | create and preview | — |
| `invoice_theme_<id>`, `invoice_customization_<id>` | preview studio, estimate conversion | preview only (not list share: F9) | Never deleted with the invoice. Not in backup. |
| `estimate_theme_<id>`, `estimate_customization_<id>` | estimate preview | estimate preview, conversion | Same issues |
| `invoice_sent_<id>` | preview (on share) | preview | F19 |
| `is_premium_user` | `BillingService` **and** `AdManager` | both | Two sources of truth (F6) |
| `dismissed_invoice_tips` | coachmarks | create invoice | — |
| `app_review_first_seen_ms`, `app_review_last_prompt_ms`, `app_review_significant_action_count` | `AppReviewService` | same | Prompts after 3 share/save actions, 3 days after install, with a 120-day cooldown. Sensible. |

### Database (schema version 4)

| Table | Contents |
|---|---|
| `clients` | id, name, email, phone, address, gstin, created_at |
| `invoices` | Includes a client snapshot (good), sgst/cgst/igst rates, discount, paid_amount, status, currency (default INR) |
| `line_items` | id, invoice_id, description, quantity, unit_price, total, sort_order (no tax, HSN or unit) |
| `estimates`, `estimate_line_items` | Mirrors of the invoice tables |
| `saved_items` | unit, hsn_code, category, is_taxable, tax_rate, discount_rate, default_quantity (richer than `line_items`, so the data is lost on use: F5) |

### Free-tier limits in code

| Limit | Where |
|---|---|
| 10 invoices a month | `create_invoice_screen.dart:40` |
| 10 estimates a month | `create_estimate_screen.dart:31` |
| 5 clients | `client_list_screen.dart:71` |
| Invoice History shows only the first 5 invoices (after search and filter) | `invoice_history_screen.dart:518–523` (F58) |
| Not gated (holes in the monthly cap) | Duplicate (F18), New Invoice from the client sheet, estimate conversion (F57) |
| Watermark "Generated by Invoice Maker Pro" | PDF |
| Logo gated in onboarding only | F17 |

---

## Appendix D: Coverage and limits

| Area | Depth |
|---|---|
| `main.dart`, `db_provider.dart`, billing, ads, paywall, currency provider and models, formatter, typography, animations, onboarding, dashboard, create invoice, preview, PDF generator, settings, business profile, item picker | Read in full or in large part |
| Invoice History, estimates (list, create, preview), clients, items list and create sheet, customizer studio, theme picker, customization config, signature pad, paywall header, shared widgets, review and update services | Read by me in targeted passes, then line by line by the six sweep agents (F47–F75) |
| Runtime behaviour | **Not run on a device in this audit** (only the unit probe above). F13's exact outcome and the visual issues need a device check. |
| Tests | `flutter analyze` is clean, and 79 of 79 tests pass. None covers numbering, totals, PDF numbers or migrations. |
| Competitor reviews | Small, "most relevant" samples (~20 per app; 120 for Invoice Simple). Several Western samples are from 2019–22 and are marked old. QuickBooks and FreshBooks have no Play samples. Pricing figures from third parties are unverified. |
| Competitor apps | Assessed from listings, descriptions and reviews. Not installed or used. |

**Verification sweep.** After the first draft, a workflow ran six independent finder agents over the areas this audit had read only in targeted passes (estimates, history and clients, items, the design studio, profile and signature and shared widgets, core money models and migrations). A separate skeptic agent per area then tried to refute each finding against the source. Of 64 findings, 60 were confirmed and 4 were rejected (one duplicate of F7, one intended behaviour, one unreachable setState-after-dispose path, one speculative performance claim). After merging duplicates they became F47–F75. I re-traced the three most severe myself (F47, F48, F51) and proved F47, F50 and F51 by running a throwaway unit probe: an `estimate_line_items` row makes `LineItemModel.fromMap` throw a `TypeError`; `1.05` and `10.05` become "15" and "105"; `2.5.toStringAsFixed(0)` is "3". The probe file was deleted afterwards. The F47 cast dates from the first commit, so it is not a recent regression. That the Estimates screen then hangs is read from the code (no try/finally around the load), not seen on a device.

**How the work was split.** Indian, global and SMB competitor research was gathered by three research subagents and cross-checked. I read Play Store reviews for Invoice Simple, Invoice2go, Bookipi, SpeedInvoice, Wave, Joist and Moon directly in the browser. Code findings F1–F46 were traced by me. F47–F75 come from the verification sweep above. One delegated code-extraction run failed on a quota limit, and nothing from it is used here. A second-opinion reviewer (a separate model, read-only) re-checked the P0 and P1 code claims against the source. It found none wrong. It corrected the mechanism of F4, added the legacy-ID gap to F6, the missing-logo-file path to F2, and the client foreign-key trap to F11. It moved F12 and F18 to P0, reworded F13 as a race, narrowed Phase 1, and supplied the counter-argument to Thesis 3. I verified each correction in the source before applying it.
