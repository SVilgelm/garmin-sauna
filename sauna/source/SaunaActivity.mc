import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Timer;

// Recording state machine for a sauna session.
enum SaunaState {
    STATE_STOPPED, // no open session (initial state, or after save/discard)
    STATE_RUNNING, // timer active, recording
    STATE_PAUSED   // session open but timer stopped
}

// The two kinds of phase a sauna session alternates between.
enum RoundType {
    ROUND_SAUNA, // in the hot room
    ROUND_RELAX  // cool down / rest
}

// Wraps an ActivityRecording.Session and exposes a tiny state machine.
// A sauna is recorded as a generic "Cardio" training activity (no GPS),
// so it shows up in Garmin Connect with duration, heart rate and calories.
class SaunaActivity {
    private var _session as ActivityRecording.Session?;
    private var _state as SaunaState;
    private var _roundType as RoundType; // current phase: sauna or relax
    private var _saunaCount as Number;
    private var _relaxCount as Number;
    private var _roundStartMs as Number; // timerTime when the current phase began
    private var _tempField as FitContributor.Field?; // records temperature into the FIT
    private var _sampleTimer as Timer.Timer?;
    private var _currentTempC as Float?;

    public function initialize() {
        _session = null;
        _state = STATE_STOPPED;
        _roundType = ROUND_SAUNA;
        _saunaCount = 1;
        _relaxCount = 0;
        _roundStartMs = 0;
        _tempField = null;
        _sampleTimer = null;
        _currentTempC = null;
    }

    public function getState() as SaunaState {
        return _state;
    }

    public function getRoundType() as RoundType {
        return _roundType;
    }

    public function getSaunaCount() as Number {
        return _saunaCount;
    }

    public function getRelaxCount() as Number {
        return _relaxCount;
    }

    // Latest ambient temperature in Celsius, or null if unavailable.
    public function getCurrentTempC() as Float? {
        return _currentTempC;
    }

    // timerTime (moving ms) at which the current phase started.
    public function getRoundStartMs() as Number {
        return _roundStartMs;
    }

    public function isActive() as Boolean {
        return _state != STATE_STOPPED;
    }

    // Start a brand-new session, or resume a paused one.
    public function startOrResume() as Void {
        var s = _session;
        if (s == null) {
            s = ActivityRecording.createSession({
                :name => "Sauna",
                :sport => Activity.SPORT_TRAINING,
                :subSport => Activity.SUB_SPORT_CARDIO_TRAINING
            });
            _tempField = s.createField(
                "temperature", 0, FitContributor.DATA_TYPE_FLOAT,
                { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "C" }
            );
            _session = s;
            _roundType = ROUND_SAUNA;
            _saunaCount = 1;
            _relaxCount = 0;
            _roundStartMs = 0;
        }
        if (!s.isRecording()) {
            s.start();
        }
        _state = STATE_RUNNING;
        startSampling();
        vibe(50, 200);
    }

    // Pause the timer but keep the session open.
    public function pause() as Void {
        var s = _session;
        if (s != null && s.isRecording()) {
            s.stop();
        }
        stopSampling();
        _state = STATE_PAUSED;
        vibe(50, 100);
    }

    // Switch between the sauna and relax phases. Each switch closes the
    // current lap and opens a new one. Returns true if it happened.
    public function switchPhase() as Boolean {
        var s = _session;
        if (s != null && s.isRecording()) {
            s.addLap();
            if (_roundType == ROUND_SAUNA) {
                _roundType = ROUND_RELAX;
                _relaxCount += 1;
            } else {
                _roundType = ROUND_SAUNA;
                _saunaCount += 1;
            }
            var info = Activity.getActivityInfo();
            _roundStartMs = (info != null && info.timerTime != null) ? info.timerTime : 0;
            vibe(75, 150);
            return true;
        }
        return false;
    }

    // Stop the timer (if needed) and write the activity to history.
    public function save() as Void {
        stopSampling();
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.save();
        }
        _session = null;
        _state = STATE_STOPPED;
        vibe(100, 400);
    }

    // Throw the session away without saving.
    public function discard() as Void {
        stopSampling();
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.discard();
        }
        _session = null;
        _state = STATE_STOPPED;
    }

    private function startSampling() as Void {
        if (_sampleTimer == null) {
            _sampleTimer = new Timer.Timer();
        }
        (_sampleTimer as Timer.Timer).start(method(:sampleTemperature), 1000, true);
        sampleTemperature(); // capture one reading immediately
    }

    private function stopSampling() as Void {
        if (_sampleTimer != null) {
            (_sampleTimer as Timer.Timer).stop();
        }
    }

    // Read the current temperature and attach it to the FIT record stream.
    public function sampleTemperature() as Void {
        var c = readTemperatureC();
        _currentTempC = c;
        if (c != null && _tempField != null) {
            (_tempField as FitContributor.Field).setData(c);
        }
    }

    private function readTemperatureC() as Float? {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getTemperatureHistory)) {
            var iter = SensorHistory.getTemperatureHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST });
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Numeric).toFloat();
                }
            }
        }
        return null;
    }

    private function vibe(intensity as Number, durationMs as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(
                [new Attention.VibeProfile(intensity, durationMs)] as Array<Attention.VibeProfile>
            );
        }
    }
}
