#!/usr/bin/env node

"use strict";

const { execFileSync } = require("child_process");
const crypto = require("crypto");
const fs = require("fs");
const https = require("https");
const path = require("path");

const root = path.resolve(__dirname, "..");
const runtimeLockPath = path.join(root, "runtime", "package-lock.json");
const outputPath = path.join(root, "dependencies.lock.json");
const directFormulae = [
    "node@24",
    "ffmpeg",
    "jpegoptim",
    "pngquant",
    "oxipng",
    "webp",
    "imagemagick"
];

const windowsPackages = {
    node: {
        id: "OpenJS.NodeJS.LTS",
        version: "24.18.0",
        manifestUrl: "https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/o/OpenJS/NodeJS/LTS/24.18.0/OpenJS.NodeJS.LTS.installer.yaml",
        installerSha256: {
            x64: "E30CD4CA15529583AFE0EFC978F1AE3AB3A93C2400C222D0752D17900552EBB3",
            arm64: "F6E4A38E2D1F27D7E106B22C070CA5C2D653ABFC38C6BEA42D6C9358499391E2"
        }
    },
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

function sha256(filePath) {
    return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

async function main() {
    if (!fs.existsSync(runtimeLockPath)) {
        throw new Error("runtime/package-lock.json not found. Run npm install --package-lock-only inside runtime first.");
    }

    const dependencies = execFileSync("brew", [
        "deps",
        "--union",
        "--full-name",
        ...directFormulae
    ], {
        encoding: "utf8",
        env: { ...process.env, HOMEBREW_NO_ENV_HINTS: "1" }
    }).trim().split(/\r?\n/).filter(Boolean);

    const names = [...new Set([...directFormulae, ...dependencies])].sort();
    const formulae = {};

    for (const name of names) {
        const encodedName = encodeURIComponent(name);
        const data = await fetchJson(`https://formulae.brew.sh/api/formula/${encodedName}.json`);
        const revision = Number(data.revision || 0);
        const installedVersion = `${data.versions.stable}${revision ? `_${revision}` : ""}`;
        formulae[name] = {
            version: data.versions.stable,
            revision,
            installedVersion,
            formulaSha256: data.ruby_source_checksum.sha256,
            dependencies: data.dependencies,
            bottles: Object.fromEntries(Object.entries(data.bottle.stable.files).map(([tag, bottle]) => [
                tag,
                {
                    url: bottle.url,
                    sha256: bottle.sha256
                }
            ]))
        };
    }

    const runtimeLock = JSON.parse(fs.readFileSync(runtimeLockPath, "utf8"));
    const playwrightPackage = runtimeLock.packages["node_modules/playwright"];
    const playwrightCorePackage = runtimeLock.packages["node_modules/playwright-core"];

    for (const packageData of Object.values(windowsPackages)) {
        const manifest = await fetchText(packageData.manifestUrl);
        packageData.manifestSha256 = crypto.createHash("sha256").update(manifest).digest("hex").toUpperCase();
    }

    const lock = {
        schemaVersion: 1,
        jpToolsVersion: "1.2.4",
        generatedAt: new Date().toISOString(),
        npmRuntime: {
            packageLockSha256: sha256(runtimeLockPath),
            playwright: {
                version: playwrightPackage.version,
                integrity: playwrightPackage.integrity
            },
            playwrightCore: {
                version: playwrightCorePackage.version,
                integrity: playwrightCorePackage.integrity
            },
            chromium: {
                revision: "1228",
                browserVersion: "149.0.7827.55"
            }
        },
        macos: {
            directFormulae,
            formulae
        },
        windows: {
            packages: windowsPackages
        }
    };

    fs.writeFileSync(outputPath, `${JSON.stringify(lock, null, 2)}\n`);
    console.log(`Created ${outputPath} with ${names.length} locked Homebrew formulae.`);
}

main().catch(error => {
    console.error(`Dependency lock error: ${error.message}`);
    process.exit(1);
});
