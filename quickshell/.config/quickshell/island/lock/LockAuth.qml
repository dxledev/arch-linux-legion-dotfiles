import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    property bool locked: false
    property string buffer: ""
    property string error: ""
    property string config: "passwd"
    property string configDirectory: Quickshell.shellDir + "/assets/pam.d"
    property int retryDelay: 1500
    property int authenticationTimeout: 15000
    readonly property bool busy: authenticating
    readonly property bool canSubmit: locked && !busy && !retry.running
    property bool authenticating: false
    property bool submitPending: false
    property bool responseSent: false
    property string submittedPassword: ""

    signal authenticated()

    function submit(): void {
        if (!locked || buffer.length === 0)
            return;
        if (busy)
            cancelAuthentication();
        submitPending = true;
        if (!retry.running)
            startAuthentication();
    }

    function cancelAuthentication(): void {
        timeout.stop();
        pam.abort();
        submittedPassword = "";
        authenticating = false;
        responseSent = false;
    }

    function startAuthentication(): void {
        submitPending = false;
        if (!canSubmit || buffer.length === 0)
            return;
        error = "";
        responseSent = false;
        submittedPassword = buffer;
        buffer = "";
        authenticating = true;
        if (!pam.start()) {
            submittedPassword = "";
            authenticating = false;
            error = "Authentication unavailable. Try again.";
            console.info("Island lock: authentication could not start");
        } else {
            timeout.restart();
            console.info("Island lock: authentication started");
        }
    }

    function reset(): void {
        cancelAuthentication();
        buffer = "";
        error = "";
        submitPending = false;
        retry.stop();
    }

    onLockedChanged: reset()

    PamContext {
        id: pam
        config: root.config
        configDirectory: root.configDirectory
        onPamMessage: {
            if (messageIsError)
                root.error = message;
            if (!responseRequired)
                return;
            // Never reuse the password for another prompt in a PAM conversation.
            if (root.responseSent) {
                root.cancelAuthentication();
                root.error = "Unexpected authentication prompt. Try again.";
                retry.restart();
                console.info("Island lock: additional PAM prompt rejected");
                return;
            }
            root.responseSent = true;
            respond(root.submittedPassword);
            root.submittedPassword = "";
        }
        onCompleted: result => {
            timeout.stop();
            console.info("Island lock: PAM result " + PamResult.toString(result));
            root.submittedPassword = "";
            if (!root.locked) {
                root.authenticating = false;
                return;
            }
            if (result === PamResult.Success) {
                root.error = "";
                root.authenticating = false;
                root.authenticated();
                return;
            }
            if (!root.error)
                root.error = result === PamResult.Error ? "Authentication unavailable. Try again."
                    : result === PamResult.MaxTries ? "Too many attempts. Please wait and try again."
                    : "Incorrect password. Try again.";
            retry.restart();
            root.authenticating = false;
        }
    }

    Timer {
        id: retry
        interval: root.retryDelay
        onTriggered: if (root.submitPending) root.startAuthentication()
    }

    Timer {
        id: timeout
        interval: root.authenticationTimeout
        onTriggered: {
            root.cancelAuthentication();
            root.error = "Authentication timed out. Enter your password and try again.";
            console.info("Island lock: stalled authentication cancelled");
        }
    }
}
