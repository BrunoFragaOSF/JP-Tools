#!/usr/bin/env node

"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const args = process.argv.slice(2);
const lockOnly = args[0] === "--lock-only";
const offset = lockOnly ? 1 : 0;
const runtimeDir = path.resolve(args[offset] || "");
const lockPath = path.resolve(args[offset + 1] || "");

if (!runtimeDir || !lockPath || !fs.existsSync(lockPath)) {
    console.error("Usage: verify-runtime.js [--lock-only] runtime-dir dependencies.lock.json");
    process.exit(2);
}

const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));
const expected = lock.npmRuntime;
const packageLockPath = path.join(runtimeDir, "package-lock.json");
const actualLockSha = crypto.createHash("sha256").update(fs.readFileSync(packageLockPath)).digest("hex");

if (actualLockSha !== expected.packageLockSha256) {
    console.error("JP Tools error: o hash de runtime/package-lock.json foi alterado.");
    process.exit(1);
}

if (lockOnly) {
    console.log("JP Tools: package-lock.json validado.");
    process.exit(0);
}

const playwrightPackage = require(path.join(runtimeDir, "node_modules", "playwright", "package.json"));
const playwrightCorePackage = require(path.join(runtimeDir, "node_modules", "playwright-core", "package.json"));
const browsers = require(path.join(runtimeDir, "node_modules", "playwright-core", "browsers.json"));
const chromiumEntry = browsers.browsers.find(browser => browser.name === "chromium");
const { chromium } = require(path.join(runtimeDir, "node_modules", "playwright"));

const errors = [];
if (playwrightPackage.version !== expected.playwright.version) {
    errors.push(`Playwright ${playwrightPackage.version}, esperado ${expected.playwright.version}`);
}
if (playwrightCorePackage.version !== expected.playwrightCore.version) {
    errors.push(`playwright-core ${playwrightCorePackage.version}, esperado ${expected.playwrightCore.version}`);
}
if (!chromiumEntry || chromiumEntry.revision !== expected.chromium.revision) {
    errors.push(`revisao Chromium ${chromiumEntry && chromiumEntry.revision}, esperada ${expected.chromium.revision}`);
}
if (!chromiumEntry || chromiumEntry.browserVersion !== expected.chromium.browserVersion) {
    errors.push(`versao Chromium ${chromiumEntry && chromiumEntry.browserVersion}, esperada ${expected.chromium.browserVersion}`);
}
if (!fs.existsSync(chromium.executablePath())) {
    errors.push("executavel homologado do Chromium nao foi encontrado");
}

async function finishValidation() {
    if (!errors.length) {
        try {
            const browser = await chromium.launch({ headless: true });
            const launchedVersion = browser.version();
            await browser.close();
            if (launchedVersion !== expected.chromium.browserVersion) {
                errors.push(`Chromium executado ${launchedVersion}, esperado ${expected.chromium.browserVersion}`);
            }
        } catch (error) {
            errors.push(`Chromium nao iniciou: ${error.message}`);
        }
    }

    if (errors.length) {
        console.error("JP Tools error: o runtime instalado nao confere com o lock.");
        errors.forEach(error => console.error(`  - ${error}`));
        process.exit(1);
    }

    console.log(`JP Tools: Playwright ${playwrightPackage.version} e Chromium ${chromiumEntry.browserVersion} validados.`);
}

finishValidation();
