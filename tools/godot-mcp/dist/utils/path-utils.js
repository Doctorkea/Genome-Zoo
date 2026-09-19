import * as path from "path";
function getProjectRoot(projectPath) {
    return path.resolve(projectPath || process.cwd());
}
function isWithinRoot(rootPath, targetPath) {
    const relativePath = path.relative(rootPath, targetPath);
    return (relativePath === "" ||
        (!relativePath.startsWith("..") && !path.isAbsolute(relativePath)));
}
export function resolveProjectPath(inputPath, projectPath) {
    let normalizedInput = inputPath.trim();
    if (!normalizedInput) {
        throw new Error("Path cannot be empty");
    }
    if (normalizedInput.startsWith("res://")) {
        normalizedInput = normalizedInput.slice(6);
    }
    const rootPath = getProjectRoot(projectPath);
    const resolvedPath = path.isAbsolute(normalizedInput)
        ? path.resolve(normalizedInput)
        : path.resolve(rootPath, normalizedInput);
    if (!isWithinRoot(rootPath, resolvedPath)) {
        throw new Error(`Path escapes project root: ${inputPath}`);
    }
    return resolvedPath;
}
export function resolveProjectDirectory(directory, projectPath) {
    if (!directory) {
        return getProjectRoot(projectPath);
    }
    return resolveProjectPath(directory, projectPath);
}
export function getProjectRelativePath(fullPath, projectPath) {
    const rootPath = getProjectRoot(projectPath);
    const resolvedPath = path.resolve(fullPath);
    if (!isWithinRoot(rootPath, resolvedPath)) {
        throw new Error(`Path escapes project root: ${fullPath}`);
    }
    return path.relative(rootPath, resolvedPath);
}
//# sourceMappingURL=path-utils.js.map