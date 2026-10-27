# 💌 Urgent Romantic Date Invitation (Flutter Web)

🔗 **Live on GitHub Pages:** [https://alexbejann.github.io/date-antigravity-app/](https://alexbejann.github.io/date-antigravity-app/)

A funny, romantic, multi-step Flutter web application designed to invite your girlfriend on a date—complete with an impossible-to-click runaway **"No"** button, rigged date & restaurant selection that playfully steers her to **Saturday at 17:45** at **[Lestari Indonesisch Restaurant 🇮🇩](https://maps.app.goo.gl/5w67QseydzxbkMb66)**,confetti heart bursts, and a downloadable **VIP Romantic Boarding Pass / Date Ticket** at the end.

---

## ✨ Features

1. **Step 1 — The Big Question (`💌 The Question`)**
   - Pulsing love-letter badge and romantic background with floating hearts & sparkles.
   - **Runaway & Shrinking "No" Button**: Evades the cursor on hover and tap, cycles through hilarious pleading error messages from JSON, and makes the **"YES, Obviously! 💖"** button grow larger with every refusal attempt.
   - **"Report a Bug" System Diagnostics**: A playful modal that informs her the `"No"` button is broken on purpose and diagnoses `1,000,000%` obsession.
2. **Step 2 — Pick a Date & Time (`📅 Pick Time`)**
   - Pre-selects **Saturday @ 17:45** (`🌟 DESTINY'S PICK`).
   - Trying to click any other decoy date triggers a funny schedule override excuse from `assets/date_options.json` and snaps the selection right back to **Saturday @ 17:45**!
3. **Step 3 — Pick a Restaurant & Princess Perks (`🇮🇩 Pick Feast`)**
   - Pre-selects **Lestari Indonesisch Restaurant 🇮🇩** (`Nieuwstraat 50, 6811 HX Arnhem`) with a direct link to [Google Maps](https://maps.app.goo.gl/5w67QseydzxbkMb66).
   - Trying to pick any decoy restaurant triggers a hilarious kitchen/boyfriend veto excuse and snaps right back to **Lestari**!
   - Includes a rigged **"I Can't Decide, Pick For Me! 🎲"** randomizer button that lands on **Lestari Indonesisch Restaurant** 100% of the time.
   - Selectable **VIP Princess Add-ons** (`extras` in JSON) with tooltips + custom special request text box.
4. **Step 4 — Official VIP Date Ticket (`🎟️ Date Ticket`)**
   - Celebratory confetti & heart shower overlay.
   - Perforated boarding-pass style Date Ticket with a custom barcode, Google Maps button, and stubbornness telemetry.
   - **One-Click Copy Receipt**: Copies a formatted confirmation text (including the Google Maps link) she can paste & send back to you.
   - **Download Calendar Invite (`.ics`)** for **Saturday at 17:45** & **Download Ticket (`.txt`)** directly in the browser.

---

## 🛠️ Customizing `assets/date_options.json`

Edit [`assets/date_options.json`](assets/date_options.json) to tweak names, messages, dates (`isDestined: true` marks the winning option), restaurants, and perks.
