const fs = require("fs");
const path = require("path");
const { createRequire } = require("module");

const repoRootForModules = path.resolve(__dirname, "..", "..");
const toolPackage = path.join(repoRootForModules, "tools", "product-experience", "package.json");
const toolRequire = fs.existsSync(toolPackage) ? createRequire(toolPackage) : require;

const { chromium } = toolRequire("@playwright/test");

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

async function waitForWorkstationReady(page, expectedTarget) {
  await page.evaluate(() => {
    if (window.__awCheckReadiness) window.__awCheckReadiness();
  }).catch(() => {});
  await page.waitForFunction((target) => {
    const state = window.__awDomReady || {};
    return state.ready === true &&
      state.checks &&
      state.checks.shiny_connected === true &&
      state.checks.styles_loaded === true &&
      state.checks.route_rendered === true &&
      state.checks.layout_stable === true &&
      (!target || state.checks.target === target);
  }, expectedTarget || null, { timeout: 45000 });
}

async function assertStyledWorkstation(page, expectedText) {
  const state = await page.evaluate((text) => {
    const bodyStyle = window.getComputedStyle(document.body);
    const header = document.querySelector(".aq-workstation-header");
    const headerStyle = header ? window.getComputedStyle(header) : null;
    const logo = document.querySelector(".aq-brand-mark");
    const button = document.querySelector(".aq-app-shell .btn, .aq-shell-route, button");
    const buttonStyle = button ? window.getComputedStyle(button) : null;
    const cssLinks = Array.from(document.querySelectorAll("link[rel='stylesheet']")).map((el) => el.href);
    return {
      body_background: bodyStyle.backgroundColor,
      aq_bg: bodyStyle.getPropertyValue("--aq-bg").trim(),
      aq_surface: bodyStyle.getPropertyValue("--aq-surface").trim(),
      header_background: headerStyle ? headerStyle.backgroundColor : "",
      header_display: headerStyle ? headerStyle.display : "",
      button_border_radius: buttonStyle ? buttonStyle.borderRadius : "",
      button_background: buttonStyle ? buttonStyle.backgroundColor : "",
      logo_visible: !!logo && logo.getBoundingClientRect().width > 32,
      build_week_rendered: text ? (document.body.innerText || "").includes(text) : true,
      stylesheet_count: cssLinks.length,
      app_css_loaded: cssLinks.some((href) => href.indexOf("aw-assets/app.css") !== -1),
      ready: window.__awDomReady || null
    };
  }, expectedText || "");

  const defaultWhite = /rgba?\(255,\s*255,\s*255/i.test(state.body_background);
  const missing = [];
  if (defaultWhite || !state.aq_bg || !state.aq_surface) missing.push("the page still looks browser-default or CSS variables are missing");
  if (!state.app_css_loaded) missing.push("aw-assets/app.css was not loaded");
  if (!state.logo_visible) missing.push("the Analytics Workstation logo is not visible");
  if (!state.build_week_rendered) missing.push(`expected route text was not rendered: ${expectedText}`);
  if (!state.button_border_radius || state.button_border_radius === "0px") missing.push("primary controls do not have workstation styling");
  if (state.header_display === "block") missing.push("navigation/header layout appears unstyled");
  if (missing.length) {
    throw new Error(`Styled workstation assertion failed: ${missing.join("; ")}\n${JSON.stringify(state, null, 2)}`);
  }
  return state;
}

async function routeTo(page, target, expectedText) {
  await page.evaluate((routeTarget) => {
    const route = Array.from(document.querySelectorAll(".aq-shell-route[data-target]"))
      .find((el) => el.getAttribute("data-target") === routeTarget);
    if (!route) throw new Error(`Route not found: ${routeTarget}`);
    route.click();
  }, target);
  await waitForWorkstationReady(page, target);
  if (expectedText) {
    await page.locator(".aq-main-tabset .tab-pane.active").getByText(expectedText, { exact: false }).first().waitFor({ state: "visible", timeout: 30000 });
  }
}

async function clickButton(page, label) {
  const button = page.getByRole("button", { name: label, exact: true }).first();
  await button.waitFor({ state: "visible", timeout: 30000 });
  await button.click();
}

async function setSelectBySuffix(page, suffix, value) {
  const ok = await page.evaluate(({ suffix, value }) => {
    const select = Array.from(document.querySelectorAll("select")).find((el) => (el.id || "").endsWith(suffix));
    if (!select) return false;
    select.value = value;
    select.dispatchEvent(new Event("change", { bubbles: true }));
    select.dispatchEvent(new Event("input", { bubbles: true }));
    if (window.Shiny && Shiny.setInputValue && select.id) {
      Shiny.setInputValue(select.id, value, { priority: "event" });
    }
    return true;
  }, { suffix, value });
  if (!ok) throw new Error(`Select ending in ${suffix} not found.`);
}

async function waitForText(page, text, timeout = 45000) {
  await page.waitForFunction((needle) => (document.body.innerText || "").includes(needle), text, { timeout });
}

async function main() {
  const repoRoot = path.resolve(__dirname, "..", "..");
  const mediaDir = path.resolve(repoRoot, "docs", "media");
  const tempVideoDir = path.resolve(repoRoot, "exports", "product_experience", "build_week_public_recording", "video");
  ensureDir(mediaDir);
  ensureDir(tempVideoDir);

  const appUrl = process.env.AW_APP_URL || "http://127.0.0.1:3899";
  const demoVideo = path.join(mediaDir, "demo.webm");
  const firstFrame = path.join(mediaDir, "demo_first_frame.png");
  const finalFrame = path.join(mediaDir, "demo_final_frame.png");

  const failedRequests = [];
  const badResponses = [];
  let browser;
  let context;
  let page;

  try {
    browser = await chromium.launch({ headless: true });
    context = await browser.newContext({
      viewport: { width: 1600, height: 1000 },
      recordVideo: { dir: tempVideoDir, size: { width: 1600, height: 1000 } }
    });
    page = await context.newPage();

    page.on("requestfailed", (request) => {
      failedRequests.push({ url: request.url(), failure: request.failure() });
    });
    page.on("response", (response) => {
      const url = response.url();
      if ((url.includes("aw-assets") || url.includes("bootstrap") || url.includes("jquery")) && response.status() >= 400) {
        badResponses.push({ url, status: response.status() });
      }
    });

    await page.goto(appUrl, { waitUntil: "domcontentloaded", timeout: 45000 });
    await waitForWorkstationReady(page, "Guide");
    await assertStyledWorkstation(page, "Analytics Workstation");
    await page.screenshot({ path: firstFrame, fullPage: false });
    await page.waitForTimeout(1000);

    await routeTo(page, "Build Week Demo", "Build Week Demo");
    await assertStyledWorkstation(page, "Build Week Demo");
    await setSelectBySuffix(page, "-provider", "mock");
    await page.waitForTimeout(600);
    await clickButton(page, "Run Preflight");
    await waitForText(page, "preflight", 45000);
    await page.waitForTimeout(1400);

    await clickButton(page, "Launch Demo");
    await waitForText(page, "Belief Revision", 45000);
    await page.waitForTimeout(1800);

    await clickButton(page, "Why should I believe this?");
    await waitForText(page, "The workstation challenged its own recommendation.", 45000);
    await page.getByText("The workstation challenged its own recommendation.", { exact: false }).first().scrollIntoViewIfNeeded();
    await page.waitForTimeout(2200);
    await page.screenshot({ path: finalFrame, fullPage: false });

    const requiredFailures = failedRequests.filter((item) =>
      item.url.includes("aw-assets") || item.url.includes("bootstrap") || item.url.includes("jquery")
    );
    if (requiredFailures.length || badResponses.length) {
      throw new Error(`Required asset failures detected.\nFailed requests: ${JSON.stringify(requiredFailures, null, 2)}\nBad responses: ${JSON.stringify(badResponses, null, 2)}`);
    }
  } finally {
    if (page) {
      const video = page.video();
      await page.close();
      if (video) {
        const recordedPath = await video.path();
        fs.copyFileSync(recordedPath, demoVideo);
      }
    }
    if (context) await context.close();
    if (browser) await browser.close();
  }

  if (!fs.existsSync(demoVideo) || fs.statSync(demoVideo).size < 100000) {
    throw new Error("Demo video was not created or is unexpectedly small.");
  }
  if (!fs.existsSync(firstFrame) || !fs.existsSync(finalFrame)) {
    throw new Error("Demo frame captures were not created.");
  }
  console.log(JSON.stringify({
    status: "success",
    demo_video: demoVideo,
    first_frame: firstFrame,
    final_frame: finalFrame,
    failed_requests: failedRequests.length,
    bad_required_responses: badResponses.length
  }, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
