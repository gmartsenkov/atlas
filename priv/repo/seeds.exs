alias Atlas.Repo

alias Atlas.Communities.{
  Collection,
  Community,
  CommunityMember,
  Page,
  PageComment,
  PageStar,
  Section
}

alias Atlas.Accounts.User

# Block builder helpers
t = fn text -> %{"type" => "text", "text" => text} end
b = fn text -> %{"type" => "text", "text" => text, "styles" => %{"bold" => true}} end
i = fn text -> %{"type" => "text", "text" => text, "styles" => %{"italic" => true}} end
code = fn text -> %{"type" => "text", "text" => text, "styles" => %{"code" => true}} end

h = fn level, text, id ->
  %{
    "id" => id,
    "type" => "heading",
    "props" => %{"level" => level},
    "content" => [t.(text)],
    "children" => []
  }
end

p = fn
  parts, id when is_list(parts) ->
    %{"id" => id, "type" => "paragraph", "content" => parts, "children" => []}

  text, id when is_binary(text) ->
    %{"id" => id, "type" => "paragraph", "content" => [t.(text)], "children" => []}
end

bullet = fn
  parts, id when is_list(parts) ->
    %{"id" => id, "type" => "bulletListItem", "content" => parts, "children" => []}

  text, id when is_binary(text) ->
    %{"id" => id, "type" => "bulletListItem", "content" => [t.(text)], "children" => []}
end

num = fn
  parts, id when is_list(parts) ->
    %{"id" => id, "type" => "numberedListItem", "content" => parts, "children" => []}

  text, id when is_binary(text) ->
    %{"id" => id, "type" => "numberedListItem", "content" => [t.(text)], "children" => []}
end

# --- Triumph Trident 660 ---
trident_content = [
  h.(1, "Triumph Trident 660", "t-h1"),
  p.(
    [
      t.("The Trident 660 is a "),
      b.("triple-cylinder"),
      t.(
        " middleweight naked motorcycle produced by Triumph Motorcycles. Launched in early 2021, it sits as the entry point to Triumph's roadster range, designed to be accessible for newer riders while still offering genuine Triumph character and performance."
      )
    ],
    "t-p1"
  ),
  p.(
    "With its distinctive design, punchy triple engine, and competitive price point, the Trident has quickly become one of the most popular middleweights on the market.",
    "t-p2"
  ),
  h.(2, "Engine & Performance", "t-h2"),
  p.(
    [
      t.("At the heart of the Trident sits a "),
      b.("660cc inline triple"),
      t.(" engine producing "),
      b.("81 PS (80 bhp)"),
      t.(" at 10,250 rpm and "),
      b.("64 Nm"),
      t.(
        " of torque at 6,250 rpm. The powerplant is derived from the Street Triple's motor but detuned for a smoother, more approachable power delivery."
      )
    ],
    "t-p3"
  ),
  bullet.([b.("Engine type: "), t.("Liquid-cooled, 12-valve, DOHC, inline 3-cylinder")], "t-b1"),
  bullet.([b.("Displacement: "), t.("660cc")], "t-b2"),
  bullet.([b.("Bore x Stroke: "), t.("74.04mm x 51.1mm")], "t-b3"),
  bullet.([b.("Compression ratio: "), t.("11.95:1")], "t-b4"),
  bullet.([b.("Fuel system: "), t.("Multipoint sequential electronic fuel injection")], "t-b5"),
  bullet.([b.("Transmission: "), t.("6-speed, slip & assist clutch")], "t-b6"),
  p.(
    "The triple engine character is what sets the Trident apart from its twin-cylinder competitors. You get a wider, more usable spread of torque with a distinctive exhaust note that sounds far more exotic than the typical parallel twin.",
    "t-p4"
  ),
  h.(2, "Chassis & Dimensions", "t-h3"),
  p.(
    "The Trident uses a tubular steel perimeter frame paired with a bolt-on aluminium rear subframe. Suspension comes from Showa: a 41mm upside-down fork up front and a monoshock at the rear, both offering preload adjustment.",
    "t-p5"
  ),
  bullet.([b.("Wet weight: "), t.("189 kg")], "t-b7"),
  bullet.([b.("Seat height: "), t.("805 mm")], "t-b8"),
  bullet.([b.("Wheelbase: "), t.("1,401 mm")], "t-b9"),
  bullet.([b.("Fuel capacity: "), t.("14 litres")], "t-b10"),
  bullet.(
    [b.("Front brake: "), t.("Twin 310mm discs, Nissin 2-piston sliding calipers")],
    "t-b11"
  ),
  bullet.(
    [b.("Rear brake: "), t.("Single 255mm disc, Nissin single-piston sliding caliper")],
    "t-b12"
  ),
  h.(2, "Electronics & Features", "t-h4"),
  p.(
    "Despite its position as an entry-level model, the Trident comes well-equipped with modern electronics:",
    "t-p6"
  ),
  bullet.("Ride-by-wire throttle with two riding modes (Road and Rain)", "t-b13"),
  bullet.("Switchable traction control", "t-b14"),
  bullet.("ABS (disengageable on rear)", "t-b15"),
  bullet.(
    [t.("Fully digital "), b.("TFT instrument cluster"), t.(" with Bluetooth connectivity")],
    "t-b16"
  ),
  bullet.("LED lighting throughout (headlight, indicators, tail light)", "t-b17"),
  bullet.("USB charging socket under the seat", "t-b18"),
  p.(
    [
      t.("The Triumph Connectivity system pairs with the "),
      b.("My Triumph"),
      t.(
        " app, allowing turn-by-turn navigation, phone notifications, and GoPro control directly on the TFT display."
      )
    ],
    "t-p7"
  ),
  h.(2, "Riding Experience", "t-h5"),
  p.(
    "The Trident is a genuinely fun and approachable motorcycle. The riding position is upright and relaxed, with a natural reach to the wide handlebars. The low seat height and manageable weight make it confidence-inspiring in traffic and at low speeds.",
    "t-p8"
  ),
  p.(
    [
      t.(
        "On the open road, the triple engine pulls cleanly from low revs and has a satisfying rush toward the redline. It's not the fastest bike in class on paper, but the "
      ),
      i.("way"),
      t.(
        " it delivers its power — smooth, linear, and with that trademark triple howl — makes it feel special."
      )
    ],
    "t-p9"
  ),
  p.(
    "The brakes offer good feel and adequate stopping power for the bike's performance level, and the suspension handles British B-roads with composure. It's a bike that genuinely makes you smile.",
    "t-p10"
  ),
  h.(2, "Common Modifications", "t-h6"),
  p.("Popular modifications among Trident owners include:", "t-p11"),
  num.("Arrow or Akrapovic slip-on exhaust for better sound and slight weight saving", "t-n1"),
  num.("Bar-end mirrors to replace the stock items", "t-n2"),
  num.("Radiator guard to protect against stone chips", "t-n3"),
  num.("Tail tidy / fender eliminator for a cleaner rear end", "t-n4"),
  num.("Adjustable levers for better ergonomics", "t-n5"),
  num.("Tank pads and frame sliders for protection", "t-n6"),
  h.(2, "Service Intervals", "t-h7"),
  p.("Triumph recommends the following service schedule:", "t-p12"),
  bullet.([b.("First service: "), t.("800 km (500 miles) or 4 weeks")], "t-b19"),
  bullet.(
    [
      b.("Minor service: "),
      t.("Every 16,000 km (10,000 miles) or 12 months — oil, filter, and inspection")
    ],
    "t-b20"
  ),
  bullet.(
    [
      b.("Major service: "),
      t.("Every 32,000 km (20,000 miles) or 24 months — includes valve clearance check")
    ],
    "t-b21"
  ),
  bullet.([b.("Coolant: "), t.("Replace every 5 years regardless of mileage")], "t-b22"),
  bullet.([b.("Brake fluid: "), t.("Replace every 2 years")], "t-b23")
]

# --- Steam Deck: Getting Started ---
steam_getting_started = [
  h.(1, "Getting Started with Steam Deck", "sg-h1"),
  p.(
    [
      t.("Welcome to the "),
      b.("Steam Deck"),
      t.(
        " — Valve's portable gaming PC that puts your entire Steam library in your hands. This guide will walk you through everything from unboxing to playing your first game."
      )
    ],
    "sg-p1"
  ),
  h.(2, "What's in the Box", "sg-h2"),
  bullet.("Steam Deck console", "sg-b1"),
  bullet.("45W USB-C power supply with cable", "sg-b2"),
  bullet.("Carrying case (512GB and OLED models get a premium case)", "sg-b3"),
  bullet.("Quick start guide", "sg-b4"),
  p.(
    "No microSD card is included — you'll likely want to pick one up for extra storage.",
    "sg-p2"
  ),
  h.(2, "Initial Setup", "sg-h3"),
  p.("When you first power on the Deck, you'll walk through these steps:", "sg-p3"),
  num.("Select your language and region", "sg-n1"),
  num.("Connect to Wi-Fi", "sg-n2"),
  num.(
    [
      t.("Sign in to your "),
      b.("Steam account"),
      t.(" (use the Steam mobile app for quick two-factor auth)")
    ],
    "sg-n3"
  ),
  num.("Choose a timezone", "sg-n4"),
  num.("Wait for any pending system updates to download and install", "sg-n5"),
  p.(
    [
      t.("The initial update can take "),
      i.("15–30 minutes"),
      t.(" depending on your connection speed. Let it finish before trying to install games.")
    ],
    "sg-p4"
  ),
  h.(2, "Installing Games", "sg-h4"),
  p.("Navigate to your Library from the main menu. Games are grouped by compatibility:", "sg-p5"),
  bullet.([b.("Verified"), t.(" — Fully tested, works great out of the box")], "sg-b5"),
  bullet.(
    [
      b.("Playable"),
      t.(" — Works, but may need manual tweaks (controller config, launcher interaction)")
    ],
    "sg-b6"
  ),
  bullet.(
    [b.("Unsupported"), t.(" — Likely won't work, or requires significant workarounds")],
    "sg-b7"
  ),
  bullet.([b.("Unknown"), t.(" — Not yet tested by Valve")], "sg-b8"),
  p.(
    "Start with Verified titles for the best experience. Many Unsupported or Unknown games actually work fine — check ProtonDB for community reports.",
    "sg-p6"
  ),
  h.(2, "Storage Management", "sg-h5"),
  p.(
    [
      t.("The internal storage fills up fast, especially on the 64GB model. A "),
      b.("microSD card"),
      t.(
        " is essential. The Deck supports cards up to 2TB and game load times from a quality A2/U3 card are nearly identical to internal storage."
      )
    ],
    "sg-p7"
  ),
  p.("To move games between internal and microSD storage:", "sg-p8"),
  num.("Press the Steam button → Settings → Storage", "sg-n6"),
  num.("Select the game you want to move", "sg-n7"),
  num.([t.("Choose "), b.("Move"), t.(" and select the destination")], "sg-n8"),
  h.(2, "Desktop Mode", "sg-h6"),
  p.(
    [
      t.("The Steam Deck runs "),
      b.("SteamOS"),
      t.(
        ", a Linux-based operating system. You can access a full KDE Plasma desktop by pressing the Steam button → Power → Switch to Desktop Mode."
      )
    ],
    "sg-p9"
  ),
  p.("In Desktop Mode you can:", "sg-p10"),
  bullet.("Browse the web with Firefox", "sg-b9"),
  bullet.("Install apps from the Discover store (Flatpak)", "sg-b10"),
  bullet.([t.("Use "), code.("Konsole"), t.(" for terminal access")], "sg-b11"),
  bullet.("Configure Decky Loader plugins", "sg-b12"),
  bullet.("Transfer files via USB or network shares", "sg-b13"),
  p.(
    [
      t.("To return to Gaming Mode, double-click the "),
      b.("Return to Gaming Mode"),
      t.(" shortcut on the desktop.")
    ],
    "sg-p11"
  ),
  h.(2, "Essential Accessories", "sg-h7"),
  p.("Accessories that significantly improve the Steam Deck experience:", "sg-p12"),
  bullet.(
    [b.("microSD card"), t.(" — Samsung EVO Select or SanDisk Extreme, 512GB+ recommended")],
    "sg-b14"
  ),
  bullet.(
    [b.("USB-C dock"), t.(" — for connecting to monitors, Ethernet, and USB peripherals")],
    "sg-b15"
  ),
  bullet.(
    [b.("Screen protector"), t.(" — tempered glass, especially for the LCD model")],
    "sg-b16"
  ),
  bullet.(
    [b.("Carrying case upgrade"), t.(" — if you have the base model without the premium case")],
    "sg-b17"
  ),
  bullet.([b.("Power bank"), t.(" — 45W+ USB-C PD for full-speed charging on the go")], "sg-b18")
]

# --- Steam Deck: Performance Tweaks ---
steam_performance = [
  h.(1, "Steam Deck Performance Tweaks", "sp-h1"),
  p.(
    "The Steam Deck is impressively capable, but learning how to tune performance per game can dramatically improve your experience — better frame rates, longer battery life, or both.",
    "sp-p1"
  ),
  h.(2, "Quick Access Performance Overlay", "sp-h2"),
  p.(
    [
      t.("Press the "),
      b.("..."),
      t.(" (Quick Access) button and go to the "),
      b.("Performance"),
      t.(" tab (battery icon). This is where all the magic happens.")
    ],
    "sp-p2"
  ),
  p.("Key settings available:", "sp-p3"),
  bullet.(
    [b.("Framerate Limit"), t.(" — 15, 30, 40, 60 fps (or off). Lower = better battery life")],
    "sp-b1"
  ),
  bullet.(
    [
      b.("Refresh Rate"),
      t.(" — Match to your frame limit for smooth output (40Hz for 40fps, etc.)")
    ],
    "sp-b2"
  ),
  bullet.(
    [b.("Allow Tearing"), t.(" — Eliminates input lag but can cause visual tearing")],
    "sp-b3"
  ),
  bullet.(
    [
      b.("Half Rate Shading"),
      t.(" — Reduces GPU shading work; surprisingly good for many games")
    ],
    "sp-b4"
  ),
  bullet.([b.("TDP Limit"), t.(" — Cap the CPU/GPU power draw in watts (3–15W)")], "sp-b5"),
  bullet.(
    [b.("GPU Clock Frequency"), t.(" — Manual GPU clock override (200–1600 MHz)")],
    "sp-b6"
  ),
  bullet.([b.("Scaling Filter"), t.(" — FSR, Integer, Linear, or Nearest")], "sp-b7"),
  h.(2, "The Golden 40fps Setup", "sp-h3"),
  p.(
    [
      t.("For most games, "),
      b.("40fps at 40Hz"),
      t.(
        " is the sweet spot on the Deck. It's noticeably smoother than 30fps while using significantly less power than 60fps. The OLED model's 90Hz display makes 45fps another excellent target."
      )
    ],
    "sp-p4"
  ),
  p.("To set this up:", "sp-p5"),
  num.("Open Quick Access → Performance", "sp-n1"),
  num.("Set Framerate Limit to 40", "sp-n2"),
  num.("Set Refresh Rate to 40", "sp-n3"),
  num.("Enable per-game profile so this only applies to the current game", "sp-n4"),
  h.(2, "Per-Game Profiles", "sp-h4"),
  p.(
    [
      t.("Toggle "),
      b.("Use Per-Game Profile"),
      t.(
        " in the performance overlay. This saves your performance settings individually for each game. This is essential — you don't want your Hades settings applied to Cyberpunk 2077."
      )
    ],
    "sp-p6"
  ),
  p.("Recommended starting points by game type:", "sp-p7"),
  bullet.(
    [b.("Indie / 2D games"), t.(" — 60fps, TDP limit 4–6W for massive battery life")],
    "sp-b8"
  ),
  bullet.([b.("Older 3D titles"), t.(" — 60fps, TDP limit 8–10W")], "sp-b9"),
  bullet.([b.("Modern AAA"), t.(" — 30–40fps, FSR enabled, TDP limit 12–15W")], "sp-b10"),
  h.(2, "FSR (FidelityFX Super Resolution)", "sp-h5"),
  p.(
    [
      t.("When you set an in-game resolution "),
      i.("below"),
      t.(" the Deck's native resolution (1280x800), SteamOS can apply "),
      b.("AMD FSR"),
      t.(
        " upscaling. This renders the game at a lower resolution for better performance, then upscales it intelligently."
      )
    ],
    "sp-p8"
  ),
  p.("Best practice:", "sp-p9"),
  num.("Set in-game resolution to 960x600 or 1024x640", "sp-n5"),
  num.("Enable FSR in the performance overlay", "sp-n6"),
  num.("Set FSR Sharpness to 3–4 (higher = sharper but can look artificial)", "sp-n7"),
  p.(
    "The result is often indistinguishable from native resolution on the Deck's small screen while gaining 20–40% more performance.",
    "sp-p10"
  ),
  h.(2, "Proton / Compatibility Layer Settings", "sp-h6"),
  p.(
    [
      t.(
        "Some games perform better with specific Proton versions. To change the Proton version: go to the game's "
      ),
      b.("Properties → Compatibility"),
      t.(" and select a different version.")
    ],
    "sp-p11"
  ),
  bullet.([b.("Proton Experimental"), t.(" — Latest, best for most newer games")], "sp-b11"),
  bullet.(
    [
      b.("Proton GE"),
      t.(" — Community build with extra patches. Install via ProtonUp-Qt in Desktop Mode")
    ],
    "sp-b12"
  ),
  bullet.(
    [b.("Proton 8.x / 9.x"), t.(" — Stable releases, good fallback if Experimental has issues")],
    "sp-b13"
  ),
  h.(2, "Battery Life Tips", "sp-h7"),
  p.(
    "Beyond frame limits and TDP caps, a few more tricks for maximizing battery life:",
    "sp-p12"
  ),
  bullet.("Reduce screen brightness — the display is one of the biggest power draws", "sp-b14"),
  bullet.("Disable Wi-Fi while playing offline games", "sp-b15"),
  bullet.("Use Bluetooth only when needed (controller, earbuds)", "sp-b16"),
  bullet.("Disable haptics or reduce haptic intensity", "sp-b17"),
  bullet.("Close background processes (Discord overlay, browser tabs in Desktop Mode)", "sp-b18"),
  p.(
    [
      t.("With aggressive tuning, indie games can run for "),
      b.("5–6 hours"),
      t.(" on the LCD model. Demanding AAA games will drain the battery in "),
      b.("90 minutes to 2 hours"),
      t.(".")
    ],
    "sp-p13"
  )
]

# --- ROG Ally X: Overview ---
rog_overview = [
  h.(1, "ROG Ally X Overview", "ro-h1"),
  p.(
    [
      t.("The "),
      b.("ASUS ROG Ally X"),
      t.(
        " is the refined second generation of ASUS's handheld gaming PC. Released in mid-2024, it addresses nearly every criticism of the original Ally while retaining its powerful AMD Z1 Extreme chipset."
      )
    ],
    "ro-p1"
  ),
  h.(2, "Key Specifications", "ro-h2"),
  bullet.(
    [b.("Processor: "), t.("AMD Ryzen Z1 Extreme (8 cores / 16 threads, RDNA 3 graphics)")],
    "ro-b1"
  ),
  bullet.([b.("RAM: "), t.("24GB LPDDR5X-7500 (up from 16GB)")], "ro-b2"),
  bullet.([b.("Storage: "), t.("1TB PCIe 4.0 NVMe SSD (user-replaceable)")], "ro-b3"),
  bullet.([b.("Display: "), t.("7-inch IPS, 1920x1080, 120Hz, 500 nits, VRR support")], "ro-b4"),
  bullet.([b.("Battery: "), t.("80Wh (doubled from original's 40Wh)")], "ro-b5"),
  bullet.([b.("Weight: "), t.("678g")], "ro-b6"),
  bullet.([b.("OS: "), t.("Windows 11")], "ro-b7"),
  h.(2, "What's New vs. Original Ally", "ro-h3"),
  p.("The Ally X is more of a major revision than a true sequel. Key improvements:", "ro-p2"),
  num.(
    [
      b.("Doubled battery"),
      t.(
        " — The 80Wh cell is the headline upgrade. Expect roughly 1.5–2x the playtime of the original."
      )
    ],
    "ro-n1"
  ),
  num.(
    [b.("24GB RAM"), t.(" — More headroom for demanding games and Windows overhead")],
    "ro-n2"
  ),
  num.(
    [
      b.("Improved ergonomics"),
      t.(
        " — Slightly reshaped grips, relocated XG Mobile port to top, better weight distribution"
      )
    ],
    "ro-n3"
  ),
  num.([b.("1TB storage"), t.(" — Double the original's 512GB")], "ro-n4"),
  num.(
    [b.("Improved thermals"), t.(" — New fan design runs cooler and quieter under load")],
    "ro-n5"
  ),
  num.([b.("Sturdier build"), t.(" — Improved triggers, dpad, and overall feel")], "ro-n6"),
  h.(2, "Windows on a Handheld", "ro-h4"),
  p.(
    [
      t.("Unlike the Steam Deck (which runs Linux), the Ally X runs "),
      b.("Windows 11"),
      t.(". This has trade-offs:")
    ],
    "ro-p3"
  ),
  p.([b.("Advantages:")], "ro-p4"),
  bullet.("Native compatibility with virtually every PC game", "ro-b8"),
  bullet.("Full access to Game Pass, Epic, GOG, Battle.net — not just Steam", "ro-b9"),
  bullet.("Easy anti-cheat support in all multiplayer games", "ro-b10"),
  bullet.("Standard Windows app ecosystem", "ro-b11"),
  p.([b.("Disadvantages:")], "ro-p5"),
  bullet.(
    "Windows is not optimized for handheld use — touch targets are small, system popups interrupt gameplay",
    "ro-b12"
  ),
  bullet.("Higher RAM usage at idle (~4–5GB) compared to SteamOS (~1GB)", "ro-b13"),
  bullet.("Windows updates can be disruptive", "ro-b14"),
  bullet.("Sleep/resume is less reliable than SteamOS", "ro-b15"),
  h.(2, "Armoury Crate SE", "ro-h5"),
  p.(
    [
      t.("ASUS provides "),
      b.("Armoury Crate SE"),
      t.(" as the handheld-optimized game launcher and system control center. It provides:")
    ],
    "ro-p6"
  ),
  bullet.(
    "A controller-friendly game library aggregating Steam, Game Pass, Epic, etc.",
    "ro-b16"
  ),
  bullet.("Quick-access performance profiles (Silent, Performance, Turbo)", "ro-b17"),
  bullet.("Per-game TDP and GPU clock settings", "ro-b18"),
  bullet.("Controller remapping and macro support", "ro-b19"),
  bullet.("System monitoring (FPS, temps, power draw)", "ro-b20"),
  p.(
    "It's not perfect — it can be buggy after updates — but it's improved significantly since launch and is essential for a good handheld experience on Windows.",
    "ro-p7"
  )
]

# --- ROG Ally X: Best Settings ---
rog_settings = [
  h.(1, "ROG Ally X Best Settings", "rs-h1"),
  p.(
    "Getting the most out of your ROG Ally X requires tuning both Windows and per-game settings. Here's a comprehensive guide to optimizing the experience.",
    "rs-p1"
  ),
  h.(2, "Windows Optimizations", "rs-h2"),
  p.("Start with these system-level tweaks:", "rs-p2"),
  num.(
    [
      b.("Disable Notifications in game"),
      t.(" — Settings → System → Notifications → turn off while gaming")
    ],
    "rs-n1"
  ),
  num.(
    [b.("Set active hours for Windows Update"), t.(" — Prevent surprise update reboots")],
    "rs-n2"
  ),
  num.(
    [
      b.("Disable hardware-accelerated GPU scheduling"),
      t.(" — Reported to cause micro-stutters on the Z1 Extreme")
    ],
    "rs-n3"
  ),
  num.(
    [
      b.("Set power plan to Balanced"),
      t.(" — Let Armoury Crate handle performance modes instead")
    ],
    "rs-n4"
  ),
  num.(
    [b.("Disable background apps"), t.(" — Xbox Game Bar, OneDrive, Cortana, Widgets")],
    "rs-n5"
  ),
  h.(2, "Armoury Crate Performance Profiles", "rs-h3"),
  p.("The three built-in profiles and when to use them:", "rs-p3"),
  bullet.(
    [
      b.("Silent (9W)"),
      t.(" — Visual novels, 2D games, retro emulation. Minimal fan noise, 3+ hours of battery")
    ],
    "rs-b1"
  ),
  bullet.(
    [
      b.("Performance (15W)"),
      t.(" — The daily driver. Good balance of power and efficiency for most games")
    ],
    "rs-b2"
  ),
  bullet.(
    [
      b.("Turbo (25W+)"),
      t.(" — Maximum performance. Use when plugged in for demanding AAA titles")
    ],
    "rs-b3"
  ),
  p.(
    [
      t.("You can create "),
      b.("custom profiles"),
      t.(
        " per game via Armoury Crate SE's game library. This lets you fine-tune TDP, fan curves, and GPU clocks for each title."
      )
    ],
    "rs-p4"
  ),
  h.(2, "Display & Resolution Scaling", "rs-h4"),
  p.(
    [
      t.(
        "The Ally X has a 1080p display, which is demanding for the integrated GPU. For most games, rendering at "
      ),
      b.("720p or 900p"),
      t.(" and using upscaling provides the best balance.")
    ],
    "rs-p5"
  ),
  bullet.(
    [
      b.("RSR (Radeon Super Resolution)"),
      t.(
        " — AMD's driver-level FSR. Set in-game resolution to 720p/900p and enable RSR in AMD Software"
      )
    ],
    "rs-b4"
  ),
  bullet.(
    [
      b.("In-game FSR 2/3"),
      t.(" — When available, use Quality or Balanced preset. Better quality than RSR")
    ],
    "rs-b5"
  ),
  bullet.(
    [b.("Integer scaling"), t.(" — Best for retro/pixel-art games at exact multipliers")],
    "rs-b6"
  ),
  h.(2, "Per-Game Recommended Settings", "rs-h5"),
  p.("Starting points for popular titles:", "rs-p6"),
  h.(3, "Cyberpunk 2077", "rs-h6"),
  bullet.("Steam Deck preset as baseline, increase to Medium textures", "rs-b7"),
  bullet.("FSR 2 on Quality, 30–40fps target", "rs-b8"),
  bullet.("Performance mode, TDP 15W for portable play", "rs-b9"),
  h.(3, "Elden Ring", "rs-h7"),
  bullet.("Medium preset, 720p with RSR", "rs-b10"),
  bullet.("40fps cap via RTSS (game doesn't support custom frame limits)", "rs-b11"),
  bullet.("Performance mode is sufficient", "rs-b12"),
  h.(3, "Baldur's Gate 3", "rs-h8"),
  bullet.("Medium-High preset, FSR on Balanced", "rs-b13"),
  bullet.("30fps target in Act 3 (CPU-heavy area)", "rs-b14"),
  bullet.("Model Quality to Medium saves significant VRAM", "rs-b15"),
  h.(2, "Battery Life Optimization", "rs-h6b"),
  p.(
    "The Ally X's 80Wh battery is generous, but demanding games still drain it quickly. Maximize your untethered gaming time:",
    "rs-p7"
  ),
  bullet.(
    [
      t.("Lock to "),
      b.("30fps"),
      t.(" for games where you can tolerate it — doubles battery vs 60fps")
    ],
    "rs-b16"
  ),
  bullet.("Reduce brightness to 40–50%", "rs-b17"),
  bullet.("Use Performance mode (15W) instead of Turbo (25W+)", "rs-b18"),
  bullet.("Disable Wi-Fi and Bluetooth when not needed", "rs-b19"),
  bullet.("Close background launchers (Steam, Epic, Game Bar)", "rs-b20"),
  p.(
    [
      t.("Expect "),
      b.("2–3 hours"),
      t.(" of AAA gaming at medium settings, and "),
      b.("4–6 hours"),
      t.(" for lighter titles.")
    ],
    "rs-p8"
  )
]

# --- PS5: Tips & Tricks ---
ps5_tips = [
  h.(1, "PS5 Tips & Tricks", "ps-h1"),
  p.(
    "The PlayStation 5 is packed with features that many owners never discover. This guide covers the most useful tips to get more out of your console.",
    "ps-p1"
  ),
  h.(2, "Storage Management", "ps-h2"),
  p.(
    [
      t.("The PS5's internal SSD is fast but limited. The "),
      b.("825GB"),
      t.(" total translates to roughly "),
      b.("667GB"),
      t.(" of usable space after the OS. Here's how to manage it effectively:")
    ],
    "ps-p2"
  ),
  bullet.(
    [
      b.("Expand with NVMe SSD"),
      t.(
        " — The internal M.2 slot supports PCIe Gen 4 drives. A heatsink is required (most NVMe drives include one now)"
      )
    ],
    "ps-b1"
  ),
  bullet.(
    [
      b.("Move PS4 games to USB"),
      t.(" — PS4 titles can run from an external USB drive, freeing internal space for PS5 games")
    ],
    "ps-b2"
  ),
  bullet.(
    [
      b.("Auto-delete game data"),
      t.(" — Settings → Storage → manage which data types auto-delete")
    ],
    "ps-b3"
  ),
  bullet.(
    [
      b.("Game install sizes"),
      t.(
        " — Check the store page before buying. Some titles (COD, Final Fantasy XVI) consume 100GB+"
      )
    ],
    "ps-b4"
  ),
  h.(2, "Performance vs. Fidelity Mode", "ps-h3"),
  p.("Most PS5 games offer two rendering modes:", "ps-p3"),
  bullet.(
    [
      b.("Performance Mode"),
      t.(" — Targets 60fps (sometimes 120fps) at lower resolution or visual settings")
    ],
    "ps-b5"
  ),
  bullet.([b.("Fidelity Mode"), t.(" — Targets native 4K or ray tracing at 30fps")], "ps-b6"),
  p.(
    [
      t.("You can set a "),
      b.("system-wide default"),
      t.(
        " in Settings → Save Data and Game/App Settings → Game Presets. This applies to all games that support both modes, so you don't have to switch in each game's menu."
      )
    ],
    "ps-p4"
  ),
  p.(
    [
      i.(
        "Recommendation: Performance Mode is the better default for most players. The smoothness of 60fps outweighs the visual bump of 4K on most TV setups."
      )
    ],
    "ps-p5"
  ),
  h.(2, "DualSense Features", "ps-h4"),
  p.("The DualSense is one of the PS5's standout features. Make the most of it:", "ps-p6"),
  bullet.(
    [
      b.("Haptic feedback intensity"),
      t.(
        " — Adjust in Settings → Accessories → Controllers. Strong for immersion, weak for longer sessions"
      )
    ],
    "ps-b7"
  ),
  bullet.(
    [
      b.("Adaptive trigger intensity"),
      t.(" — Same menu. Can reduce hand fatigue in games that use them heavily")
    ],
    "ps-b8"
  ),
  bullet.(
    [
      b.("Built-in mic"),
      t.(
        " — The controller has a microphone. Mute it quickly by tapping the mute button below the PS button"
      )
    ],
    "ps-b9"
  ),
  bullet.(
    [
      b.("Speaker volume"),
      t.(" — Adjustable in settings. Some games use it brilliantly (Astro's Playroom, Returnal)")
    ],
    "ps-b10"
  ),
  bullet.(
    [
      b.("Battery life"),
      t.(
        " — Reduce trigger/haptic intensity and lower controller speaker volume to extend battery. Dimming the light bar helps marginally too"
      )
    ],
    "ps-b11"
  ),
  h.(2, "Hidden UI Features", "ps-h5"),
  p.("Features buried in the PS5 UI that are easy to miss:", "ps-p7"),
  num.(
    [
      b.("Switcher"),
      t.(" — Double-tap the PS button to quickly switch between your last two apps/games")
    ],
    "ps-n1"
  ),
  num.(
    [
      b.("Game Help"),
      t.(
        " — PS Plus subscribers get in-game hint cards for supported titles via the Activities system"
      )
    ],
    "ps-n2"
  ),
  num.(
    [
      b.("Custom game lists"),
      t.(
        " — In your library, create collections to organize your games (e.g., Backlog, Currently Playing, Platinum'd)"
      )
    ],
    "ps-n3"
  ),
  num.(
    [
      b.("Screen recording"),
      t.(
        " — Press Create button, then Square for screenshot or Triangle for recording. Hold Create for instant screenshot"
      )
    ],
    "ps-n4"
  ),
  num.(
    [
      b.("Web browser"),
      t.(
        " — Not officially supported, but you can access it through the messaging app by sending yourself a link"
      )
    ],
    "ps-n5"
  ),
  h.(2, "Network & Remote Play", "ps-h6"),
  p.("Improve your online and remote gaming experience:", "ps-p8"),
  bullet.(
    [
      b.("Use Ethernet"),
      t.(
        " — Wi-Fi 6 is fine for most cases, but a wired connection eliminates interference and reduces latency"
      )
    ],
    "ps-b12"
  ),
  bullet.(
    [
      b.("Remote Play"),
      t.(
        " — Stream your PS5 to a phone, tablet, PC, or another PS console. Works over local network and internet"
      )
    ],
    "ps-b13"
  ),
  bullet.(
    [
      b.("Rest Mode downloads"),
      t.(" — Enable network in Rest Mode to keep games updated and charged controllers")
    ],
    "ps-b14"
  ),
  bullet.(
    [
      b.("NAT Type"),
      t.(
        " — Type 1 (open) is ideal for multiplayer. If you're Type 3, set up port forwarding on your router"
      )
    ],
    "ps-b15"
  ),
  h.(2, "Accessibility Options", "ps-h7"),
  p.(
    "The PS5 has extensive accessibility features worth exploring even for players without disabilities:",
    "ps-p9"
  ),
  bullet.([b.("Button remapping"), t.(" — Remap any controller button system-wide")], "ps-b16"),
  bullet.([b.("Screen reader"), t.(" — Full TTS for all system menus")], "ps-b17"),
  bullet.([b.("High contrast UI"), t.(" — Easier on the eyes in dark rooms")], "ps-b18"),
  bullet.(
    [
      b.("Custom button assignments"),
      t.(" — Create multiple profiles for different games or users")
    ],
    "ps-b19"
  )
]

# --- Retroid Pocket 5: Setup Guide ---
retroid_setup = [
  h.(1, "Retroid Pocket 5 Setup Guide", "rp-h1"),
  p.(
    [
      t.("The "),
      b.("Retroid Pocket 5"),
      t.(
        " is one of the most capable retro gaming handhelds available. Powered by a Qualcomm Snapdragon chipset and running Android, it can handle everything from NES to GameCube and PS2 with ease."
      )
    ],
    "rp-p1"
  ),
  h.(2, "First Boot & Android Setup", "rp-h2"),
  p.("On first boot, you'll go through standard Android setup:", "rp-p2"),
  num.("Select language and connect to Wi-Fi", "rp-n1"),
  num.("Skip Google account sign-in if you prefer (you can add it later)", "rp-n2"),
  num.("Complete setup and allow the system to check for OTA updates", "rp-n3"),
  num.("Install all pending updates — there are usually several at launch", "rp-n4"),
  p.(
    [
      t.("The Retroid Pocket 5 ships with the "),
      b.("Retroid Launcher"),
      t.(
        " pre-installed, which provides a console-like frontend optimized for controller navigation."
      )
    ],
    "rp-p3"
  ),
  h.(2, "Transferring ROMs", "rp-h3"),
  p.("You have several options for getting your game library onto the device:", "rp-p4"),
  bullet.(
    [
      b.("microSD card"),
      t.(
        " — Format as exFAT, create a folder structure (e.g., /ROMs/SNES/, /ROMs/PSX/), and insert into the device"
      )
    ],
    "rp-b1"
  ),
  bullet.(
    [
      b.("USB file transfer"),
      t.(" — Connect to PC via USB-C, the device appears as a storage device")
    ],
    "rp-b2"
  ),
  bullet.(
    [
      b.("Wireless transfer"),
      t.(" — Use apps like Syncthing or just a basic file manager with SMB/FTP support")
    ],
    "rp-b3"
  ),
  p.(
    [
      i.(
        "Organize your ROMs by system in separate folders. This makes emulator setup much easier and keeps the Retroid Launcher tidy."
      )
    ],
    "rp-p5"
  ),
  h.(2, "Recommended Emulators", "rp-h4"),
  p.("The best emulator for each system on the RP5:", "rp-p6"),
  bullet.(
    [b.("NES / SNES / Genesis / GBA"), t.(" — RetroArch (use the appropriate core)")],
    "rp-b4"
  ),
  bullet.([b.("Nintendo DS"), t.(" — DraStic (best performance) or melonDS")], "rp-b5"),
  bullet.([b.("PlayStation 1"), t.(" — Duckstation")], "rp-b6"),
  bullet.([b.("Nintendo 64"), t.(" — Mupen64Plus FZ")], "rp-b7"),
  bullet.([b.("PSP"), t.(" — PPSSPP")], "rp-b8"),
  bullet.([b.("Dreamcast"), t.(" — Flycast (via RetroArch or standalone)")], "rp-b9"),
  bullet.([b.("GameCube / Wii"), t.(" — Dolphin (official build from Play Store)")], "rp-b10"),
  bullet.([b.("PlayStation 2"), t.(" — AetherSX2 or NetherSX2")], "rp-b11"),
  bullet.([b.("3DS"), t.(" — Citra (MMJ fork)")], "rp-b12"),
  p.(
    [
      t.("Install these from the "),
      b.("Play Store"),
      t.(" where available, or from trusted sources like the emulator's official website.")
    ],
    "rp-p7"
  ),
  h.(2, "RetroArch Setup", "rp-h5"),
  p.("RetroArch handles most retro systems through a single app. Initial setup:", "rp-p8"),
  num.("Install RetroArch from the Play Store", "rp-n5"),
  num.("Go to Online Updater → Core Downloader and install the cores you need", "rp-n6"),
  num.(
    [
      t.("Set your ROM directory: Settings → Directory → File Browser → point to your "),
      code.("/ROMs"),
      t.(" folder")
    ],
    "rp-n7"
  ),
  num.("Scan your ROM directory to build playlists: Import Content → Scan Directory", "rp-n8"),
  num.("Configure controller input: Settings → Input → set up your device buttons", "rp-n9"),
  p.("Key RetroArch settings for the RP5:", "rp-p9"),
  bullet.([b.("Video driver"), t.(" — Use Vulkan for best performance")], "rp-b13"),
  bullet.(
    [b.("Frame throttle"), t.(" — Enable VSync, set max framerate to match screen (60fps)")],
    "rp-b14"
  ),
  bullet.(
    [
      b.("Rewind"),
      t.(
        " — Enable for retro systems (NES, SNES) for a great quality-of-life feature. Disable for demanding systems"
      )
    ],
    "rp-b15"
  ),
  h.(2, "Retroid Launcher Configuration", "rp-h6"),
  p.(
    [
      t.("The "),
      b.("Retroid Launcher"),
      t.(" is a frontend that presents your games in a polished, console-like interface:")
    ],
    "rp-p10"
  ),
  num.("Open Retroid Launcher → Settings → Systems", "rp-n10"),
  num.("For each system, set the ROM path and default emulator", "rp-n11"),
  num.("Scan for games — the launcher will scrape box art and metadata automatically", "rp-n12"),
  num.("Customize the home screen layout and collections", "rp-n13"),
  p.(
    "You can also use alternative frontends like Daijisho or Pegasus if you prefer a different look and feel.",
    "rp-p11"
  ),
  h.(2, "Performance Tips", "rp-h7"),
  p.("Get the best performance from your RP5:", "rp-p12"),
  bullet.(
    [
      b.("Set performance mode"),
      t.(" — In the system tray, switch to Performance mode for demanding games (GameCube, PS2)")
    ],
    "rp-b16"
  ),
  bullet.(
    [
      b.("Close background apps"),
      t.(" — Android loves keeping apps in memory. Force stop unused apps before heavy emulation")
    ],
    "rp-b17"
  ),
  bullet.(
    [
      b.("Per-game settings"),
      t.(" — Most emulators support per-game profiles. Use lower settings for demanding titles")
    ],
    "rp-b18"
  ),
  bullet.(
    [
      b.("Thermal management"),
      t.(
        " — The device can throttle during long PS2/GameCube sessions. A small fan or playing in a cool environment helps"
      )
    ],
    "rp-b19"
  ),
  bullet.(
    [
      b.("Shader caching"),
      t.(
        " — Dolphin and AetherSX2 stutter on first run as they build shader caches. Subsequent plays will be much smoother"
      )
    ],
    "rp-b20"
  )
]

# --- Dolphin: Installation ---
dolphin_install = [
  h.(1, "Dolphin Emulator Installation", "di-h1"),
  p.(
    [
      t.("Dolphin is the premier open-source emulator for "),
      b.("Nintendo GameCube"),
      t.(" and "),
      b.("Nintendo Wii"),
      t.(
        " games. It runs on Windows, macOS, Linux, and Android, and can play most games at full speed with significant graphical improvements over original hardware."
      )
    ],
    "di-p1"
  ),
  h.(2, "System Requirements", "di-h2"),
  p.("Dolphin is more CPU-dependent than GPU-dependent. Minimum and recommended specs:", "di-p2"),
  h.(3, "Minimum", "di-h3"),
  bullet.([b.("CPU: "), t.("Any modern x86-64 or ARM64 processor with SSE2 support")], "di-b1"),
  bullet.([b.("GPU: "), t.("OpenGL 4.4 or Vulkan 1.1 compatible")], "di-b2"),
  bullet.([b.("RAM: "), t.("4GB")], "di-b3"),
  bullet.([b.("OS: "), t.("Windows 10 64-bit, macOS 12+, or Linux (64-bit)")], "di-b4"),
  h.(3, "Recommended", "di-h4"),
  bullet.([b.("CPU: "), t.("Intel Core i5-10400 / AMD Ryzen 5 3600 or better")], "di-b5"),
  bullet.([b.("GPU: "), t.("Any discrete GPU from the last 5 years")], "di-b6"),
  bullet.([b.("RAM: "), t.("8GB+")], "di-b7"),
  h.(2, "Installation by Platform", "di-h5"),
  h.(3, "Windows", "di-h6"),
  num.(
    [
      t.("Download the latest "),
      b.("Development"),
      t.(" build from the official Dolphin website")
    ],
    "di-n1"
  ),
  num.(
    "Extract the .7z archive to a folder of your choice (e.g., C:\\Emulators\\Dolphin)",
    "di-n2"
  ),
  num.("Run Dolphin.exe — no installer needed, it's fully portable", "di-n3"),
  num.("Install the Visual C++ Redistributable if prompted (2022 version)", "di-n4"),
  p.(
    [
      i.(
        "Use the Development builds, not the Stable release. Stable is years out of date. Development builds are tested and much more compatible."
      )
    ],
    "di-p3"
  ),
  h.(3, "macOS", "di-h7"),
  num.("Download the macOS universal build (.dmg) from the Dolphin website", "di-n5"),
  num.("Drag Dolphin to your Applications folder", "di-n6"),
  num.(
    [
      t.("Right-click → Open on first launch to bypass Gatekeeper (or allow it in "),
      b.("System Preferences → Security"),
      t.(")")
    ],
    "di-n7"
  ),
  p.(
    "Apple Silicon Macs (M1/M2/M3/M4) run Dolphin extremely well via the native ARM64 build. Most GameCube and Wii titles hit full speed.",
    "di-p4"
  ),
  h.(3, "Linux", "di-h8"),
  p.("Multiple installation options:", "di-p5"),
  bullet.(
    [
      b.("Flatpak (recommended)"),
      t.(" — "),
      code.("flatpak install flathub org.DolphinEmu.dolphin-emu")
    ],
    "di-b8"
  ),
  bullet.(
    [
      b.("PPA (Ubuntu/Debian)"),
      t.(" — "),
      code.(
        "sudo add-apt-repository ppa:dolphin-emu/ppa && sudo apt update && sudo apt install dolphin-emu"
      )
    ],
    "di-b9"
  ),
  bullet.([b.("AUR (Arch)"), t.(" — "), code.("yay -S dolphin-emu-git")], "di-b10"),
  h.(3, "Android", "di-h9"),
  num.("Install from the Google Play Store (official listing)", "di-n8"),
  num.(
    "Requires a modern ARM64 device (Snapdragon 8-series, Dimensity 9000+, Tensor G2+)",
    "di-n9"
  ),
  num.("Performance varies significantly by device and game", "di-n10"),
  h.(2, "Initial Configuration", "di-h10"),
  p.("After installation, configure these essential settings:", "di-p6"),
  num.(
    [b.("Paths"), t.(" — Config → Paths → add your GameCube and Wii game directories")],
    "di-n11"
  ),
  num.(
    [
      b.("Graphics backend"),
      t.(" — Graphics → Backend → select Vulkan (best for most systems) or OpenGL")
    ],
    "di-n12"
  ),
  num.(
    [
      b.("Internal resolution"),
      t.(" — Graphics → Enhancements → set to 2x or 3x native for sharp visuals")
    ],
    "di-n13"
  ),
  num.(
    [b.("Controller"), t.(" — see the Controller Configuration page for detailed setup")],
    "di-n14"
  ),
  p.(
    [
      t.("Game ISOs should be in "),
      b.(".iso"),
      t.(", "),
      b.(".gcm"),
      t.(", "),
      b.(".wbfs"),
      t.(", or "),
      b.(".rvz"),
      t.(
        " format. RVZ is recommended for storage efficiency — you can convert ISOs to RVZ within Dolphin itself."
      )
    ],
    "di-p7"
  ),
  h.(2, "BIOS & System Files", "di-h11"),
  p.(
    [
      t.("Dolphin does "),
      b.("not"),
      t.(
        " require GameCube or Wii system files (BIOS/NAND) for most games. The emulator includes high-level emulation that handles system functions."
      )
    ],
    "di-p8"
  ),
  p.("However, some specific scenarios need real system files:", "di-p9"),
  bullet.("Wii Menu / System Transfer features", "di-b11"),
  bullet.("Some WiiWare and Virtual Console titles", "di-b12"),
  bullet.("Games that rely on specific system settings", "di-b13"),
  p.(
    [
      t.("If needed, dump these from a real Wii console. Place them in Dolphin's "),
      code.("User/Wii"),
      t.(" directory.")
    ],
    "di-p10"
  )
]

# --- Dolphin: Controller Configuration ---
dolphin_controller = [
  h.(1, "Dolphin Controller Configuration", "dc-h1"),
  p.(
    "Proper controller setup is essential for the best Dolphin experience. The GameCube controller's unique layout (especially the analog triggers) and the Wii Remote's motion controls require careful mapping.",
    "dc-p1"
  ),
  h.(2, "GameCube Controller Setup", "dc-h2"),
  p.("For standard controller input (Xbox, PlayStation, Switch Pro, etc.):", "dc-p2"),
  num.([t.("Go to "), b.("Controllers → GameCube → Port 1 → Configure")], "dc-n1"),
  num.("Select your controller from the Device dropdown", "dc-n2"),
  num.("Click each button field and press the corresponding button on your controller", "dc-n3"),
  num.("Map the C-Stick to the right analog stick", "dc-n4"),
  num.(
    [
      t.("Set "),
      b.("L-Analog"),
      t.(" and "),
      b.("R-Analog"),
      t.(" to your controller's triggers (LT/RT)")
    ],
    "dc-n5"
  ),
  num.("Save your profile for reuse", "dc-n6"),
  h.(3, "Recommended GameCube Mappings", "dc-h3"),
  p.("Standard mapping for an Xbox-style controller:", "dc-p3"),
  bullet.([b.("A → A"), t.(" (south button)")], "dc-b1"),
  bullet.([b.("B → X"), t.(" (west button) or B (east) — preference varies")], "dc-b2"),
  bullet.([b.("X → Y"), t.(" (north button)")], "dc-b3"),
  bullet.([b.("Y → B"), t.(" (east button) or RB")], "dc-b4"),
  bullet.([b.("Z → RB"), t.(" (right bumper)")], "dc-b5"),
  bullet.([b.("L → LT"), t.(" (left trigger, full analog)")], "dc-b6"),
  bullet.([b.("R → RT"), t.(" (right trigger, full analog)")], "dc-b7"),
  bullet.([b.("D-Pad → D-Pad")], "dc-b8"),
  bullet.([b.("Control Stick → Left Stick")], "dc-b9"),
  bullet.([b.("C-Stick → Right Stick")], "dc-b10"),
  p.(
    [
      i.(
        "The GameCube's trigger buttons have both analog and digital stages. Most modern controllers handle this fine with their analog triggers, but some games (Super Mario Sunshine, Luigi's Mansion) specifically rely on the analog range and digital click."
      )
    ],
    "dc-p4"
  ),
  h.(2, "Wii Remote Configuration", "dc-h4"),
  p.("Wii games require one of several controller configurations:", "dc-p5"),
  bullet.(
    [
      b.("Emulated Wii Remote"),
      t.(
        " — Maps Wii Remote functions to a standard controller. Good for games that don't rely heavily on pointing/motion"
      )
    ],
    "dc-b11"
  ),
  bullet.(
    [
      b.("Real Wii Remote"),
      t.(" — Connect a genuine Wii Remote via Bluetooth for the most authentic experience")
    ],
    "dc-b12"
  ),
  h.(3, "Emulated Wii Remote Setup", "dc-h5"),
  num.(
    [t.("Go to "), b.("Controllers → Wii Remote 1 → Emulated Wii Remote → Configure")],
    "dc-n7"
  ),
  num.("Map buttons: A, B, 1, 2, +, -, Home to your controller", "dc-n8"),
  num.(
    [
      t.("Configure "),
      b.("IR pointer"),
      t.(
        " — map to right stick for aiming/pointing games. Adjust sensitivity under the Motion Simulation tab"
      )
    ],
    "dc-n9"
  ),
  num.(
    [
      t.("Configure "),
      b.("Shake/Tilt/Swing"),
      t.(" — map these to buttons or stick flicks for motion actions")
    ],
    "dc-n10"
  ),
  p.("For games that use the Nunchuk:", "dc-p6"),
  bullet.([t.("Set Extension to "), b.("Nunchuk"), t.(" in the dropdown")], "dc-b13"),
  bullet.("Map Nunchuk stick to left analog stick", "dc-b14"),
  bullet.("Map C and Z buttons", "dc-b15"),
  bullet.("Map Nunchuk shake to a button", "dc-b16"),
  h.(3, "Real Wii Remote via Bluetooth", "dc-h6"),
  p.("For the best experience with motion-heavy games:", "dc-p7"),
  num.("Enable Bluetooth on your PC", "dc-n11"),
  num.([t.("In Dolphin, go to "), b.("Controllers → Wii Remote 1 → Real Wii Remote")], "dc-n12"),
  num.("Press 1+2 on the Wii Remote simultaneously to put it in pairing mode", "dc-n13"),
  num.([t.("Click "), b.("Refresh"), t.(" in Dolphin — it should detect the remote")], "dc-n14"),
  num.(
    "A Sensor Bar (or two candles/IR LEDs placed 8 inches apart) is needed for pointer functionality",
    "dc-n15"
  ),
  p.(
    [
      b.("Tip:"),
      t.(" Dolphin's "),
      b.("Continuous Scanning"),
      t.(
        " option (under Controllers) automatically reconnects Wii Remotes when they wake up, removing the need to re-pair each session."
      )
    ],
    "dc-p8"
  ),
  h.(2, "Per-Game Controller Profiles", "dc-h7"),
  p.(
    [
      t.(
        "Many games benefit from custom profiles. You can assign profiles per game by right-clicking a game → "
      ),
      b.("Properties → Game Config → Controller")
    ],
    "dc-p9"
  ),
  p.("Games that commonly need custom profiles:", "dc-p10"),
  bullet.(
    [
      b.("Super Mario Sunshine"),
      t.(" — Needs careful analog trigger mapping for water spray pressure")
    ],
    "dc-b17"
  ),
  bullet.(
    [b.("Metroid Prime Trilogy"), t.(" — IR pointer sensitivity and dead zone tuning")],
    "dc-b18"
  ),
  bullet.(
    [
      b.("The Legend of Zelda: Skyward Sword"),
      t.(" — Requires real Wii Remote + MotionPlus or very careful emulated mapping")
    ],
    "dc-b19"
  ),
  bullet.(
    [
      b.("Super Smash Bros. Melee"),
      t.(
        " — Competitive players need exact stick ranges and no input lag — consider a GameCube adapter"
      )
    ],
    "dc-b20"
  ),
  h.(2, "GameCube Adapter (Official / Mayflash)", "dc-h8"),
  p.(
    [
      t.("For the most authentic experience, use a "),
      b.("GameCube controller adapter"),
      t.(" (the official Wii U/Switch adapter or a Mayflash 4-port). Dolphin has native support:")
    ],
    "dc-p11"
  ),
  num.("Plug in the adapter (use both USB cables for full power)", "dc-n15b"),
  num.(
    [t.("In Controllers, set GameCube Port 1 to "), b.("GameCube Adapter for Wii U")],
    "dc-n16"
  ),
  num.("Plug in your GameCube controller — it should be detected immediately", "dc-n17"),
  num.("No mapping needed — Dolphin reads the native inputs directly", "dc-n18"),
  p.(
    [
      t.("On Windows, you may need to install "),
      b.("Zadig"),
      t.(" drivers if the adapter isn't detected. On Linux, add the appropriate udev rules.")
    ],
    "dc-p12"
  )
]

# --- UK Moto Roads ---

cat_and_fiddle_content = [
  h.(1, "Cat and Fiddle (A537)", "cf-h1"),
  p.(
    [
      t.("The "),
      b.("A537 Cat and Fiddle Road"),
      t.(
        " connects Macclesfield in Cheshire to Buxton in Derbyshire, cutting through the Peak District's wild moorland. At 516 metres above sea level, it's the second-highest A-road in England and one of the most famous motorcycle routes in the country."
      )
    ],
    "cf-p1"
  ),
  p.(
    [
      i.(
        "This road has a reputation. It's appeared regularly on road safety statistics due to its deceptive bends and exposed conditions. Ride it with respect — the scenery is worth savouring, not rushing."
      )
    ],
    "cf-p2"
  ),
  h.(2, "Route Overview", "cf-h2"),
  bullet.([b.("Start: "), t.("Macclesfield town centre (A537 junction)")], "cf-b1"),
  bullet.([b.("End: "), t.("Buxton town centre")], "cf-b2"),
  bullet.([b.("Distance: "), t.("12 miles (19 km)")], "cf-b3"),
  bullet.([b.("Estimated time: "), t.("25–35 minutes")], "cf-b4"),
  bullet.([b.("Summit elevation: "), t.("516m — second-highest A-road in England")], "cf-b5"),
  h.(2, "Directions", "cf-h3"),
  num.("Start in Macclesfield and pick up the A537 heading southeast toward Buxton", "cf-n1"),
  num.(
    "Climb out of town through suburban streets before the road opens up onto moorland",
    "cf-n2"
  ),
  num.(
    "Pass through a series of sweeping bends as you gain elevation — the road surface is generally good but watch for gravel on bends after rain",
    "cf-n3"
  ),
  num.(
    "At the summit you'll pass the Cat and Fiddle pub (one of the highest pubs in England) on your right",
    "cf-n4"
  ),
  num.(
    "Descend toward Buxton through a mix of fast sweepers and tighter bends with elevation changes",
    "cf-n5"
  ),
  num.("The road drops into Buxton — follow signs for the town centre", "cf-n6"),
  h.(2, "What Makes It Special", "cf-h4"),
  p.(
    "The Cat and Fiddle is all about the landscape. You ride up out of Macclesfield's valley through farmland and suddenly you're on exposed moorland with panoramic views in every direction. On a clear day the visibility is stunning — you can see across Cheshire to the Welsh hills.",
    "cf-p3"
  ),
  p.(
    "The road itself is a mix of fast flowing bends and tighter switchbacks, with constant elevation changes that keep you engaged. The surface is generally well-maintained, though the exposed sections can be damp or have standing water even when it hasn't rained locally.",
    "cf-p4"
  ),
  h.(2, "Hazards & Tips", "cf-h5"),
  bullet.(
    "Exposed moorland means crosswinds can be fierce — be prepared for gusts, especially at the summit",
    "cf-b6"
  ),
  bullet.(
    "Fog and low cloud are common, even in summer — visibility can drop to near zero very quickly",
    "cf-b7"
  ),
  bullet.("Average speed cameras cover the entire route — stick to the 50mph limit", "cf-b8"),
  bullet.("Watch for sheep on the road, particularly in spring and early summer", "cf-b9"),
  bullet.(
    "The descent into Buxton has some off-camber bends that tighten unexpectedly",
    "cf-b10"
  ),
  bullet.("Fuel up in Macclesfield or Buxton — no petrol stations on the route itself", "cf-b11"),
  h.(2, "Best Combined With", "cf-h6"),
  p.("The Cat and Fiddle works brilliantly as part of a longer Peak District loop:", "cf-p5"),
  bullet.(
    "Continue from Buxton to the A53 Leek Road for more great riding toward the Staffordshire Moorlands",
    "cf-b12"
  ),
  bullet.(
    "Head north from Buxton on the A6 to pick up the A623 and loop back via Castleton and the Hope Valley",
    "cf-b13"
  ),
  bullet.("Combine with Snake Pass (A57) for a full day Peak District circuit", "cf-b14")
]

snake_pass_content = [
  h.(1, "Snake Pass (A57)", "sn-h1"),
  p.(
    [
      t.("The "),
      b.("A57 Snake Pass"),
      t.(
        " is one of England's most iconic mountain roads, connecting Sheffield to Glossop across the northern Peak District. Named after the Snake Inn (which itself was named after the serpentine course of the River Ashop), it climbs to 512 metres at its summit and offers some of the most dramatic riding in northern England."
      )
    ],
    "sn-p1"
  ),
  h.(2, "Route Overview", "sn-h2"),
  bullet.([b.("Start: "), t.("Ladybower Reservoir (A57/A6013 junction)")], "sn-b1"),
  bullet.([b.("End: "), t.("Glossop town centre")], "sn-b2"),
  bullet.([b.("Distance: "), t.("14 miles (22 km)")], "sn-b3"),
  bullet.([b.("Estimated time: "), t.("25–40 minutes")], "sn-b4"),
  bullet.([b.("Summit elevation: "), t.("512m at Snake Summit")], "sn-b5"),
  h.(2, "Directions", "sn-h3"),
  num.(
    "From Sheffield, take the A57 west through the suburbs and past the Rivelin Valley",
    "sn-n1"
  ),
  num.(
    "Continue past the Ladybower Reservoir — consider a stop here as the viaduct views are excellent",
    "sn-n2"
  ),
  num.(
    "Pass the Snake Inn on your left and begin the climb through the Woodlands Valley",
    "sn-n3"
  ),
  num.("The road ascends steadily through open moorland with long, flowing bends", "sn-n4"),
  num.(
    "Cross the summit at Snake Pass (the A57's highest point) and begin the descent toward Glossop",
    "sn-n5"
  ),
  num.("The western descent features tighter bends and steeper gradients — stay alert", "sn-n6"),
  num.("Follow the road into Glossop where it joins the A626", "sn-n7"),
  h.(2, "What Makes It Special", "sn-h4"),
  p.(
    "Snake Pass is the complete package: a challenging road through genuinely wild, remote landscape. The eastern approach from Ladybower builds gradually — open, flowing bends alongside reservoirs and woodland. Then the character changes completely as you climb onto the moor and the landscape becomes bleak, treeless, and vast.",
    "sn-p2"
  ),
  p.(
    "The western descent into Glossop is the technical highlight — tighter, more demanding bends with limited visibility. The contrast between the two halves of the road makes it endlessly interesting.",
    "sn-p3"
  ),
  h.(2, "Hazards & Tips", "sn-h5"),
  bullet.(
    "Snake Pass is frequently closed in winter due to snow and ice — check road status before setting out",
    "sn-b6"
  ),
  bullet.(
    "The road surface can deteriorate after harsh winters, particularly on the western descent — watch for potholes",
    "sn-b7"
  ),
  bullet.(
    "High winds and sudden fog are common at the summit, even on otherwise pleasant days",
    "sn-b8"
  ),
  bullet.(
    "Popular with cyclists, especially at weekends — overtake with care on blind crests",
    "sn-b9"
  ),
  bullet.("No mobile signal for long stretches across the moor", "sn-b10"),
  bullet.(
    "The Glossop descent has several drainage channels cut across the road that can unsettle the bike",
    "sn-b11"
  ),
  h.(2, "Best Combined With", "sn-h6"),
  p.("Snake Pass pairs perfectly with other Peak District routes:", "sn-p4"),
  bullet.("Loop back via Woodhead Pass (A628) for a wilder, more remote return route", "sn-b12"),
  bullet.(
    "Head south from Ladybower to ride the A6187 through the Hope Valley — gentler but beautiful",
    "sn-b13"
  ),
  bullet.("Combine with the Cat and Fiddle for a complete Peak District day ride", "sn-b14")
]

hardknott_pass_content = [
  h.(1, "Hardknott Pass", "hk-h1"),
  p.(
    [
      t.("The "),
      b.("Hardknott Pass"),
      t.(
        " in the Lake District is the steepest road pass in England, with gradients reaching 1-in-3 (33%). Connecting Eskdale to the Duddon Valley, this single-track road with hairpin bends is a genuine challenge on two wheels — and one of the most thrilling rides in the UK."
      )
    ],
    "hk-p1"
  ),
  p.(
    [
      i.(
        "This is not a road for beginners or heavy touring bikes loaded with luggage. It demands confidence, clutch control, and respect for the gradient. If that sounds like your kind of riding, it's absolutely unforgettable."
      )
    ],
    "hk-p2"
  ),
  h.(2, "Route Overview", "hk-h2"),
  bullet.([b.("Start: "), t.("Boot, Eskdale (western approach)")], "hk-b1"),
  bullet.([b.("End: "), t.("Cockley Beck, Duddon Valley (eastern side)")], "hk-b2"),
  bullet.([b.("Distance: "), t.("3 miles (5 km) for the pass itself")], "hk-b3"),
  bullet.([b.("Estimated time: "), t.("15–25 minutes (seriously)")], "hk-b4"),
  bullet.([b.("Maximum gradient: "), t.("33% (1-in-3)")], "hk-b5"),
  bullet.([b.("Summit elevation: "), t.("393m")], "hk-b6"),
  h.(2, "Directions", "hk-h3"),
  num.(
    "From the west, head to Boot in Eskdale via the minor road from Holmrook on the A595",
    "hk-n1"
  ),
  num.(
    "Follow signs for Hardknott Pass — the road narrows to single track almost immediately",
    "hk-n2"
  ),
  num.(
    "The ascent begins gently before hitting the first set of hairpins — these are tight, steep, and on rough tarmac",
    "hk-n3"
  ),
  num.(
    "Continue climbing through three major hairpin sections — use first gear and keep momentum",
    "hk-n4"
  ),
  num.(
    "At the summit, stop to visit the Roman fort ruins (Hardknott Castle) and take in the views down to Eskdale",
    "hk-n5"
  ),
  num.(
    "The eastern descent into the Duddon Valley is less severe but still steep with loose surfaces",
    "hk-n6"
  ),
  num.(
    "At Cockley Beck you can continue east to connect with Wrynose Pass for a double-pass experience",
    "hk-n7"
  ),
  h.(2, "What Makes It Special", "hk-h4"),
  p.(
    "Hardknott is a road that makes you feel like you've genuinely achieved something. The hairpin bends on the western ascent are outrageously steep — you look up at the road above you and wonder how anything with wheels is supposed to get up there. But when you reach the summit and look back down the valley toward the coast, the sense of accomplishment is real.",
    "hk-p3"
  ),
  p.(
    "The Roman fort at the top (Mediobogdum) is a remarkable bonus — the Romans built a garrison here 2,000 years ago, and the foundations are still visible. The views from the fort toward the Scafell range are among the finest in the Lake District.",
    "hk-p4"
  ),
  h.(2, "Hazards & Tips", "hk-h5"),
  bullet.(
    [
      b.("Gradient: "),
      t.(
        "33% sections demand first gear and careful clutch control — do not stall on the steep hairpins"
      )
    ],
    "hk-b7"
  ),
  bullet.(
    "Single track with passing places — always be prepared to stop for oncoming traffic, including campervans that shouldn't really be there",
    "hk-b8"
  ),
  bullet.(
    "Road surface is rough and patchy, with loose gravel in places — avoid aggressive lean angles",
    "hk-b9"
  ),
  bullet.(
    "If it's wet, the steepest sections become genuinely treacherous — consider postponing",
    "hk-b10"
  ),
  bullet.("No barriers on cliff edges — concentration is not optional", "hk-b11"),
  bullet.(
    "Carry water and snacks — the nearest shop is in Boot and there's nothing on the pass",
    "hk-b12"
  ),
  h.(2, "Best Combined With", "hk-h6"),
  p.(
    [
      t.("Hardknott is almost always ridden together with "),
      b.("Wrynose Pass"),
      t.(
        " immediately to the east. Together they form a continuous 7-mile stretch of mountain road between Eskdale and the A593 near Ambleside. The combination is one of the best riding experiences in England."
      )
    ],
    "hk-p5"
  ),
  bullet.(
    "Wrynose Pass eastbound from Cockley Beck leads to Little Langdale and Ambleside",
    "hk-b13"
  ),
  bullet.("Return via the A593 and A595 along the coast for a relaxed contrast ride", "hk-b14"),
  bullet.("Add the Kirkstone Pass (A592) for a Lake District triple-pass day", "hk-b15")
]

black_mountain_content = [
  h.(1, "Black Mountain Pass (A4069)", "bm-h1"),
  p.(
    [
      t.("The "),
      b.("A4069 Black Mountain Pass"),
      t.(
        " in Carmarthenshire is widely considered the finest motorcycle road in Wales. Sweeping through the western edge of the Brecon Beacons (now Bannau Brycheiniog), it climbs over the Black Mountain with perfectly sighted bends, superb tarmac, and the kind of views that make you want to turn around and ride it again immediately."
      )
    ],
    "bm-p1"
  ),
  h.(2, "Route Overview", "bm-h2"),
  bullet.([b.("Start: "), t.("Llangadog (junction with A40)")], "bm-b1"),
  bullet.([b.("End: "), t.("Brynamman")], "bm-b2"),
  bullet.([b.("Distance: "), t.("15 miles (24 km)")], "bm-b3"),
  bullet.([b.("Estimated time: "), t.("25–35 minutes")], "bm-b4"),
  bullet.([b.("Summit elevation: "), t.("493m")], "bm-b5"),
  h.(2, "Directions", "bm-h3"),
  num.("From Llangadog on the A40, turn south onto the A4069 signed for Brynamman", "bm-n1"),
  num.(
    "The first few miles are gentle — rolling farmland with good visibility and easy bends",
    "bm-n2"
  ),
  num.(
    "The road begins to climb as the landscape opens up, with the Black Mountain escarpment rising to the east",
    "bm-n3"
  ),
  num.(
    "A series of perfectly flowing sweepers carry you up the mountainside — this is the section that made the road famous",
    "bm-n4"
  ),
  num.(
    "At the summit, the road crosses open moorland with views across to the Towy Valley and beyond",
    "bm-n5"
  ),
  num.(
    "The southern descent toward Brynamman is slightly more technical with some tighter bends and steeper gradients",
    "bm-n6"
  ),
  num.(
    "Drop into Brynamman where you can pick up the A474 to loop back or continue south toward Swansea",
    "bm-n7"
  ),
  h.(2, "What Makes It Special", "bm-h4"),
  p.(
    "The Black Mountain Pass is that rare thing: a road that seems designed for motorcycles. The bends are well-sighted with progressive radii, the surface is excellent, the gradient changes are smooth, and the traffic is usually light. It flows beautifully — you settle into a rhythm and the bike and road just work together.",
    "bm-p2"
  ),
  p.(
    [
      t.(
        "The scenery helps too. The northern approach through the Towy Valley is classically Welsh — green fields, hedgerows, stone walls. Then as you climb, it transforms into something much wilder. At the summit you're riding across open mountain with "
      ),
      b.("Llyn y Fan Fach"),
      t.(
        " (a glacial lake) tucked into the escarpment below, and views stretching to the Gower Peninsula on clear days."
      )
    ],
    "bm-p3"
  ),
  h.(2, "Hazards & Tips", "bm-h5"),
  bullet.(
    "Livestock on the road — sheep and occasionally ponies graze freely on the mountain sections",
    "bm-b6"
  ),
  bullet.(
    "The southern descent can surprise you after the gentle northern approach — the bends tighten and the gradient steepens",
    "bm-b7"
  ),
  bullet.("Exposed at the summit, so crosswinds and rain can arrive without warning", "bm-b8"),
  bullet.(
    "Popular with sports cars and cyclists at weekends — ride considerately, this road has a good reputation and we'd like to keep it",
    "bm-b9"
  ),
  bullet.(
    "No speed cameras but there are occasional police presence on sunny weekends",
    "bm-b10"
  ),
  bullet.("Fuel available in Llangadog and Brynamman — nothing on the mountain", "bm-b11"),
  h.(2, "Best Combined With", "bm-h6"),
  p.("The A4069 is excellent on its own but even better as part of a loop:", "bm-p4"),
  bullet.(
    "Head east from Llangadog on the A40 to pick up the A470 through the Brecon Beacons — the Storey Arms section is another classic",
    "bm-b12"
  ),
  bullet.(
    "Loop west from Brynamman via the A474 and A48 to ride the Gower Peninsula coastal roads",
    "bm-b13"
  ),
  bullet.(
    "Combine with the Devil's Staircase (A4069 continuation south) for a full day of Welsh mountain riding",
    "bm-b14"
  )
]

bealach_na_ba_content = [
  h.(1, "Bealach na Ba", "bn-h1"),
  p.(
    [
      t.("The "),
      b.("Bealach na Ba"),
      t.(
        " (Pass of the Cattle) on the Applecross Peninsula in the Scottish Highlands is the greatest road in Britain. That's not hyperbole — this single-track pass climbs to 626 metres with Alpine-style hairpins, sheer drops, and views that stretch to the Isle of Skye and the Outer Hebrides. It is utterly magnificent."
      )
    ],
    "bn-p1"
  ),
  p.(
    [
      i.(
        "This is a bucket-list ride. If you only ever ride one road in the UK, make it this one."
      )
    ],
    "bn-p2"
  ),
  h.(2, "Route Overview", "bn-h2"),
  bullet.([b.("Start: "), t.("Tornapress (junction at A896)")], "bn-b1"),
  bullet.([b.("End: "), t.("Applecross village")], "bn-b2"),
  bullet.([b.("Distance: "), t.("11 miles (18 km)")], "bn-b3"),
  bullet.([b.("Estimated time: "), t.("30–50 minutes")], "bn-b4"),
  bullet.([b.("Summit elevation: "), t.("626m — highest road climb in the UK")], "bn-b5"),
  h.(2, "Directions", "bn-h3"),
  num.("From Inverness, take the A835 northwest to Garve, then the A832 to Achnasheen", "bn-n1"),
  num.("Continue on the A890 to Lochcarron, then follow the A896 south toward Kishorn", "bn-n2"),
  num.(
    "At Tornapress, ignore the coastal road and take the unclassified road signed for Applecross via the Bealach na Ba",
    "bn-n3"
  ),
  num.(
    "The ascent begins immediately — steep, narrow, and single-track with passing places",
    "bn-n4"
  ),
  num.(
    "Climb through a series of tight hairpins carved into the mountainside, with sheer drops to your left",
    "bn-n5"
  ),
  num.(
    "The gradient eases near the summit where a car park offers panoramic views — stop here, it's mandatory",
    "bn-n6"
  ),
  num.(
    "The descent into Applecross is more gradual, winding down through moorland to the village and the sea",
    "bn-n7"
  ),
  h.(2, "What Makes It Special", "bn-h4"),
  p.(
    "The Bealach na Ba is in a different league to anything else in the UK. The eastern ascent from Tornapress feels genuinely Alpine — tight switchbacks climbing a steep mountain face with nothing but a low stone wall between you and a very long drop. The road was built in 1822 and it shows — it follows the contours of the mountain rather than blasting through them, which gives it an organic, dramatic character that engineered roads simply don't have.",
    "bn-p3"
  ),
  p.(
    "At the summit, the views are staggering. On a clear day you can see Skye, Raasay, the Torridon mountains, and all the way to the Outer Hebrides. The descent into Applecross opens up with the sea stretching out below you, and the village itself is a perfect endpoint — a tiny coastal settlement with an excellent inn (the Applecross Inn) serving fresh local seafood.",
    "bn-p4"
  ),
  h.(2, "Hazards & Tips", "bn-h5"),
  bullet.(
    [
      b.("Single track throughout"),
      t.(
        " — use passing places properly, pull left to let faster traffic past, and never park in a passing place"
      )
    ],
    "bn-b6"
  ),
  bullet.(
    "The eastern ascent hairpins are very tight — first gear on some of them, and watch for gravel on the inside of bends",
    "bn-b7"
  ),
  bullet.(
    "No barriers on the cliff edges during the ascent — if this bothers you, you'll want to know in advance",
    "bn-b8"
  ),
  bullet.(
    "Cloud and mist can completely obscure the summit — the road becomes very difficult to read in poor visibility",
    "bn-b9"
  ),
  bullet.(
    "The road is closed in severe winter weather — check the Highland Council road status page before travelling",
    "bn-b10"
  ),
  bullet.(
    "Allow time — rushing the Bealach is both dangerous and pointless. The ride is the destination",
    "bn-b11"
  ),
  bullet.(
    "Fuel up in Lochcarron — the nearest petrol after that is Applecross (limited hours) or back in Lochcarron",
    "bn-b12"
  ),
  h.(2, "Best Combined With", "bn-h6"),
  p.("The Applecross Peninsula makes a perfect day ride:", "bn-p5"),
  bullet.(
    "After descending to Applecross, take the coastal road north around the peninsula via Toscaig and Kenmore — slower but spectacularly beautiful",
    "bn-b13"
  ),
  bullet.(
    "The coastal road eventually rejoins the A896 at Shieldaig — continue to Torridon for more jaw-dropping Highland scenery",
    "bn-b14"
  ),
  bullet.(
    "Combine with the A896 through Glen Torridon and the A832 to Gairloch for a full day of the best roads in Scotland",
    "bn-b15"
  ),
  bullet.(
    "The NC500 (North Coast 500) passes nearby — the Bealach na Ba is the essential detour that most NC500 riders add to the route",
    "bn-b16"
  )
]

# Helper to split block arrays into sections by h1/h2 headings
# Heading blocks are included in section content for seamless rendering
split_into_sections = fn blocks ->
  {sections, current_blocks} =
    Enum.reduce(blocks, {[], []}, fn block, {sections, acc} ->
      if block["type"] == "heading" and get_in(block, ["props", "level"]) in [1, 2] do
        if acc == [] do
          {sections, [block]}
        else
          {sections ++ [Enum.reverse(acc)], [block]}
        end
      else
        {sections, [block | acc]}
      end
    end)

  sections ++ [Enum.reverse(current_blocks)]
end

communities = [
  %{
    name: "TriumphMotorcycles",
    description: "Community for Triumph motorcycle enthusiasts",
    icon:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Logo_Triumph.svg/500px-Logo_Triumph.svg.png",
    pages: [
      %{title: "Trident 660", slug: "trident-660", blocks: trident_content}
    ]
  },
  %{
    name: "SteamDeck",
    description: "Valve's handheld gaming PC",
    icon:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Steam_Deck_colored_logo.svg/500px-Steam_Deck_colored_logo.svg.png",
    pages: [
      %{title: "Getting Started", slug: "getting-started", blocks: steam_getting_started},
      %{title: "Performance Tweaks", slug: "performance-tweaks", blocks: steam_performance}
    ]
  },
  %{
    name: "ROGAllyX",
    description: "ASUS ROG Ally X handheld gaming device",
    icon:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/ASUS_ROG_logo.svg/500px-ASUS_ROG_logo.svg.png",
    pages: [
      %{title: "Overview", slug: "overview", blocks: rog_overview},
      %{title: "Best Settings", slug: "best-settings", blocks: rog_settings}
    ]
  },
  %{
    name: "PS5",
    description: "Sony PlayStation 5 console",
    icon:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/PlayStation_logo.svg/500px-PlayStation_logo.svg.png",
    pages: [
      %{title: "Tips & Tricks", slug: "tips-and-tricks", blocks: ps5_tips}
    ]
  },
  %{
    name: "RetroidPocket5",
    description: "Retroid Pocket 5 retro gaming handheld",
    icon:
      "https://www.goretroid.com/cdn/shop/files/retroid-pocket-logo_6f5cc0c8-a40f-48f7-a55f-4b8539141659_300x300.png?v=1613577578",
    pages: [
      %{title: "Setup Guide", slug: "setup-guide", blocks: retroid_setup}
    ]
  },
  %{
    name: "DolphinEmulator",
    description: "GameCube and Wii emulator",
    icon:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Dolphin_Emulator_Logo_Refresh.svg/500px-Dolphin_Emulator_Logo_Refresh.svg.png",
    collections: ["Setup"],
    pages: [
      %{
        title: "Installation",
        slug: "installation",
        blocks: dolphin_install,
        collection: "Setup"
      },
      %{
        title: "Controller Configuration",
        slug: "controller-configuration",
        blocks: dolphin_controller,
        collection: "Setup"
      }
    ]
  },
  %{
    name: "UkMotoRoads",
    description: "The best twisty motorcycle roads in the UK",
    collections: ["England", "Wales & Scotland"],
    pages: [
      %{
        title: "Cat and Fiddle (A537)",
        slug: "cat-and-fiddle",
        blocks: cat_and_fiddle_content,
        collection: "England"
      },
      %{
        title: "Snake Pass (A57)",
        slug: "snake-pass",
        blocks: snake_pass_content,
        collection: "England"
      },
      %{
        title: "Hardknott Pass",
        slug: "hardknott-pass",
        blocks: hardknott_pass_content,
        collection: "England"
      },
      %{
        title: "Black Mountain Pass (A4069)",
        slug: "black-mountain-pass",
        blocks: black_mountain_content,
        collection: "Wales & Scotland"
      },
      %{
        title: "Bealach na Ba",
        slug: "bealach-na-ba",
        blocks: bealach_na_ba_content,
        collection: "Wales & Scotland"
      }
    ]
  }
]

# --- Create Users ---

create_user = fn email, nickname, password ->
  %User{}
  |> User.registration_changeset(%{email: email, nickname: nickname}, validate_unique: false)
  |> User.password_changeset(%{password: password})
  |> Repo.insert!()
end

admin = create_user.("admin@atlas.local", "admin", "password123456")

fake_users = [
  create_user.("alex.chen@example.com", "alexchen", "password123456"),
  create_user.("maria.santos@example.com", "mariasantos", "password123456"),
  create_user.("james.wilson@example.com", "jameswilson", "password123456"),
  create_user.("priya.patel@example.com", "priyapatel", "password123456"),
  create_user.("liam.oconnor@example.com", "liamoconnor", "password123456"),
  create_user.("yuki.tanaka@example.com", "yukitanaka", "password123456"),
  create_user.("emma.johnson@example.com", "emmajohnson", "password123456"),
  create_user.("carlos.rivera@example.com", "carlosrivera", "password123456"),
  create_user.("sofia.andersson@example.com", "sofiaandersson", "password123456"),
  create_user.("omar.hassan@example.com", "omarhassan", "password123456"),
  create_user.("nina.kowalski@example.com", "ninakowalski", "password123456"),
  create_user.("david.kim@example.com", "davidkim", "password123456"),
  create_user.("ava.thompson@example.com", "avathompson", "password123456"),
  create_user.("lucas.martin@example.com", "lucasmartin", "password123456"),
  create_user.("zara.ahmed@example.com", "zaraahmed", "password123456")
]

all_users = [admin | fake_users]

IO.puts("Seeded #{length(all_users)} users.")

# Assign owners to communities (spread across users)
owner_assignments = %{
  "TriumphMotorcycles" => Enum.at(fake_users, 0),
  "SteamDeck" => Enum.at(fake_users, 2),
  "ROGAllyX" => Enum.at(fake_users, 4),
  "PS5" => Enum.at(fake_users, 6),
  "RetroidPocket5" => Enum.at(fake_users, 8),
  "DolphinEmulator" => Enum.at(fake_users, 10),
  "UkMotoRoads" => Enum.at(fake_users, 12)
}

# Member counts per community (for organic-looking distribution)
member_counts = %{
  "TriumphMotorcycles" => 8,
  "SteamDeck" => 14,
  "ROGAllyX" => 10,
  "PS5" => 12,
  "RetroidPocket5" => 6,
  "DolphinEmulator" => 9,
  "UkMotoRoads" => 11
}

for community_data <- communities do
  {pages_data, community_attrs} = Map.pop(community_data, :pages)
  {collections_data, community_attrs} = Map.pop(community_attrs, :collections, [])
  name = community_attrs[:name]
  owner = Map.fetch!(owner_assignments, name)

  community_attrs = Map.put(community_attrs, :owner_id, owner.id)
  community = Repo.insert!(%Community{} |> Community.changeset(Map.new(community_attrs)))

  # Create collections
  collections_map =
    collections_data
    |> Enum.with_index()
    |> Enum.map(fn {coll_name, idx} ->
      collection =
        Repo.insert!(
          %Collection{}
          |> Collection.changeset(%{name: coll_name, sort_order: idx, community_id: community.id})
        )

      {coll_name, collection}
    end)
    |> Map.new()

  for page_data <- pages_data do
    {blocks, page_attrs} = Map.pop(page_data, :blocks, [])
    {collection_name, page_attrs} = Map.pop(page_attrs, :collection)

    collection_id =
      if collection_name, do: Map.fetch!(collections_map, collection_name).id, else: nil

    page_attrs =
      page_attrs
      |> Map.put(:community_id, community.id)
      |> Map.put(:owner_id, owner.id)
      |> Map.put(:collection_id, collection_id)

    page = Repo.insert!(%Page{} |> Page.changeset(Map.new(page_attrs)))

    # Split blocks into sections by h1/h2 headings
    sections = split_into_sections.(blocks)

    sections
    |> Enum.with_index()
    |> Enum.each(fn {content, idx} ->
      Repo.insert!(
        %Section{}
        |> Section.changeset(%{
          content: content,
          sort_order: idx,
          page_id: page.id
        })
      )
    end)
  end

  # Add owner as member
  Repo.insert!(
    %CommunityMember{}
    |> CommunityMember.changeset(%{user_id: owner.id, community_id: community.id})
  )

  # Add admin as member
  if admin.id != owner.id do
    Repo.insert!(
      %CommunityMember{}
      |> CommunityMember.changeset(%{user_id: admin.id, community_id: community.id})
    )
  end

  # Add random fake users as members
  target_count = Map.fetch!(member_counts, name)
  remaining_users = Enum.reject(fake_users, fn u -> u.id == owner.id end)

  members_to_add =
    remaining_users
    |> Enum.shuffle()
    |> Enum.take(target_count - 2)

  for user <- members_to_add do
    if user.id != admin.id do
      Repo.insert!(
        %CommunityMember{}
        |> CommunityMember.changeset(%{user_id: user.id, community_id: community.id})
      )
    end
  end
end

# Add stars to pages
all_pages = Repo.all(Page)
all_users = [admin | fake_users]

for page <- all_pages do
  stargazers =
    all_users
    |> Enum.shuffle()
    |> Enum.take(Enum.random(1..8))

  for user <- stargazers do
    Repo.insert!(
      %PageStar{}
      |> PageStar.changeset(%{user_id: user.id, page_id: page.id})
    )
  end
end

# Add comments to pages
comment_pool = [
  "Great page! Very informative and well-organized.",
  "This could use some more detail on the specs.",
  "Thanks for putting this together, exactly what I was looking for.",
  "I think some of this info might be outdated, can someone verify?",
  "Bookmarked this for future reference.",
  "Would love to see a comparison section added here.",
  "The community really needs more pages like this one.",
  "Has anyone tested these claims firsthand?",
  "Minor nitpick but the formatting in the middle section is a bit off.",
  "Solid write-up, learned a lot from this.",
  "Can we get some images or diagrams added?",
  "This is the best resource on this topic I've found so far.",
  "I disagree with some of the conclusions here, but good effort overall.",
  "Is there a follow-up page planned for this topic?",
  "Really helpful for newcomers to the community."
]

reply_pool = [
  "Agreed, this is really well done.",
  "Good point, I was thinking the same thing.",
  "I can confirm this is accurate from my experience.",
  "Thanks for flagging that, I'll look into it.",
  "I second this, would be a great addition.",
  "+1, that would make this page even better.",
  "Not sure I agree, but I see where you're coming from.",
  "Great suggestion, someone should propose an edit.",
  "Yeah I noticed that too, hopefully it gets updated soon.",
  "Absolutely, this has been super useful."
]

for page <- all_pages do
  # 2-5 top-level comments per page
  num_comments = Enum.random(2..5)
  commenters = all_users |> Enum.shuffle() |> Enum.take(num_comments)

  for {user, idx} <- Enum.with_index(commenters) do
    comment =
      Repo.insert!(
        %PageComment{}
        |> PageComment.changeset(%{
          body: Enum.at(comment_pool, rem(idx + page.id, length(comment_pool))),
          page_id: page.id,
          author_id: user.id
        })
      )

    # ~50% chance of 1-2 replies on each top-level comment
    if Enum.random(0..1) == 1 do
      num_replies = Enum.random(1..2)

      repliers =
        all_users |> Enum.reject(&(&1.id == user.id)) |> Enum.shuffle() |> Enum.take(num_replies)

      for {replier, r_idx} <- Enum.with_index(repliers) do
        Repo.insert!(
          %PageComment{}
          |> PageComment.changeset(%{
            body: Enum.at(reply_pool, rem(r_idx + comment.id, length(reply_pool))),
            page_id: page.id,
            author_id: replier.id,
            parent_id: comment.id
          })
        )
      end
    end
  end
end

IO.puts(
  "Seeded #{length(communities)} communities with pages, owners, members, stars, and comments."
)
