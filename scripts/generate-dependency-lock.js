#!/usr/bin/env node

"use strict";

const crypto = require("crypto");
const fs = require("fs");
const https = require("https");
const path = require("path");

const root = path.resolve(__dirname, "..");
const outputPath = path.join(root, "dependencies.lock.json");
const lockedFormulaNames = ["ffmpeg", "imagemagick", "jpegoptim", "oxipng", "pngquant"];

const lockedWindowsPackages = {
    ffmpeg: {
        id: "Gyan.FFmpeg",
        version: "8.1.2",
        manifestUrl: "https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/g/Gyan/FFmpeg/8.1.2/Gyan.FFmpeg.installer.yaml",
        installerSha256: {
            x64: "B8CDEFAB5F50590A076C27C2B56B0294A0E6154FADED28BA1BA05EBC4F801F57"
        }
    },
    imagemagick: {
        id: "ImageMagick.ImageMagick",
        version: "7.1.2.27",
        manifestUrl: "https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/i/ImageMagick/ImageMagick/7.1.2.27/ImageMagick.ImageMagick.installer.yaml",
        installerSha256: {
            x64: "96EB3DCC1E787F92766CE164879F52D66272233C34B03B04C448D0D17261A03E",
            arm64: "759A894E220E53981F872EB55D75D29EBCE3C0BD9570E61A28556EDA8CD77AE7"
        }
    }
};

function fetchText(url) {
    return new Promise((resolve, reject) => {
        https.get(url, { headers: { "User-Agent": "JP-Tools dependency lock generator" } }, response => {
            if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
                response.resume();
                fetchText(response.headers.location).then(resolve, reject);
                return;
            }
            if (response.statusCode !== 200) {
                response.resume();
                reject(new Error(`HTTP ${response.statusCode} for ${url}`));
                return;
            }
            let body = "";
            response.setEncoding("utf8");
            response.on("data", chunk => { body += chunk; });
            response.on("end", () => resolve(body));
        }).on("error", reject);
    });
}

async function fetchJson(url) {
    return JSON.parse(await fetchText(url));
}

async function main() {
    const previousLock = fs.existsSync(outputPath) ? JSON.parse(fs.readFileSync(outputPath, "utf8")) : {};
    const legacyPinnedFormulae = previousLock.migration?.unpinFormulae || Object.keys(previousLock.macos?.formulae || {});
    const lockedFormulae = {};

    for (const name of lockedFormulaNames.sort()) {
        const data = await fetchJson(`https://formulae.brew.sh/api/formula/${encodeURIComponent(name)}.json`);
        const revision = Number(data.revision || 0);
        lockedFormulae[name] = {
            version: data.versions.stable,
            revision,
            installedVersion: `${data.versions.stable}${revision ? `_${revision}` : ""}`,
            formulaSha256: data.ruby_source_checksum.sha256,
            dependencies: data.dependencies,
            bottles: Object.fromEntries(Object.entries(data.bottle.stable.files).map(([tag, bottle]) => [
                tag,
                { url: bottle.url, sha256: bottle.sha256 }
            ]))
        };
    }

    for (const packageData of Object.values(lockedWindowsPackages)) {
        const manifest = await fetchText(packageData.manifestUrl);
        packageData.manifestSha256 = crypto.createHash("sha256").update(manifest).digest("hex").toUpperCase();
    }

    const lock = {
        schemaVersion: 2,
        jpToolsVersion: "1.2.3",
        generatedAt: new Date().toISOString(),
        policy: {
            automaticallyUpdated: ["Node.js", "Playwright", "Chromium", "WebP"],
            versionLocked: ["FFmpeg", "ImageMagick", "jpegoptim", "pngquant", "oxipng"]
        },
        macos: {
            dynamicFormulae: ["node", "webp"],
            lockedFormulae
        },
        windows: {
            dynamicPackages: {
                node: { id: "OpenJS.NodeJS.LTS" }
            },
            lockedPackages: lockedWindowsPackages
        },
        migration: {
            unpinFormulae: legacyPinnedFormulae.sort()
        }
    };

    fs.writeFileSync(outputPath, `${JSON.stringify(lock, null, 2)}\n`);
    console.log(`Created ${outputPath} with ${lockedFormulaNames.length} locked third-party formulae.`);
}

main().catch(error => {
    console.error(`Dependency lock error: ${error.message}`);
    process.exit(1);
});
