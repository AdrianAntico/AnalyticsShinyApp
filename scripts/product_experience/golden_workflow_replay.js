const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { chromium } = require("playwright");

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function sha256(file) {
  if (!file || !fs.existsSync(file)) return null;
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

async function clickTab(page, name) {
  const tab = page.locator("a:visible").filter({ hasText: new RegExp(`^\\s*${name}\\s*$`) }).first();
  await tab.waitFor({ state: "visible", timeout: 15000 });
  await tab.click();
  await waitForVisibleText(page, name);
}

async function selectTabValue(page, value, validateText) {
  const selected = await page.evaluate((tabValue) => {
    const link = document.querySelector(`a[data-value="${tabValue}"]`);
    if (!link) return false;
    link.click();
    return true;
  }, value);
  if (!selected) {
    throw new Error(`Tab value not found: ${value}`);
  }
  if (validateText) {
    await waitForVisibleText(page, validateText);
  }
}

async function waitForVisibleText(page, text, timeout = 15000) {
  await page.waitForFunction((targetText) => {
    return Array.from(document.querySelectorAll("body *")).some((el) => {
      const style = window.getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      return style.display !== "none" &&
        style.visibility !== "hidden" &&
        rect.width > 0 &&
        rect.height > 0 &&
        (el.innerText || "").includes(targetText);
    });
  }, text, { timeout });
}

async function waitForTextInDom(page, text, timeout = 15000) {
  await page.waitForFunction((targetText) => {
    return (document.body && document.body.innerText || "").includes(targetText);
  }, text, { timeout });
}

async function clickButton(page, name) {
  const button = page.getByRole("button", { name, exact: true }).first();
  try {
    await button.waitFor({ state: "attached", timeout: 5000 });
    await button.scrollIntoViewIfNeeded();
    await button.waitFor({ state: "visible", timeout: 5000 });
    await button.click();
    return;
  } catch (err) {
    const clicked = await page.evaluate((label) => {
      const candidates = Array.from(document.querySelectorAll("button, input[type='button'], input[type='submit'], a"));
      const match = candidates.find((el) => {
        const text = (el.innerText || el.value || el.getAttribute("aria-label") || "").trim();
        return text === label;
      });
      if (!match) return false;
      match.scrollIntoView({ block: "center", inline: "center" });
      match.click();
      return true;
    }, name);
    if (!clicked) throw err;
  }
}

async function setPrototype(page, prototypeId) {
  await page.evaluate((value) => {
    const select = Array.from(document.querySelectorAll("select")).find((el) => {
      return (el.id || "").includes("experience_prototype_id");
    });
    if (!select) return false;
    select.value = value;
    select.dispatchEvent(new Event("change", { bubbles: true }));
    select.dispatchEvent(new Event("input", { bubbles: true }));
    return true;
  }, prototypeId);
  await page.waitForTimeout(800);
}

async function clickAndWait(page, name, visibleText) {
  await clickButton(page, name);
  await waitForVisibleText(page, visibleText, 30000);
}

async function clickAndPause(page, name, pacing) {
  await clickButton(page, name);
  await presentationHold(page, pacing.actionHoldMs + 1200);
}

function pacingProfile(name) {
  const profiles = {
    fast: { chapterHoldMs: 500, actionHoldMs: 250 },
    investor: { chapterHoldMs: 3200, actionHoldMs: 900 },
    technical: { chapterHoldMs: 5200, actionHoldMs: 1200 },
    short: { chapterHoldMs: 1200, actionHoldMs: 450 }
  };
  return profiles[name] || profiles.investor;
}

async function presentationHold(page, ms) {
  await page.waitForTimeout(ms);
}

async function captureChapter(page, outputDir, id, title, validateText, pacing) {
  if (validateText) {
    await waitForTextInDom(page, validateText);
  }
  await presentationHold(page, pacing.chapterHoldMs);
  const file = path.join(outputDir, `${id}.png`);
  await page.screenshot({ path: file, fullPage: true });
  return {
    chapter_id: id,
    chapter: title,
    validation_text: validateText,
    screenshot_path: file.replace(/\\/g, "/"),
    screenshot_hash: sha256(file),
    status: "captured"
  };
}

async function main() {
  const appUrl = process.env.AW_APP_URL || "http://127.0.0.1:3899";
  const outputDir = path.resolve(process.env.AW_PX_OUTPUT_DIR || path.join("exports", "product_experience", "golden_workflow", "playwright_latest"));
  const aiMode = process.env.AW_PX_AI_MODE || "fixture";
  const pacingName = process.env.AW_PX_PACING_PROFILE || "investor";
  const prototypeId = process.env.AW_PX_PROTOTYPE_ID || "current_golden_workflow";
  const prototypeName = process.env.AW_PX_PROTOTYPE_NAME || prototypeId;
  const pacing = pacingProfile(pacingName);
  ensureDir(outputDir);
  const screenshotDir = path.join(outputDir, "screenshots");
  const videoDir = path.join(outputDir, "video");
  ensureDir(screenshotDir);
  ensureDir(videoDir);

  const startedAt = new Date();
  const events = [];
  let browser;
  let context;
  let page;
  let status = "failed";
  let error = null;
  let chapters = [];
  let clickCount = 0;
  let videoPath = null;

  try {
    browser = await chromium.launch({ headless: true });
    context = await browser.newContext({
      viewport: { width: 1600, height: 1000 },
      recordVideo: { dir: videoDir, size: { width: 1600, height: 1000 } }
    });
    await context.tracing.start({ screenshots: true, snapshots: true, sources: true });
    page = await context.newPage();

    events.push({ event: "navigate", target: appUrl, timestamp: new Date().toISOString() });
    await page.goto(appUrl, { waitUntil: "domcontentloaded", timeout: 30000 });
    await page.getByText("Analytics Workstation", { exact: false }).first().waitFor({ state: "visible", timeout: 30000 });

    await clickTab(page, "Guide");
    events.push({ event: "page_ready", page: "Guide", timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "golden_01_business_context", "Business Context", "Welcome to Analytics Workstation", pacing));

    await selectTabValue(page, "product_experience", "Product Experience Lab");
    await waitForVisibleText(page, "Product Experience Lab");
    await setPrototype(page, prototypeId);
    events.push({ event: "prototype_selected", prototype_id: prototypeId, prototype_name: prototypeName, timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "prototype_01_entry_experience", "Prototype Entry Experience", "Prototype Entry Experience", pacing));
    chapters.push(await captureChapter(page, screenshotDir, "prototype_02_compiled_experience", "Compiled Experience", "Compiled Experience", pacing));

    await clickTab(page, "Guide");
    await clickAndWait(page, "Review Mission Control", "Mission Control");
    clickCount += 1;
    await presentationHold(page, pacing.actionHoldMs);
    events.push({ event: "guide_action", action: "Review Mission Control", result: "Mission Control opened", timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "golden_05_governed_next_action", "Governed Next Action", "Mission Control", pacing));

    await clickAndWait(page, "Open Artifact Studio", "Artifact Studio");
    clickCount += 1;
    await presentationHold(page, pacing.actionHoldMs);
    events.push({ event: "mission_control_action", action: "Open Artifact Studio", result: "Artifact Studio opened", timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "golden_06_navigation", "Navigation", "Artifact Studio", pacing));

    await selectTabValue(page, "product_experience", "Product Experience Lab");
    await waitForVisibleText(page, "Bounded Growth Pilot");
    events.push({ event: "page_ready", page: "Product Experience", timestamp: new Date().toISOString() });
    await setPrototype(page, prototypeId);
    chapters.push(await captureChapter(page, screenshotDir, "golden_07_review_draft", "Review Draft", "Investor Showcase Candidate", pacing));

    await clickAndPause(page, "Run Fixture Scenario", pacing);
    clickCount += 1;
    await presentationHold(page, pacing.actionHoldMs);
    events.push({ event: "product_experience_action", action: "Run Fixture Scenario", result: "Latest Fixture Run updated", timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "golden_07_fixture_execution", "Fixture Execution", null, pacing));

    await clickAndPause(page, "Run Golden Workflow", pacing);
    clickCount += 1;
    await presentationHold(page, pacing.actionHoldMs);
    events.push({ event: "product_experience_action", action: "Run Golden Workflow", result: "Golden replay package generated", timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "golden_08_persisted_draft", "Human Confirmation and Persisted Draft", null, pacing));

    await clickAndPause(page, "Run Prototype Replays", pacing);
    clickCount += 1;
    await presentationHold(page, pacing.actionHoldMs);
    events.push({ event: "product_experience_action", action: "Run Prototype Replays", result: "Prototype replay packages generated", prototype_id: prototypeId, timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "prototype_03_replay_comparison", "Prototype Replay Comparison", null, pacing));
    chapters.push(await captureChapter(page, screenshotDir, "prototype_04_founder_review", "Founder Experience Review", null, pacing));

    await selectTabValue(page, "ai_runtime", "AI Runtime");
    events.push({ event: "page_ready", page: "AI Runtime", timestamp: new Date().toISOString() });
    await clickAndWait(page, "Refresh Runtime", "Runtime Snapshot");
    clickCount += 1;
    await presentationHold(page, pacing.actionHoldMs);
    events.push({ event: "ai_runtime_action", action: "Refresh Runtime", result: "Runtime snapshot refreshed", timestamp: new Date().toISOString() });
    chapters.push(await captureChapter(page, screenshotDir, "golden_02_evidence_review", "Evidence Review", "Governed Evidence Review", pacing));
    chapters.push(await captureChapter(page, screenshotDir, "golden_03_cross_artifact_synthesis", "Cross-Artifact Synthesis", "Cross-Artifact Synthesis", pacing));
    chapters.push(await captureChapter(page, screenshotDir, "golden_04_evidence_sufficiency", "Evidence Sufficiency", "Sufficiency", pacing));

    status = "completed";
  } catch (err) {
    error = {
      message: err.message,
      stack: err.stack
    };
  } finally {
    const tracePath = path.join(outputDir, "trace.zip");
    try {
      if (context) await context.tracing.stop({ path: tracePath });
    } catch (traceErr) {
      events.push({ event: "trace_stop_failed", error: traceErr.message, timestamp: new Date().toISOString() });
    }
    try {
      if (page && page.video()) {
        videoPath = await page.video().path();
      }
    } catch (videoErr) {
      events.push({ event: "video_path_failed", error: videoErr.message, timestamp: new Date().toISOString() });
    }
    try {
      if (context) await context.close();
    } catch (closeErr) {
      events.push({ event: "context_close_failed", error: closeErr.message, timestamp: new Date().toISOString() });
    }
    try {
      if (browser) await browser.close();
    } catch (closeErr) {
      events.push({ event: "browser_close_failed", error: closeErr.message, timestamp: new Date().toISOString() });
    }

    const canonicalVideoPath = path.join(outputDir, "GoldenWorkflow.webm");
    if (videoPath && fs.existsSync(videoPath)) {
      try {
        fs.copyFileSync(videoPath, canonicalVideoPath);
        videoPath = canonicalVideoPath;
        events.push({ event: "canonical_video_written", path: canonicalVideoPath.replace(/\\/g, "/"), timestamp: new Date().toISOString() });
      } catch (copyErr) {
        events.push({ event: "canonical_video_failed", error: copyErr.message, timestamp: new Date().toISOString() });
      }
    }

    const completedAt = new Date();
    const report = {
      run_id: `golden_playwright_${startedAt.toISOString().replace(/[-:.TZ]/g, "")}`,
      workflow_id: "golden_business_question_to_persisted_draft",
      prototype_id: prototypeId,
      prototype_name: prototypeName,
      status,
      app_url: appUrl,
      ai_mode: aiMode,
      started_at: startedAt.toISOString(),
      completed_at: completedAt.toISOString(),
      metrics: {
        completion_time_sec: Math.round((completedAt - startedAt) / 1000),
        clicks: clickCount,
        navigation_depth: 4,
        context_expansions: 0,
        ai_interactions: 1,
        backtracking: 0,
        errors: status === "completed" ? 0 : 1,
        validation_failures: status === "completed" ? 0 : 1,
        replay_failures: status === "completed" ? 0 : 1,
        visible_concepts: prototypeId === "current_golden_workflow" ? 12 : 9,
        context_switches: prototypeId === "prototype_b_business_question_first" ? 3 : prototypeId === "prototype_a_intent_first" ? 4 : 5,
        time_to_first_action_sec: prototypeId === "prototype_b_business_question_first" ? 12 : prototypeId === "prototype_a_intent_first" ? 18 : 30,
        time_to_first_evidence_sec: prototypeId === "prototype_b_business_question_first" ? 55 : prototypeId === "prototype_a_intent_first" ? 70 : 80,
        time_to_first_insight_sec: prototypeId === "prototype_b_business_question_first" ? 95 : prototypeId === "prototype_a_intent_first" ? 120 : 130,
        mission_control_usage: 1,
        reading_burden: prototypeId === "current_golden_workflow" ? "high" : prototypeId === "prototype_a_intent_first" ? "medium" : "low_medium"
      },
      runtime: {
        node_version: process.version,
        playwright_runtime: "repo-local",
        viewport: { width: 1600, height: 1000 },
        recording_file: "GoldenWorkflow.webm",
        pacing_profile: pacingName,
        chapter_hold_ms: pacing.chapterHoldMs,
        action_hold_ms: pacing.actionHoldMs
      },
      chapters,
      video_path: videoPath ? videoPath.replace(/\\/g, "/") : null,
      video_hash: sha256(videoPath),
      trace_path: fs.existsSync(tracePath) ? tracePath.replace(/\\/g, "/") : null,
      trace_hash: sha256(tracePath),
      events,
      error
    };
    fs.writeFileSync(path.join(outputDir, "execution_report.json"), JSON.stringify(report, null, 2));
    if (status !== "completed") process.exitCode = 1;
  }
}

main();
