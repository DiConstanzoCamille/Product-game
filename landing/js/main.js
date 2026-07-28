const DATA_DIR = "../data/";

async function loadJSON(file) {
  const res = await fetch(DATA_DIR + file);
  if (!res.ok) throw new Error(`Impossible de charger ${file} (${res.status})`);
  return res.json();
}

function el(html) {
  const template = document.createElement("template");
  template.innerHTML = html.trim();
  return template.content.firstElementChild;
}

/* ---------- RESOURCES + TENSIONS + HUD ---------- */

function renderResources(resources) {
  const grid = document.getElementById("resource-grid");
  grid.innerHTML = resources
    .map(
      (r) => `
    <div class="resource-card">
      <div class="resource-icon">${r.icon}</div>
      <div class="resource-name">${r.name}</div>
      <p class="resource-def">${r.definition}</p>
      <div class="resource-drivers">
        <div><span class="k">Monte</span> — ${r.rises.join(", ")}</div>
        <div><span class="k">Descend</span> — ${r.falls.join(", ")}</div>
      </div>
      <p class="resource-zero">${r.extreme.condition} → ${r.extreme.outcome}</p>
    </div>`
    )
    .join("");
}

function renderTensions(tensions) {
  const list = document.getElementById("tension-list");
  list.innerHTML = tensions
    .map((t) => `<div class="tension-item">⚖️ <span>${t.description}</span></div>`)
    .join("");
}

function renderHud(hud) {
  const hudEl = document.getElementById("hud");
  hudEl.innerHTML = `
    <div class="hud-top">
      <span class="hud-era">${hud.era}</span>
      <span class="hud-sprint">CPO : ${hud.cpo}</span>
    </div>
    <div class="hud-gauges">
      ${hud.gauges
        .map(
          (g) => `
        <div class="gauge">
          <div class="gauge-top"><span class="gauge-label">${g.label}</span><span class="gauge-value ${g.state === "good" ? "good" : "bad"}">${g.display}</span></div>
          <div class="gauge-bar"><div class="gauge-fill ${g.state === "good" ? "" : g.state}" style="width:${g.percent}%"></div></div>
        </div>`
        )
        .join("")}
    </div>
    <div class="hud-journal">
      <div class="hud-journal-title">Journal du sprint</div>
      ${hud.journal
        .map(
          (j) => `<div class="journal-entry">Sprint ${j.sprint} — ${j.text}<div class="journal-deltas">${j.deltas}</div></div>`
        )
        .join("")}
    </div>
    <div class="hud-alert">${hud.alert}</div>
  `;
}

/* ---------- CARDS (RICE / Notion / Jira) ---------- */

let cardsData = null;
let currentTeam = "junior";

function renderCards() {
  const grid = document.getElementById("cards-grid");
  grid.innerHTML = cardsData.cards
    .map(
      (card) => `
    <div class="card-flip" data-card="${card.id}" tabindex="0" role="button" aria-pressed="false" aria-label="Retourner la carte ${card.name}">
      <div class="card-inner">
        <div class="card-front">
          <div class="card-id">#${card.refId}</div>
          <div class="card-eyebrow">${card.category}</div>
          <div class="card-title">${card.name}</div>
          <p class="card-tagline">${card.tagline}</p>
          <div class="card-hint">cliquer pour retourner →</div>
        </div>
        <div class="card-back">
          <div class="card-eyebrow" data-role="back-eyebrow"></div>
          ${cardsData.axes
            .map(
              (axis) => `
            <div class="axis-row" data-axis="${axis.id}">
              <div class="axis-top"><span class="axis-label">${axis.label}</span><span class="axis-value"></span></div>
              <div class="axis-bar"><div class="axis-fill"></div></div>
              <p class="axis-note"></p>
            </div>`
            )
            .join("")}
        </div>
      </div>
    </div>`
    )
    .join("");

  const teamShortLabel =
    cardsData.teamProfiles.find((t) => t.id === currentTeam)?.shortLabel ?? currentTeam;

  grid.querySelectorAll(".card-flip").forEach((cardEl) => {
    const key = cardEl.getAttribute("data-card");
    const card = cardsData.cards.find((c) => c.id === key);
    const data = card.effects[currentTeam];
    cardEl.querySelector('[data-role="back-eyebrow"]').textContent = "Effet réel — " + teamShortLabel;
    cardEl.querySelectorAll(".axis-row").forEach((row) => {
      const axis = row.getAttribute("data-axis");
      const d = data[axis];
      const fill = row.querySelector(".axis-fill");
      const valueEl = row.querySelector(".axis-value");
      const noteEl = row.querySelector(".axis-note");
      const isPositive = d.value >= 0;
      fill.style.width = Math.min(Math.abs(d.value), 100) + "%";
      fill.className = "axis-fill " + (isPositive ? "positive" : "negative");
      valueEl.className = "axis-value " + (isPositive ? "positive" : "negative");
      valueEl.textContent = (isPositive ? "+" : "−") + Math.abs(d.value);
      noteEl.textContent = d.note;
    });

    cardEl.addEventListener("click", () => toggleFlip(cardEl));
    cardEl.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        toggleFlip(cardEl);
      }
    });
  });
}

function toggleFlip(cardEl) {
  const flipped = cardEl.classList.toggle("is-flipped");
  cardEl.setAttribute("aria-pressed", flipped ? "true" : "false");
}

function renderTeamToggle() {
  const toggle = document.getElementById("team-toggle");
  toggle.innerHTML = cardsData.teamProfiles
    .map(
      (t, i) => `<button class="team-btn${i === 0 ? " active" : ""}" data-team="${t.id}">${t.label}</button>`
    )
    .join("");
  toggle.querySelectorAll(".team-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      toggle.querySelectorAll(".team-btn").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      currentTeam = btn.getAttribute("data-team");
      renderCards();
    });
  });
}

/* ---------- INBOX ---------- */

function renderInbox(event) {
  const container = document.getElementById("inbox-container");
  container.innerHTML = `
    <div class="inbox-card">
      <div class="inbox-head">
        <span>De : ${event.from}</span>
        <span>Sprint ${event.sprint} · ${event.status}</span>
      </div>
      <div class="inbox-body">
        <div class="inbox-subject">${event.subject}</div>
        <p class="inbox-text">${event.text}</p>
        <div class="inbox-choices">
          ${event.choices
            .map((c) => `<button class="inbox-choice" data-reveal="${c.reveal.replace(/"/g, "&quot;")}">${c.label}</button>`)
            .join("")}
        </div>
        <div class="inbox-reveal" id="inbox-reveal"></div>
      </div>
    </div>`;

  container.querySelectorAll(".inbox-choice").forEach((btn) => {
    btn.addEventListener("click", () => {
      container.querySelectorAll(".inbox-choice").forEach((b) => b.classList.remove("chosen"));
      btn.classList.add("chosen");
      const reveal = container.querySelector("#inbox-reveal");
      reveal.textContent = btn.getAttribute("data-reveal");
      reveal.classList.add("show");
    });
  });
}

/* ---------- ROADMAP ---------- */

function renderRoadmap(roadmap) {
  const grid = document.getElementById("feature-grid");
  grid.innerHTML = roadmap.features
    .map(
      (f) => `
    <button class="feature-card${f.selectedByDefault ? " selected" : ""}">
      <span class="feature-check">✓</span>
      <span class="feature-name">${f.name}</span>
      <span class="feature-promise">${f.promise}</span>
      <span class="feature-icons">${f.icons.join(" ")}</span>
    </button>`
    )
    .join("");

  const capacityMax = roadmap.capacityMax;
  const countEl = document.getElementById("capacity-count");
  const fillEl = document.getElementById("capacity-fill");
  const warningEl = document.getElementById("capacity-warning");

  function updateCapacity() {
    const selected = grid.querySelectorAll(".feature-card.selected").length;
    countEl.textContent = `${selected}/${capacityMax}`;
    const pct = Math.min((selected / capacityMax) * 100, 100);
    fillEl.style.width = pct + "%";
    const over = selected > capacityMax;
    fillEl.classList.toggle("over", over);
    warningEl.classList.toggle("show", over);
  }

  grid.querySelectorAll(".feature-card").forEach((card) => {
    card.addEventListener("click", () => {
      card.classList.toggle("selected");
      updateCapacity();
    });
  });

  updateCapacity();
}

/* ---------- RECRUITMENT ---------- */

function renderRecruitment(recruitment) {
  const toggle = document.getElementById("shop-toggle");
  const panels = document.getElementById("shop-panels");

  toggle.innerHTML = recruitment.skins
    .map((s, i) => `<button class="shop-btn${i === 0 ? " active" : ""}" data-skin="${s.id}">${s.label}</button>`)
    .join("");

  panels.innerHTML = recruitment.skins
    .map((s, i) => {
      if (s.type === "candidates") {
        return `
        <div class="candidate-grid skin-grid${i === 0 ? " show" : ""}" data-skin="${s.id}">
          ${s.candidates
            .map(
              (c) => `
            <div class="candidate-card">
              <div class="candidate-avatar">${c.avatar}</div>
              <div class="candidate-name">${c.name}</div>
              <div class="candidate-role">${c.role}</div>
              <div class="candidate-badges">${c.badges.map((b) => `<span class="candidate-badge">${b}</span>`).join("")}</div>
              <div class="candidate-cost">${c.cost}</div>
              <button class="candidate-btn">${c.action}</button>
            </div>`
            )
            .join("")}
        </div>`;
      }
      return `
        <div class="candidate-grid skin-grid${i === 0 ? " show" : ""}" data-skin="${s.id}">
          ${s.ads
            .map(
              (a) => `
            <div class="ad-card">
              <div class="ad-title">${a.title}</div>
              ${a.text}
              <button class="candidate-btn ad-btn">${a.action}</button>
            </div>`
            )
            .join("")}
        </div>`;
    })
    .join("");

  toggle.querySelectorAll(".shop-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      toggle.querySelectorAll(".shop-btn").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      const skin = btn.getAttribute("data-skin");
      panels.querySelectorAll(".skin-grid").forEach((g) => {
        g.classList.toggle("show", g.getAttribute("data-skin") === skin);
      });
    });
  });

  panels.querySelectorAll(".candidate-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (!btn.disabled) {
        btn.textContent = btn.textContent + " ✓";
        btn.disabled = true;
        btn.style.opacity = "0.65";
      }
    });
  });
}

/* ---------- FOUNDATIONS ---------- */

function renderFoundations(foundations) {
  const grid = document.getElementById("fondation-grid");
  const familyLabel = (id) => foundations.families.find((f) => f.id === id)?.label ?? id;

  grid.innerHTML = foundations.demoBoard
    .map((f) => {
      const statusLabel =
        f.status === "waiting" ? "🕐 En attente" : `✅ Actif depuis le sprint ${f.activeSinceSprint}`;
      return `
      <div class="fondation-card${f.status === "waiting" ? " waiting" : ""}">
        <span class="fondation-status ${f.status}">${statusLabel}</span>
        <div class="fondation-family">${familyLabel(f.family)}</div>
        <div class="fondation-name">${f.name}</div>
        <div class="fondation-detail">${f.detail}</div>
      </div>`;
    })
    .join("");
}

/* ---------- ERAS ---------- */

function renderEras(eras) {
  const grid = document.getElementById("era-grid");
  grid.innerHTML = eras
    .map(
      (era) => `
    <div class="era-card">
      <span class="era-badge">${era.icon} ${era.period}</span>
      <div class="era-name">${era.name}</div>
      <p class="era-desc">${era.description}</p>
      <div class="era-meta">
        <div><span class="k">Tension</span><br>${era.tension}</div>
        <div><span class="k">Boss de fin</span><br>${era.boss}</div>
      </div>
    </div>`
    )
    .join("");
}

/* ---------- ENDINGS ---------- */

function renderEndings(endings) {
  const grid = document.getElementById("ending-grid");
  grid.innerHTML = endings
    .map(
      (e) => `
    <div class="ending-badge"><div class="ending-label">${e.icon} ${e.label}</div><div class="ending-note">${e.note}</div></div>`
    )
    .join("");
}

/* ---------- BOOT ---------- */

async function main() {
  const [resourcesData, cards, inbox, roadmap, recruitment, foundations, eras, endings, hud] = await Promise.all([
    loadJSON("resources.json"),
    loadJSON("cards.json"),
    loadJSON("inbox-events.json"),
    loadJSON("roadmap-features.json"),
    loadJSON("recruitment-demo.json"),
    loadJSON("foundations.json"),
    loadJSON("eras.json"),
    loadJSON("endings.json"),
    loadJSON("hud-demo.json"),
  ]);

  cardsData = cards;

  renderResources(resourcesData.resources);
  renderTensions(resourcesData.tensions);
  renderHud(hud);
  renderTeamToggle();
  renderCards();
  renderInbox(inbox.events[0]);
  renderRoadmap(roadmap);
  renderRecruitment(recruitment);
  renderFoundations(foundations);
  renderEras(eras.eras);
  renderEndings(endings.endings);
}

main().catch((err) => {
  console.error(err);
  document.querySelector(".wrap").insertAdjacentHTML(
    "afterbegin",
    `<p style="color:#B3271E;font-family:monospace;padding:12px 0;">Erreur de chargement des données : ${err.message}. Si vous ouvrez ce fichier directement (file://), servez le dossier via un serveur local (ex: python3 -m http.server) pour que le fetch des JSON fonctionne.</p>`
  );
});
