import { gradientPresets } from "../constants";
import type { Screenshot } from "../types";

/**
 * Colors of a screenshot's gradient background: its own custom colors when
 * set (so every app can use its brand gradient), otherwise its preset.
 */
export const resolveGradient = (
  screenshot: Pick<Screenshot, "gradientPresetId" | "gradientColors">,
): { from: string; to: string } => {
  if (screenshot.gradientColors) return screenshot.gradientColors;
  const preset =
    gradientPresets.find((p) => p.id === screenshot.gradientPresetId) ??
    gradientPresets[0];
  return { from: preset.from, to: preset.to };
};
