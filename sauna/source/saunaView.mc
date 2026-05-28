import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Single dashboard showing everything at once:
//
//            SAUNA            <- phase / status (colored)
//            3:01            <- time in the current phase (big)
//        total 12:34         <- total elapsed time
//     HR 132        78°C     <- heart rate | temperature
//     84 kcal       S2 R1    <- calories   | sauna/relax counts
//           14:35            <- time of day
class saunaView extends WatchUi.View {
    private var _activity as SaunaActivity;
    private var _timer as Timer.Timer?;

    public function initialize(activity as SaunaActivity) {
        View.initialize();
        _activity = activity;
    }

    // Refresh the screen once a second while the view is visible.
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
        var cx = w / 2;
        var lx = w * 0.28; // left metric column
        var rx = w * 0.72; // right metric column

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var state = _activity.getState();
        var sauna = _activity.getRoundType() == ROUND_SAUNA;
        var info = Activity.getActivityInfo();

        // 1) phase / status header
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

        // 2) time in the current phase (hero)
        var totalMs = activityTimerMs(info);
        var phaseMs = totalMs - _activity.getRoundStartMs();
        if (phaseMs < 0) {
            phaseMs = 0;
        }
        dc.setColor(
            state == STATE_PAUSED ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        drawCentered(dc, cx, h * 0.27, Graphics.FONT_NUMBER_MEDIUM, formatTime(phaseMs));

        // 3) total elapsed time, or the start prompt when idle
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (state == STATE_STOPPED) {
            drawCentered(dc, cx, h * 0.42, Graphics.FONT_XTINY, "Press START");
        } else {
            drawCentered(dc, cx, h * 0.42, Graphics.FONT_XTINY, "total " + formatTime(totalMs));
        }

        // 4) HR | temperature
        var hr = (info != null && info.currentHeartRate != null) ? (info.currentHeartRate as Number).toString() : "--";
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, h * 0.56, Graphics.FONT_SMALL, "HR " + hr);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, rx, h * 0.56, Graphics.FONT_SMALL, tempText());

        // 5) calories | sauna/relax counts
        var cal = (info != null && info.calories != null) ? (info.calories as Number).toString() : "--";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, h * 0.68, Graphics.FONT_SMALL, cal + " kcal");
        drawCentered(dc, rx, h * 0.68, Graphics.FONT_SMALL,
            "S" + _activity.getSaunaCount().toString() + " R" + _activity.getRelaxCount().toString());

        // 6) time of day
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.85, Graphics.FONT_SMALL, formatClock());
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
