#!/usr/bin/env node

"use strict";

const fs = require("fs");
const path = require("path");

const runtimeDir = path.resolve(process.argv[2] || "");

if (!runtimeDir || !fs.existsSync(runtimeDir)) {
    console.error("Usage: verify-runtime.js runtime-dir");
    process.exit(2);
}

const playwrightPackage = require(path.join(runtimeDir, "node_modules", "playwright", "package.json"));
const playwrightCorePackage = require(path.join(runtimeDir, "node_modules", "playwright-core", "package.json"));
const browsers = require(path.join(runtimeDir, "node_modules", "playwright-core", "browsers.json"));
const chromiumEntry = browsers.browsers.find(browser => browser.name === "chromium");
const { chromium } = require(path.join(runtimeDir, "node_modules", "playwright"));
const errors = [];

if (playwrightPackage.version !== playwrightCorePackage.version) {
    errors.push(`Playwright ${playwrightPackage.version} e playwright-core ${playwrightCorePackage.version} nao correspondem`);
}
if (!chromiumEntry) {
    errors.push("metadados do Chromium nao foram encontrados");
}
if (!fs.existsSync(chromium.executablePath())) {
    errors.push("executavel do Chromium nao foi encontrado");
}

async function finishValidation() {
    if (!errors.length) {
        try {
            const browser = await chromium.launch({ headless: true });
            const launchedVersion = browser.version();
            await browser.close();
            if (launchedVersion !== chromiumEntry.browserVersion) {
                errors.push(`Chromium executado ${launchedVersion}, esperado ${chromiumEntry.browserVersion}`);
            }
        } catch (error) {
            errors.push(`Chromium nao iniciou: ${error.message}`);
        }
    }

    if (errors.length) {
        console.error("JP Tools error: o runtime Playwright/Chromium nao foi instalado corretamente.");
        errors.forEach(error => console.error(`  - ${error}`));
        process.exit(1);
    }

    console.log(`JP Tools: Playwright ${playwrightPackage.version} e Chromium ${chromiumEntry.browserVersion} validados.`);
}

finishValidation();
