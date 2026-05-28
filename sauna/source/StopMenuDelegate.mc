import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Handles the finish menu (Resume / Save / Discard).
class StopMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _activity as SaunaActivity;

    public function initialize(activity as SaunaActivity) {
        Menu2InputDelegate.initialize();
        _activity = activity;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            _activity.startOrResume();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :save) {
            _activity.save();
            System.exit();
        } else if (id == :discard) {
            _activity.discard();
            System.exit();
        }
    }

    // Backing out of the menu just returns to the (paused) timer.
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
