import { describe, expect, it } from "vitest";
import * as path from "path";
import {
  getProjectRelativePath,
  resolveProjectDirectory,
  resolveProjectPath,
} from "./path-utils.js";

describe("path utils", () => {
  const projectRoot = path.resolve("/tmp/godot-project");

  it("resolves relative project paths", () => {
    const resolved = resolveProjectPath("scenes/main.tscn", projectRoot);
    expect(resolved).toBe(path.join(projectRoot, "scenes", "main.tscn"));
  });

  it("resolves res:// paths", () => {
    const resolved = resolveProjectPath("res://scripts/player.gd", projectRoot);
    expect(resolved).toBe(path.join(projectRoot, "scripts", "player.gd"));
  });

  it("allows absolute paths inside project root", () => {
    const inProject = path.join(projectRoot, "assets", "icon.png");
    expect(resolveProjectPath(inProject, projectRoot)).toBe(inProject);
  });

  it("rejects traversal outside project root", () => {
    expect(() => resolveProjectPath("../outside.txt", projectRoot)).toThrow(
      /escapes project root/
    );
  });

  it("rejects absolute paths outside project root", () => {
    expect(() => resolveProjectPath("/etc/passwd", projectRoot)).toThrow(
      /escapes project root/
    );
  });

  it("resolves optional directories", () => {
    expect(resolveProjectDirectory(undefined, projectRoot)).toBe(projectRoot);
    expect(resolveProjectDirectory("scenes/ui", projectRoot)).toBe(
      path.join(projectRoot, "scenes", "ui")
    );
  });

  it("computes project-relative paths", () => {
    const full = path.join(projectRoot, "resources", "data.tres");
    expect(getProjectRelativePath(full, projectRoot)).toBe(
      path.join("resources", "data.tres")
    );
  });

  it("rejects project-relative path lookup outside root", () => {
    expect(() => getProjectRelativePath("/var/tmp/file.txt", projectRoot)).toThrow(
      /escapes project root/
    );
  });
});
