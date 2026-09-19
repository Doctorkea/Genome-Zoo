import * as path from "path";

function getProjectRoot(projectPath: string | null): string {
  return path.resolve(projectPath || process.cwd());
}

function isWithinRoot(rootPath: string, targetPath: string): boolean {
  const relativePath = path.relative(rootPath, targetPath);
  return (
    relativePath === "" ||
    (!relativePath.startsWith("..") && !path.isAbsolute(relativePath))
  );
}

export function resolveProjectPath(
  inputPath: string,
  projectPath: string | null
): string {
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

export function resolveProjectDirectory(
  directory: string | undefined,
  projectPath: string | null
): string {
  if (!directory) {
    return getProjectRoot(projectPath);
  }

  return resolveProjectPath(directory, projectPath);
}

export function getProjectRelativePath(
  fullPath: string,
  projectPath: string | null
): string {
  const rootPath = getProjectRoot(projectPath);
  const resolvedPath = path.resolve(fullPath);

  if (!isWithinRoot(rootPath, resolvedPath)) {
    throw new Error(`Path escapes project root: ${fullPath}`);
  }

  return path.relative(rootPath, resolvedPath);
}
