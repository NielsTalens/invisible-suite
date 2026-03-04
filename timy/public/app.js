const form = document.getElementById("entry-form");
const inputPanel = document.getElementById("input-panel");
const summaryEl = document.getElementById("summary");
const entriesEl = document.getElementById("entries");
const followupsEl = document.getElementById("followups");
const statusLine = document.getElementById("status-line");
const errorBox = document.getElementById("error-box");
const channelOptions = document.querySelectorAll(".channel-option");

function currentChannelValue() {
  const selected = form.querySelector('input[name="channel"]:checked');
  return selected ? selected.value : "mail";
}

function setChannelTheme(channel) {
  inputPanel.classList.remove("channel-mail", "channel-sms", "channel-whatsapp");
  inputPanel.classList.add(`channel-${channel}`);

  channelOptions.forEach((option) => {
    const input = option.querySelector('input[name="channel"]');
    option.classList.toggle("active", input && input.checked);
  });
}

function render(data) {
  const summary = data.summary || { processed: 0, ok: 0, needs_clarification: 0 };
  summaryEl.innerHTML = `
    <div class="metric"><strong>${summary.processed}</strong><div>Processed</div></div>
    <div class="metric"><strong>${summary.ok}</strong><div>OK</div></div>
    <div class="metric"><strong>${summary.needs_clarification}</strong><div>Needs Clarification</div></div>
  `;

  const entries = data.entries || [];
  entriesEl.innerHTML = entries.map((entry) => `
    <article class="entry">
      <div><strong>${entry.source_file || "(new)"}</strong></div>
      <div>${entry.project || "unknown"} | ${entry.duration_hours ?? 0}h | ${entry.status}</div>
      <div>${entry.task_description || "No description"}</div>
    </article>
  `).join("");

  const unclear = entries.filter((entry) => entry.status === "needs_clarification");
  if (unclear.length === 0) {
    followupsEl.innerHTML = "";
    return;
  }

  followupsEl.innerHTML = `<strong>Follow-up Questions</strong>${unclear
    .map((entry) => `<p>${entry.source_file}: ${entry.clarification_question}</p>`)
    .join("")}`;
}

function clearError() {
  errorBox.textContent = "";
  errorBox.classList.remove("visible");
}

function showError(message) {
  errorBox.textContent = message;
  errorBox.classList.add("visible");
}

async function loadResults() {
  statusLine.textContent = "Loading results...";
  statusLine.className = "";
  clearError();
  try {
    const res = await fetch("/api/results");
    const data = await res.json();
    render(data);
    statusLine.textContent = "Ready";
  } catch (error) {
    statusLine.textContent = `Failed to load results: ${error.message}`;
    statusLine.className = "error";
    showError(error.message);
  }
}

form.addEventListener("change", (event) => {
  if (event.target && event.target.name === "channel") {
    setChannelTheme(event.target.value);
  }
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  statusLine.textContent = "Submitting and processing...";
  statusLine.className = "";
  clearError();

  const payload = {
    channel: currentChannelValue(),
    lines: form.message.value.split("\n"),
  };

  try {
    const res = await fetch("/api/submit-and-process", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || "Request failed");
    }

    render(data);
    statusLine.textContent = "Processed successfully";
    form.message.value = "";
  } catch (error) {
    statusLine.textContent = `Submit failed: ${error.message}`;
    statusLine.className = "error";
    showError(error.message);
  }
});

setChannelTheme(currentChannelValue());
loadResults();
