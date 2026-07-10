"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { fileURLToPath } = require("url");

const ignoredDirs = new Set([
    ".git",
    ".vscode",
    ".idea",
    "node_modules",
    "_exports",
    "exports",
    "dist",
    "build"
]);

function isInside(childPath, parentPath) {
    const relative = path.relative(parentPath, childPath);
    return relative === "" || (!relative.startsWith(".." + path.sep) && relative !== ".." && !path.isAbsolute(relative));
}

function uniqueExistingDirs(values) {
    const seen = new Set();
    const dirs = [];

    for (const value of values) {
        if (!value) continue;

        let resolved;

        try {
            resolved = path.resolve(value);
            if (!fs.statSync(resolved).isDirectory()) continue;
        } catch (error) {
            continue;
        }

        const key = process.platform === "win32" ? resolved.toLowerCase() : resolved;
        if (seen.has(key)) continue;

        seen.add(key);
        dirs.push(resolved);
    }

    return dirs;
}

function parseRootList(value) {
    if (!value) return [];

    return uniqueExistingDirs(String(value)
        .split(process.platform === "win32" ? ";" : ":")
        .map((item) => item.trim())
        .filter(Boolean));
}

function workspaceBaseDirs() {
    if (process.env.JP_VSCODE_WORKSPACES_DIR) {
        return uniqueExistingDirs([process.env.JP_VSCODE_WORKSPACES_DIR]);
    }

    const home = os.homedir();

    if (process.platform === "darwin") {
        return uniqueExistingDirs([
            path.join(home, "Library", "Application Support", "Code", "Workspaces"),
            path.join(home, "Library", "Application Support", "Code - Insiders", "Workspaces")
        ]);
    }

    if (process.platform === "win32") {
        return uniqueExistingDirs([
            process.env.APPDATA && path.join(process.env.APPDATA, "Code", "Workspaces"),
            process.env.APPDATA && path.join(process.env.APPDATA, "Code - Insiders", "Workspaces")
        ]);
    }

    return uniqueExistingDirs([
        path.join(home, ".config", "Code", "Workspaces"),
        path.join(home, ".config", "Code - Insiders", "Workspaces")
    ]);
}

function workspaceFiles() {
    const files = [];

    for (const baseDir of workspaceBaseDirs()) {
        let entries;

        try {
            entries = fs.readdirSync(baseDir, { withFileTypes: true });
        } catch (error) {
            continue;
        }

        for (const entry of entries) {
            if (!entry.isDirectory()) continue;

            const workspacePath = path.join(baseDir, entry.name, "workspace.json");

            try {
                const stat = fs.statSync(workspacePath);
                if (stat.isFile()) files.push({ path: workspacePath, mtimeMs: stat.mtimeMs });
            } catch (error) {}
        }
    }

    return files.sort((a, b) => b.mtimeMs - a.mtimeMs);
}

function folderPathFromEntry(entry, workspacePath) {
    if (!entry || typeof entry !== "object") return "";

    if (entry.path) {
        return path.isAbsolute(entry.path)
            ? entry.path
            : path.resolve(path.dirname(workspacePath), entry.path);
    }

    if (entry.uri && String(entry.uri).startsWith("file:")) {
        try {
            return fileURLToPath(entry.uri);
        } catch (error) {
            return "";
        }
    }

    return "";
}

function readWorkspaceRoots(workspacePath) {
    try {
        const data = JSON.parse(fs.readFileSync(workspacePath, "utf8"));
        return uniqueExistingDirs((data.folders || []).map((entry) => folderPathFromEntry(entry, workspacePath)));
    } catch (error) {
        return [];
    }
}

function hasProjectMarkers(dir, maxDepth = 5) {
    const queue = [{ dir, depth: 0 }];
    let visited = 0;

    while (queue.length && visited < 2500) {
        const current = queue.shift();
        visited += 1;

        let entries;

        try {
            entries = fs.readdirSync(current.dir, { withFileTypes: true });
        } catch (error) {
            continue;
        }

        const names = new Set(entries.map((entry) => entry.name.toLowerCase()));
        if (names.has("index.html") && names.has("banner")) return true;
        if (current.depth >= maxDepth) continue;

        for (const entry of entries) {
            if (!entry.isDirectory()) continue;
            if (ignoredDirs.has(entry.name) || entry.name.startsWith(".")) continue;
            queue.push({ dir: path.join(current.dir, entry.name), depth: current.depth + 1 });
        }
    }

    return false;
}

function matchingWorkspaceRoots(cwd) {
    const matches = [];

    for (const workspaceFile of workspaceFiles()) {
        const roots = readWorkspaceRoots(workspaceFile.path);
        if (roots.length < 2) continue;
        if (!roots.some((workspaceRoot) => isInside(cwd, workspaceRoot))) continue;

        const usableRoots = roots.filter((workspaceRoot) => hasProjectMarkers(workspaceRoot));
        if (usableRoots.length < 2) continue;

        matches.push({ roots: usableRoots, mtimeMs: workspaceFile.mtimeMs });
    }

    matches.sort((a, b) => b.mtimeMs - a.mtimeMs || b.roots.length - a.roots.length);
    return matches.length ? matches[0].roots : [];
}

function commonAncestor(paths) {
    if (!paths.length) return "";

    let candidate = path.resolve(paths[0]);

    while (candidate && !paths.every((itemPath) => isInside(path.resolve(itemPath), candidate))) {
        const parent = path.dirname(candidate);
        if (parent === candidate) return "";
        candidate = parent;
    }

    return candidate;
}

function rootsShareUsableBase(roots, base) {
    if (!base || base === path.parse(base).root) return false;
    if (roots.length < 2) return false;

    return roots.every((workspaceRoot) => {
        const relative = path.relative(base, workspaceRoot);
        return relative && !relative.startsWith("..") && !path.isAbsolute(relative);
    });
}

function resolveProjectContext(cwd = process.cwd()) {
    const invocationRoot = path.resolve(cwd);
    const overrideRoots = parseRootList(process.env.JP_WORKSPACE_ROOTS);
    const isVsCode = String(process.env.TERM_PROGRAM || "").toLowerCase() === "vscode" || Boolean(process.env.VSCODE_INJECTION);
    const detectedRoots = overrideRoots.length
        ? overrideRoots
        : isVsCode
            ? matchingWorkspaceRoots(invocationRoot)
            : [];
    const workspaceRoots = detectedRoots.length > 1 ? detectedRoots : [];
    const base = commonAncestor(workspaceRoots);

    if (!rootsShareUsableBase(workspaceRoots, base)) {
        return {
            root: invocationRoot,
            searchRoots: [invocationRoot],
            invocationRoot,
            isMultiRoot: false
        };
    }

    return {
        root: base,
        searchRoots: workspaceRoots,
        invocationRoot,
        isMultiRoot: true
    };
}

module.exports = {
    resolveProjectContext
};
