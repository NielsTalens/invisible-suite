const form = document.getElementById("entry-form");
const inputPanel = document.getElementById("input-panel");
const composerShell = document.getElementById("composer-shell");
const summaryEl = document.getElementById("summary");
const entriesEl = document.getElementById("entries");
const followupsEl = document.getElementById("followups");
const resultsContent = document.getElementById("results-content");
const toggleResultsButton = document.getElementById("toggle-results");
const statusLine = document.getElementById("status-line");
const statusText = document.getElementById("status-text");
const statusElapsed = document.getElementById("status-elapsed");
const errorBox = document.getElementById("error-box");
const latestConfirmation = document.getElementById("latest-confirmation");
const channelOptions = document.querySelectorAll(".channel-option");
let processingTimer = null;
let processingStartedAt = null;

function currentChannelValue() {
  const selected = form.querySelector('input[name="channel"]:checked');
  return selected ? selected.value : "mail";
}

function setChannelTheme(channel) {
  inputPanel.classList.remove("channel-mail", "channel-sms", "channel-whatsapp");
  inputPanel.classList.add(`channel-${channel}`);
  composerShell.classList.remove("composer-mail", "composer-sms", "composer-whatsapp");
  composerShell.classList.add(`composer-${channel}`);

  channelOptions.forEach((option) => {
    const input = option.querySelector('input[name="channel"]');
    option.classList.toggle("active", input && input.checked);
  });

  const textarea = form.message;
  if (channel === "mail") {
    textarea.placeholder = "Worked 2h on Alpha\n30m sprint planning";
  } else if (channel === "sms") {
    textarea.placeholder = "2h Alpha build fixes\n1h client call";
  } else {
    textarea.placeholder = "Morning: 1.5h onboarding\nAfternoon: 2h QA follow-up";
  }
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

function clearLatestConfirmation() {
  latestConfirmation.innerHTML = "";
  latestConfirmation.classList.add("hidden");
  latestConfirmation.classList.remove("channel-mail", "channel-sms", "channel-whatsapp");
}

function renderLatestConfirmation(data, selectedChannel) {
  const created = new Set((data.created_source_files || []).map(String));
  const latestEntries = (data.entries || []).filter((entry) => created.has(String(entry.source_file)));
  if (latestEntries.length === 0) {
    clearLatestConfirmation();
    return;
  }

  latestConfirmation.classList.remove("hidden");
  latestConfirmation.classList.add(`channel-${selectedChannel}`);

  latestConfirmation.innerHTML = `
    <h3>Timy Confirmation</h3>
    ${latestEntries.map((entry) => {
      const needsClarification = entry.status === "needs_clarification";
      const body = needsClarification
        ? `<p><strong>Clarification needed:</strong> ${entry.clarification_question || "Please clarify details."}</p>`
        : `<p><strong>Recap:</strong> ${entry.task_description || "Logged"} (${entry.duration_hours ?? 0}h on ${entry.project || "unknown"})</p>`;
      return `
        <article class="confirmation-item">
          <div class="confirmation-head">
            <span class="confirmation-sender">Timy</span>
            <span class="confirmation-status ${needsClarification ? "needs-clarification" : "ok"}">
              ${needsClarification ? "Needs clarification" : "Captured"}
            </span>
          </div>
          ${body}
        </article>
      `;
    }).join("")}
  `;
}

function clearError() {
  errorBox.textContent = "";
  errorBox.classList.remove("visible");
}

function showError(message) {
  errorBox.textContent = message;
  errorBox.classList.add("visible");
}

function updateResultsToggleLabel() {
  toggleResultsButton.textContent = resultsContent.hidden ? "Show Results" : "Hide Results";
}

function formatElapsed(seconds) {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

function startProcessingStatus(message) {
  if (processingTimer) {
    clearInterval(processingTimer);
  }
  processingStartedAt = Date.now();
  statusLine.classList.add("is-processing");
  statusLine.classList.remove("error");
  statusText.textContent = message;
  statusElapsed.textContent = "00:00";
  processingTimer = setInterval(() => {
    const seconds = Math.floor((Date.now() - processingStartedAt) / 1000);
    statusElapsed.textContent = formatElapsed(seconds);
  }, 250);
}

function stopProcessingStatus(message, isError = false) {
  const elapsedMs = processingStartedAt ? Date.now() - processingStartedAt : 0;
  if (processingTimer) {
    clearInterval(processingTimer);
    processingTimer = null;
  }
  processingStartedAt = null;
  statusLine.classList.remove("is-processing");
  statusLine.classList.toggle("error", isError);
  statusText.textContent = message;
  statusElapsed.textContent = `${(elapsedMs / 1000).toFixed(1)}s`;
}

async function loadResults() {
  statusLine.classList.remove("error");
  statusText.textContent = "Loading results...";
  statusElapsed.textContent = "";
  clearError();
  try {
    const res = await fetch("/api/results");
    const data = await res.json();
    render(data);
    statusText.textContent = "Ready";
    statusElapsed.textContent = "";
  } catch (error) {
    statusLine.classList.add("error");
    statusText.textContent = `Failed to load results: ${error.message}`;
    statusElapsed.textContent = "";
    showError(error.message);
  }
}

form.addEventListener("change", (event) => {
  if (event.target && event.target.name === "channel") {
    setChannelTheme(event.target.value);
  }
});

toggleResultsButton.addEventListener("click", () => {
  resultsContent.hidden = !resultsContent.hidden;
  updateResultsToggleLabel();
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  startProcessingStatus("Submitting and processing...");
  clearError();
  clearLatestConfirmation();

  const selectedChannel = currentChannelValue();
  const payload = {
    channel: selectedChannel,
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
    renderLatestConfirmation(data, selectedChannel);
    stopProcessingStatus("Processed successfully");
    form.message.value = "";
  } catch (error) {
    stopProcessingStatus(`Submit failed: ${error.message}`, true);
    showError(error.message);
  }
});

setChannelTheme(currentChannelValue());
updateResultsToggleLabel();
loadResults();
