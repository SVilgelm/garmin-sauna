import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class saunaApp extends Application.AppBase {
    private var _activity as SaunaActivity?;

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    // If the app is exited while a session is still open (e.g. long-press
    // back, low battery), save it so the sauna isn't lost.
    public function onStop(state as Dictionary?) as Void {
        var a = _activity;
        if (a != null && a.isActive()) {
            a.save();
        }
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var a = new SaunaActivity();
        _activity = a;
        return [ new saunaView(a), new saunaDelegate(a) ];
    }
}

function getApp() as saunaApp {
    return Application.getApp() as saunaApp;
}
