import Toybox.Lang;
import Toybox.WatchUi;

// Button handling (Fenix / Epix layout):
//   START (top-right)    -> start; while active, pause and open the finish menu
//   BACK  (bottom-right) -> switch phase while recording; resume from pause; exit when idle
//   MENU  (long-press)   -> open the finish menu
class saunaDelegate extends WatchUi.BehaviorDelegate {
    private var _activity as SaunaActivity;

    public function initialize(activity as SaunaActivity) {
        BehaviorDelegate.initialize();
        _activity = activity;
    }

    public function onSelect() as Boolean {
        if (_activity.isActive()) {
            openFinishMenu(); // pauses, then offers Resume / Save / Discard
        } else {
            _activity.startOrResume();
            WatchUi.requestUpdate();
        }
        return true;
    }

    // BACK: contextual — switch phase while running, resume from pause, exit when idle.
    public function onBack() as Boolean {
        var state = _activity.getState();
        if (state == STATE_RUNNING) {
            _activity.switchPhase();
            WatchUi.requestUpdate();
            return true;
        }
        if (state == STATE_PAUSED) {
            _activity.startOrResume();
            WatchUi.requestUpdate();
            return true;
        }
        return false; // STOPPED -> let the system exit the app
    }

    public function onMenu() as Boolean {
        if (_activity.isActive()) {
            openFinishMenu();
            return true;
        }
        return false;
    }

    private function openFinishMenu() as Void {
        if (_activity.getState() == STATE_RUNNING) {
            _activity.pause();
        }
        var menu = new WatchUi.Menu2({ :title => "Sauna" });
        menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
        menu.addItem(new WatchUi.MenuItem("Save", "to Garmin Connect", :save, null));
        menu.addItem(new WatchUi.MenuItem("Discard", null, :discard, null));
        WatchUi.pushView(menu, new StopMenuDelegate(_activity), WatchUi.SLIDE_UP);
    }
}
