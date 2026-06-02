import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Two layouts depending on whether the device has a sub-display lens.
//
// Default (Fenix / Epix / round watches):
//            SAUNA            <- phase / status word (colored)
//            3:01            <- time in the current phase (big)
//        total 12:34         <- total elapsed time
//     HR 132        78°C     <- heart rate | temperature
//     84 kcal       S2 R1    <- calories   | sauna/relax counts
//           14:35            <- time of day
//
// Instinct (sub-display lens in the upper-right):
//                 [icon]      <- mode icon drawn INSIDE the lens
//        3:01    [lens ]      <- phase time on the left of the lens
//           total 12:34
//     HR 132        78°C
//     84 kcal       S2 R1
//           14:35
class saunaView extends WatchUi.View {
    private var _activity as SaunaActivity;
    private var _timer as Timer.Timer?;

    public function initialize(activity as SaunaActivity) {
        View.initialize();
        _activity = activity;
    }

    public function onShow() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        (_timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    public function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
        }
    }

    public function onTick() as Void {
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var state = _activity.getState();
        var sauna = _activity.getRoundType() == ROUND_SAUNA;
        var info = Activity.getActivityInfo();

        var sub = findSubscreen();
        if (sub != null) {
            drawSubscreenLayout(dc, w, h, sub, state, sauna, info);
        } else {
            drawDefaultLayout(dc, w, h, state, sauna, info);
        }
    }

    // --- Default layout (no sub-display) ---
    private function drawDefaultLayout(
        dc as Dc, w as Number, h as Number,
        state as SaunaState, sauna as Boolean, info as Activity.Info?
    ) as Void {
        var cx = w / 2;
        var lx = w * 0.28;
        var rx = w * 0.72;

        var label;
        var labelColor;
        if (state == STATE_RUNNING) {
            label = sauna ? "SAUNA" : "RELAX";
            labelColor = sauna ? Graphics.COLOR_ORANGE : Graphics.COLOR_BLUE;
        } else if (state == STATE_PAUSED) {
            label = "PAUSED";
            labelColor = Graphics.COLOR_YELLOW;
        } else {
            label = "READY";
            labelColor = Graphics.COLOR_LT_GRAY;
        }
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.10, Graphics.FONT_TINY, label);

        var totalMs = activityTimerMs(info);
        var phaseMs = totalMs - _activity.getRoundStartMs();
        if (phaseMs < 0) { phaseMs = 0; }
        dc.setColor(
            state == STATE_PAUSED ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        drawCentered(dc, cx, h * 0.27, Graphics.FONT_NUMBER_MEDIUM, formatTime(phaseMs));

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.42, Graphics.FONT_XTINY,
            state == STATE_STOPPED ? "Press START" : "total " + formatTime(totalMs));

        drawHrTempRow(dc, lx, rx, h * 0.56, info);
        drawCalCountsRow(dc, lx, rx, h * 0.68, info);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.85, Graphics.FONT_SMALL, formatClock());
    }

    // --- Sub-display layout (Instinct etc.) ---
    private function drawSubscreenLayout(
        dc as Dc, w as Number, h as Number, sub as Graphics.BoundingBox,
        state as SaunaState, sauna as Boolean, info as Activity.Info?
    ) as Void {
        var subX = sub.x as Number;
        var subY = sub.y as Number;
        var subW = sub.width as Number;
        var subH = sub.height as Number;

        // 1) mode icon inside the lens
        drawModeIcon(dc, subX + subW / 2, subY + subH / 2, state, sauna);

        // 2) phase time (hero) to the LEFT of the lens, with total time
        //    (or the start prompt) stacked underneath it.
        var totalMs = activityTimerMs(info);
        var phaseMs = totalMs - _activity.getRoundStartMs();
        if (phaseMs < 0) { phaseMs = 0; }
        var heroCx = subX / 2;
        dc.setColor(
            state == STATE_PAUSED ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        drawCentered(dc, heroCx, subY + subH * 0.37,
            Graphics.FONT_NUMBER_MEDIUM, formatTime(phaseMs));

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, heroCx, subY + subH * 0.82, Graphics.FONT_XTINY,
            state == STATE_STOPPED ? "Press START" : "total " + formatTime(totalMs));

        // 3) everything else fills the full-width area below the lens
        var cx = w / 2;
        var lx = w * 0.28;
        var rx = w * 0.72;
        var top = subY + subH + 6;
        var area = h - top;

        drawHrTempRow(dc, lx, rx, top + area * 0.18, info);
        drawCalCountsRow(dc, lx, rx, top + area * 0.50, info);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, top + area * 0.82, Graphics.FONT_SMALL, formatClock());
    }

    // --- Shared rows ---
    private function drawHrTempRow(dc as Dc, lx as Numeric, rx as Numeric, y as Numeric, info as Activity.Info?) as Void {
        var hr = (info != null && info.currentHeartRate != null) ? (info.currentHeartRate as Number).toString() : "--";
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, y, Graphics.FONT_SMALL, "HR " + hr);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, rx, y, Graphics.FONT_SMALL, tempText());
    }

    private function drawCalCountsRow(dc as Dc, lx as Numeric, rx as Numeric, y as Numeric, info as Activity.Info?) as Void {
        var cal = (info != null && info.calories != null) ? (info.calories as Number).toString() : "--";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, y, Graphics.FONT_SMALL, cal + " kcal");
        drawCentered(dc, rx, y, Graphics.FONT_SMALL,
            "S" + _activity.getSaunaCount().toString() + " R" + _activity.getRelaxCount().toString());
    }

    // --- Mode icons drawn into the lens ---
    private function drawModeIcon(dc as Dc, cx as Number, cy as Number, state as SaunaState, sauna as Boolean) as Void {
        if (state == STATE_STOPPED) {
            drawPlayIcon(dc, cx, cy);
        } else if (state == STATE_PAUSED) {
            drawPauseIcon(dc, cx, cy);
        } else if (sauna) {
            drawFlameIcon(dc, cx, cy);
        } else {
            drawZzzIcon(dc, cx, cy);
        }
    }

    // Filled right-pointing triangle — "ready / press start".
    private function drawPlayIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx - 10, cy - 14],
            [cx - 10, cy + 14],
            [cx + 14, cy]
        ]);
    }

    // Two vertical bars — "paused".
    private function drawPauseIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 10, cy - 14, 6, 28);
        dc.fillRectangle(cx + 4, cy - 14, 6, 28);
    }

    // Teardrop flame — "SAUNA / hot".
    private function drawFlameIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx,      cy - 18],
            [cx + 6,  cy - 8],
            [cx + 10, cy + 4],
            [cx + 6,  cy + 14],
            [cx,      cy + 18],
            [cx - 6,  cy + 14],
            [cx - 10, cy + 4],
            [cx - 6,  cy - 8]
        ]);
    }

    // Big "Z" — "RELAX / rest".
    private function drawZzzIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(cx - 12, cy - 10, cx + 12, cy - 10); // top bar
        dc.drawLine(cx + 12, cy - 10, cx - 12, cy + 10); // diagonal
        dc.drawLine(cx - 12, cy + 10, cx + 12, cy + 10); // bottom bar
        dc.setPenWidth(1);
    }

    // Returns the sub-display rectangle, or null on watches without one.
    private function findSubscreen() as Graphics.BoundingBox? {
        if (WatchUi has :getSubscreen) {
            var sub = WatchUi.getSubscreen();
            if (sub != null && sub.x != null && sub.y != null
                    && sub.width != null && sub.height != null) {
                return sub;
            }
        }
        return null;
    }

    private function tempText() as String {
        var c = _activity.getCurrentTempC();
        if (c == null) {
            return "--";
        }
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
            return (c * 9.0 / 5.0 + 32.0).format("%.0f") + "°F";
        }
        return c.format("%.0f") + "°C";
    }

    private function drawCentered(dc as Dc, x as Numeric, y as Numeric, font as Graphics.FontType, text as String) as Void {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function activityTimerMs(info as Activity.Info?) as Number {
        if (info != null && info.timerTime != null) {
            return info.timerTime;
        }
        return 0;
    }

    // Format milliseconds as M:SS, or H:MM:SS once past an hour.
    private function formatTime(ms as Number) as String {
        var totalSec = ms / 1000;
        var hours = totalSec / 3600;
        var mins = (totalSec % 3600) / 60;
        var secs = totalSec % 60;
        if (hours > 0) {
            return Lang.format("$1$:$2$:$3$", [hours, mins.format("%02d"), secs.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [mins.format("%01d"), secs.format("%02d")]);
    }

    private function formatClock() as String {
        var now = System.getClockTime();
        var hour = now.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
            return Lang.format("$1$:$2$", [hour, now.min.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [hour.format("%02d"), now.min.format("%02d")]);
    }
}
