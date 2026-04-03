defmodule AtlasWeb.NotFoundLive do
  use AtlasWeb, :live_view

  @messages [
    "This page wandered off the map. Even Atlas can't find it.",
    "You've reached the edge of the known world. Here be dragons.",
    "Plot twist: the real 404 was the friends we made along the way.",
    "This page is taking a gap year. It'll be back... probably.",
    "Looks like this page pulled an Atlantis and sank into the ocean.",
    "The page you seek has transcended to a higher plane of existence.",
    "Error 404: Page not found. Blame the intern. (We don't have an intern.)"
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Page Not Found", message: Enum.random(@messages))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-[60vh] text-center px-4">
      <div class="relative mb-2">
        <%!-- Shipwrecked pirate cat --%>
        <svg
          width="240"
          height="200"
          viewBox="0 0 240 200"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <%!-- Waves background --%>
          <g class="fill-info/10">
            <path d="M0 155 Q20 148, 40 155 Q60 162, 80 155 Q100 148, 120 155 Q140 162, 160 155 Q180 148, 200 155 Q220 162, 240 155 L240 200 L0 200 Z">
              <animateTransform
                attributeName="transform"
                type="translate"
                values="0 0; -5 2; 0 0; 5 -1; 0 0"
                dur="4s"
                repeatCount="indefinite"
              />
            </path>
          </g>
          <g class="fill-info/15">
            <path d="M0 165 Q30 158, 60 165 Q90 172, 120 165 Q150 158, 180 165 Q210 172, 240 165 L240 200 L0 200 Z">
              <animateTransform
                attributeName="transform"
                type="translate"
                values="0 0; 6 1; 0 0; -4 -1; 0 0"
                dur="5s"
                repeatCount="indefinite"
              />
            </path>
          </g>
          <%!-- Driftwood --%>
          <g>
            <animateTransform
              attributeName="transform"
              type="rotate"
              values="-2 120 150; 2 120 150; -2 120 150"
              dur="4s"
              repeatCount="indefinite"
            />
            <%!-- Main plank --%>
            <rect
              x="55"
              y="140"
              width="130"
              height="14"
              rx="4"
              class="fill-amber-800/30 stroke-amber-800/40"
              stroke-width="1.5"
            />
            <%!-- Wood grain --%>
            <line x1="70" y1="144" x2="90" y2="144" class="stroke-amber-800/20" stroke-width="1" />
            <line x1="100" y1="148" x2="140" y2="148" class="stroke-amber-800/20" stroke-width="1" />
            <line x1="150" y1="144" x2="170" y2="144" class="stroke-amber-800/20" stroke-width="1" />
            <%!-- Mast (broken stick) --%>
            <line
              x1="155"
              y1="142"
              x2="160"
              y2="60"
              class="stroke-amber-800/40"
              stroke-width="3"
              stroke-linecap="round"
            />
            <%!-- Torn sail / flag --%>
            <path
              d="M160 62 L195 70 L190 95 Q180 90, 170 97 L162 100"
              class="fill-base-content/8 stroke-base-content/20"
              stroke-width="1"
            >
              <animate
                attributeName="d"
                values="M160 62 L195 70 L190 95 Q180 90, 170 97 L162 100;M160 62 L193 72 L188 95 Q179 88, 170 96 L162 100;M160 62 L195 70 L190 95 Q180 90, 170 97 L162 100"
                dur="3s"
                repeatCount="indefinite"
              />
            </path>
            <%!-- 404 on the sail --%>
            <text
              x="170"
              y="87"
              font-size="12"
              font-weight="bold"
              font-family="sans-serif"
              class="fill-base-content/25"
              transform="rotate(5, 170, 87)"
            >
              404
            </text>
            <%!-- Cat body sitting on plank --%>
            <ellipse
              cx="105"
              cy="133"
              rx="18"
              ry="14"
              class="fill-amber-200/50 stroke-amber-400/40"
              stroke-width="1.5"
            />
            <%!-- Cat head --%>
            <circle
              cx="105"
              cy="108"
              r="18"
              class="fill-amber-200/50 stroke-amber-400/40"
              stroke-width="1.5"
            />
            <%!-- Ears --%>
            <path
              d="M90 95 L87 78 L98 90"
              class="fill-amber-200/50 stroke-amber-400/40"
              stroke-width="1.5"
              stroke-linejoin="round"
            />
            <path
              d="M120 95 L123 78 L112 90"
              class="fill-amber-200/50 stroke-amber-400/40"
              stroke-width="1.5"
              stroke-linejoin="round"
            />
            <%!-- Inner ears --%>
            <path d="M91 94 L89 82 L97 91" class="fill-pink-300/30" />
            <path d="M119 94 L121 82 L113 91" class="fill-pink-300/30" />
            <%!-- Eyes (X X — dazed) --%>
            <g class="stroke-base-content/50" stroke-width="2" stroke-linecap="round">
              <line x1="95" y1="103" x2="101" y2="109" />
              <line x1="101" y1="103" x2="95" y2="109" />
              <line x1="109" y1="103" x2="115" y2="109" />
              <line x1="115" y1="103" x2="109" y2="109" />
            </g>
            <%!-- Nose --%>
            <ellipse cx="105" cy="114" rx="2.5" ry="2" class="fill-pink-400/50" />
            <%!-- Mouth --%>
            <path
              d="M100 116 Q105 120, 110 116"
              class="stroke-base-content/30"
              stroke-width="1.5"
              fill="none"
              stroke-linecap="round"
            />
            <%!-- Whiskers --%>
            <g class="stroke-base-content/20" stroke-width="1" stroke-linecap="round">
              <line x1="88" y1="112" x2="74" y2="110" />
              <line x1="88" y1="115" x2="74" y2="116" />
              <line x1="122" y1="112" x2="136" y2="110" />
              <line x1="122" y1="115" x2="136" y2="116" />
            </g>
            <%!-- Pirate bandana --%>
            <path
              d="M87 96 Q90 86, 105 85 Q120 86, 123 96"
              class="fill-error/30 stroke-error/40"
              stroke-width="1.5"
            />
            <%!-- Bandana knot --%>
            <path
              d="M123 94 L132 90 M123 94 L130 99"
              class="stroke-error/40"
              stroke-width="2"
              stroke-linecap="round"
            />
            <%!-- Bandana dots --%>
            <circle cx="100" cy="91" r="1.5" class="fill-white/40" />
            <circle cx="110" cy="90" r="1.5" class="fill-white/40" />
            <%!-- Front paws gripping the plank --%>
            <ellipse
              cx="88"
              cy="143"
              rx="6"
              ry="4"
              class="fill-amber-200/50 stroke-amber-400/40"
              stroke-width="1"
            />
            <ellipse
              cx="122"
              cy="143"
              rx="6"
              ry="4"
              class="fill-amber-200/50 stroke-amber-400/40"
              stroke-width="1"
            />
            <%!-- Tail (soggy, hanging off the side) --%>
            <path
              d="M87 135 Q65 130, 58 140 Q55 148, 60 150"
              class="stroke-amber-400/40"
              stroke-width="3"
              fill="none"
              stroke-linecap="round"
            >
              <animate
                attributeName="d"
                values="M87 135 Q65 130, 58 140 Q55 148, 60 150;M87 135 Q65 132, 58 142 Q55 150, 62 151;M87 135 Q65 130, 58 140 Q55 148, 60 150"
                dur="4s"
                repeatCount="indefinite"
              />
            </path>
          </g>
          <%!-- Water drips from cat --%>
          <g class="fill-info/30">
            <circle r="2" cx="95" cy="130">
              <animate
                attributeName="cy"
                values="130;155;155"
                dur="3s"
                repeatCount="indefinite"
              />
              <animate
                attributeName="opacity"
                values="0.6;0;0"
                dur="3s"
                repeatCount="indefinite"
              />
            </circle>
            <circle r="1.5" cx="115" cy="125">
              <animate
                attributeName="cy"
                values="125;155;155"
                dur="2.5s"
                repeatCount="indefinite"
              />
              <animate
                attributeName="opacity"
                values="0.6;0;0"
                dur="2.5s"
                repeatCount="indefinite"
              />
            </circle>
          </g>
          <%!-- Tiny floating bubbles --%>
          <g class="fill-info/20">
            <circle r="3" cx="45" cy="170">
              <animate attributeName="cy" values="170;158;170" dur="3s" repeatCount="indefinite" />
            </circle>
            <circle r="2" cx="200" cy="168">
              <animate attributeName="cy" values="168;160;168" dur="4s" repeatCount="indefinite" />
            </circle>
          </g>
        </svg>
      </div>
      <p class="text-[8rem] leading-none font-bold text-base-content/10 select-none">404</p>
      <p class="text-lg text-base-content/60 max-w-md mt-2 mb-8">{@message}</p>
      <.link navigate={~p"/"} class="btn btn-primary rounded-full">
        Take Me Home
      </.link>
    </div>
    """
  end
end
