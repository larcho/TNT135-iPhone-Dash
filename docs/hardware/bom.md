# Bill of materials

Status column: ✅ owned, 📦 ordered, 🛒 to buy, ❓ decide after the signal survey.

| # | Part | Qty | Status | AliExpress search terms / notes |
|---|---|---|---|---|
| 1 | Waveshare ESP32-P4-WIFI6-M (P4 + C6 co-processor) | 1 | 📦 | See `MATERIALS/ESP32-P4` |
| 2 | 12 V → 5 V automotive buck, 8–36 V in, ≥ 2 A, waterproof | 1 | 📦 | Fulree USB-C 5 V 3 A. Prefer a wide-input variant: 8–23 V is below a typical TVS clamp voltage. Other options: "12V to 5V 3A step down converter waterproof", "DC-DC buck 8-40V to 5V potted" |
| 3 | PC817 optocoupler isolation module, **12 V input**, 8 channels | 1 | 🛒 | "PC817 8 channel optocoupler isolation module 12V". Pick the 12 V input variant |
| 4 | Inline blade fuse holder + 2 A fuse | 2 | 📦 | One for the bridge, one for the Quad Lock head |
| 5 | TVS diode SMBJ20A (or similar) | 2 | ✅ | |
| 6 | Resistors: 100 k, 22 k, 1 k, fuel pull-up (value from survey) | — | 🛒 | Metal film, 1 % |
| 7 | Capacitors 100 nF | 4 | 🛒 | |
| 8 | 3.3 V zener | 1 | 🛒 | Battery-sense clamp |
| 9 | **Mating 18-pin connector** (see below) | 2–3 | 📦 | RiccoDi grey male PCB header |
| 10 | Protoboard or custom PCB carrier | 1 | 🛒 | Start on protoboard; move to a JLCPCB board once the design is settled |
| 11 | Quad Lock motorcycle mount + wireless charging head (12 V) + vibration dampener | 1 | ❓ | See [power.md](power.md) |
| 12 | Heat-shrink, 20–22 AWG automotive wire, adhesive-lined heat-shrink | — | 🛒 | |

## The 18-pin connector: how to get a plug-and-play harness

The goal is to **never cut the bike's harness**, so the stock dash can be refitted in
five minutes. The bike side is the female plug in `MATERIALS/original-unit/IMG_0612.jpeg`.
You need the **male, dash-side** part.

Options, best first:

1. **PCB-mount 18-pin header (like the one in `MATERIALS/18 Pin Automotive ACC`)**
   soldered onto the ESP32 carrier board. The candidate is the grey right-angle header
   (`18-pin-pcb-header-grey-riccodi.png`, sold by the RiccoDi store): 2 staggered rows
   of 9 through-hole pins, with three latch ribs on top. Watch out for three things:
   - **Housing colour can be keying.** Some connector families key black and grey versions
     differently. Confirm that the ribs and slots match the bike's black plug, or
     order the black version if the store has one.
   - **Pin pitch may not be 2.54 mm**, so it may not fit standard perfboard. Measure the
     tails when it arrives. If it doesn't fit, mount it on a small custom PCB, or
     solder short flying leads to the protoboard.
   - Order 2–3, because they're cheap and you'll want one for a bench test harness.

   The bike plug then mates directly with the bridge, with no pigtail needed. The bike plug then mates directly with
   the bridge, with no pigtail needed. Before ordering, check against the real plug:
   pin count (2 × 9?), **pitch** (measure with calipers across several pins), and the
   **locking latch/keying** position. Search terms: "18 pin automotive
   connector PCB instrument", "18P motorcycle meter socket", "18 pin dashboard
   connector male PCB".
2. **Buy a replacement TNT125/135 speedometer** (AliExpress sells them, for example
   ["Digital Speedometer Instrument for Benelli TNT125/135"](https://www.aliexpress.com/i/4001279181584.html))
   and desolder its connector. The fit is guaranteed. The spare dash also makes a
   **bench test rig**: you can feed it signals from the ESP32 and compare readings.
3. **Pre-made pigtail** ("18 pin female/male connector with wire harness"). Only
   worth it once you know the exact connector family. Look for a part number moulded
   into the harness plug and photograph its mating face. I can help identify it.

Until the connector arrives, you can do the signal survey and bench development
with back-probe pins and Dupont leads.
