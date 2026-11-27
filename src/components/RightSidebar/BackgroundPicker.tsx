/**
 * BackgroundPicker Component
 *
 * Background mode and color/gradient selection.
 */

import type { Screenshot, GradientPreset } from "../../types";
import { STYLES } from "./constants";
import { resolveGradient } from "../../lib/gradient";

interface BackgroundPickerProps {
  /** Active screenshot data */
  screenshot: Screenshot;
  /** Available gradient presets */
  gradientPresets: GradientPreset[];
  /** Update screenshot handler */
  onUpdateScreenshot: (updates: Partial<Screenshot>) => void;
}

/**
 * BackgroundPicker - Background style selector
 *
 * Toggle between solid color and gradient backgrounds.
 *
 * @param props - Component props
 */
export const BackgroundPicker = ({
  screenshot,
  gradientPresets,
  onUpdateScreenshot,
}: BackgroundPickerProps) => (
  <div>
    <label className="block text-xs text-gray-400 mb-1">Background</label>
    <div className="space-y-2">
      {/* Mode toggle */}
      <div className="flex gap-2">
        <button
          onClick={() => onUpdateScreenshot({ backgroundMode: "solid" })}
          className={`${STYLES.modeButton} ${
            screenshot.backgroundMode === "solid"
              ? STYLES.modeButtonActive
              : STYLES.modeButtonInactive
          }`}
        >
          Solid
        </button>
        <button
          onClick={() => onUpdateScreenshot({ backgroundMode: "gradient" })}
          className={`${STYLES.modeButton} ${
            screenshot.backgroundMode === "gradient"
              ? STYLES.modeButtonActive
              : STYLES.modeButtonInactive
          }`}
        >
          Gradient
        </button>
      </div>

      {/* Color picker or gradient presets */}
      {screenshot.backgroundMode === "solid" ? (
        <input
          type="color"
          value={screenshot.backgroundColor}
          onChange={(e) =>
            onUpdateScreenshot({ backgroundColor: e.target.value })
          }
          className={STYLES.colorInput}
        />
      ) : (
        <div className="flex flex-col gap-2">
          <div className="grid grid-cols-3 gap-1">
            {gradientPresets.map((preset) => (
              <button
                key={preset.id}
                onClick={() =>
                  onUpdateScreenshot({ gradientPresetId: preset.id, gradientColors: null })
                }
                className={`${STYLES.gradientButton} ${
                  !screenshot.gradientColors && screenshot.gradientPresetId === preset.id
                    ? STYLES.gradientButtonActive
                    : ""
                }`}
                style={{
                  background: `linear-gradient(135deg, ${preset.from}, ${preset.to})`,
                }}
              />
            ))}
          </div>
          {/* Custom gradient: top and bottom colors */}
          <div className="flex items-center gap-2 text-xs text-white/60">
            <span>Custom</span>
            {(["from", "to"] as const).map((stop) => {
              const current = resolveGradient(screenshot);
              return (
                <input
                  key={stop}
                  type="color"
                  value={current[stop]}
                  aria-label={stop === "from" ? "Gradient top color" : "Gradient bottom color"}
                  onChange={(e) =>
                    onUpdateScreenshot({ gradientColors: { ...current, [stop]: e.target.value } })
                  }
                  className={STYLES.colorInput}
                />
              );
            })}
          </div>
        </div>
      )}
    </div>
  </div>
);
