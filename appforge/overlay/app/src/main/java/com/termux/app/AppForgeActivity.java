package com.termux.app;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.termux.terminal.TerminalSession;
import com.termux.terminal.TerminalSessionClient;
import com.termux.view.TerminalView;
import com.termux.view.TerminalViewClient;

import java.io.File;

public class AppForgeActivity extends Activity
    implements TerminalViewClient, TerminalSessionClient {

    private static final String TAG = "AppForge";

    private TerminalView terminalView;
    private TerminalSession terminalSession;

    private boolean volumeCtrlPressed = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        createInterface();

        terminalView.post(
            this::startTerminal
        );
    }

    private void createInterface() {
        LinearLayout root =
            new LinearLayout(this);

        root.setOrientation(
            LinearLayout.VERTICAL
        );

        root.setBackgroundColor(
            Color.rgb(12, 14, 18)
        );

        TextView header =
            new TextView(this);

        header.setText(
            "Termux AppForge   •   Volume Down = Ctrl"
        );

        header.setTextColor(
            Color.WHITE
        );

        header.setTextSize(14);

        header.setPadding(
            dp(14),
            dp(10),
            dp(14),
            dp(10)
        );

        terminalView =
            new TerminalView(
                this,
                null
            );

        terminalView.setTerminalViewClient(
            this
        );

        terminalView.setTextSize(18);

        terminalView.setBackgroundColor(
            Color.BLACK
        );

        terminalView.setFocusable(true);
        terminalView.setFocusableInTouchMode(true);

        root.addView(
            header,
            new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        );

        root.addView(
            terminalView,
            new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1.0f
            )
        );

        setContentView(root);
    }

    private void startTerminal() {
        if (terminalSession != null) {
            return;
        }

        File homeDirectory =
            new File(
                getFilesDir(),
                "home"
            );

        File tempDirectory =
            new File(
                getCacheDir(),
                "tmp"
            );

        if (!homeDirectory.exists()) {
            homeDirectory.mkdirs();
        }

        if (!tempDirectory.exists()) {
            tempDirectory.mkdirs();
        }

        String home =
            homeDirectory.getAbsolutePath();

        String temp =
            tempDirectory.getAbsolutePath();

        String shell =
            "/system/bin/sh";

        String[] environment =
            new String[] {
                "HOME=" + home,
                "TMPDIR=" + temp,
                "PATH=/system/bin:/system/xbin",
                "SHELL=" + shell,
                "TERM=xterm-256color",
                "COLORTERM=truecolor",
                "LANG=C.UTF-8"
            };

        terminalSession =
            new TerminalSession(
                shell,
                home,
                new String[0],
                environment,
                2000,
                this
            );

        terminalSession.initializeEmulator(
            80,
            24,
            8,
            16
        );

        terminalView.attachSession(
            terminalSession
        );

        terminalView.setTextSize(18);
        terminalView.requestFocus();

        terminalView.postDelayed(
            this::showKeyboard,
            300
        );

        Log.i(
            TAG,
            "Independent AppForge terminal started"
        );
    }

    private void showKeyboard() {
        terminalView.requestFocus();

        InputMethodManager keyboard =
            (InputMethodManager)
                getSystemService(
                    INPUT_METHOD_SERVICE
                );

        if (keyboard != null) {
            keyboard.showSoftInput(
                terminalView,
                InputMethodManager.SHOW_IMPLICIT
            );
        }
    }

    private int dp(int value) {
        return Math.round(
            value *
            getResources()
                .getDisplayMetrics()
                .density
        );
    }

    @Override
    public boolean dispatchKeyEvent(
        KeyEvent event
    ) {
        if (
            event.getKeyCode()
                == KeyEvent.KEYCODE_VOLUME_DOWN
        ) {
            volumeCtrlPressed =
                event.getAction()
                    == KeyEvent.ACTION_DOWN;

            return true;
        }

        return super.dispatchKeyEvent(event);
    }

    @Override
    public float onScale(float scale) {
        return 1.0f;
    }

    @Override
    public void onSingleTapUp(
        MotionEvent event
    ) {
        showKeyboard();
    }

    @Override
    public boolean shouldBackButtonBeMappedToEscape() {
        return false;
    }

    @Override
    public boolean shouldEnforceCharBasedInput() {
        return false;
    }

    @Override
    public boolean shouldUseCtrlSpaceWorkaround() {
        return false;
    }

    @Override
    public boolean isTerminalViewSelected() {
        return true;
    }

    @Override
    public void copyModeChanged(
        boolean copyMode
    ) {
    }

    @Override
    public boolean onKeyDown(
        int keyCode,
        KeyEvent event,
        TerminalSession session
    ) {
        return false;
    }

    @Override
    public boolean onKeyUp(
        int keyCode,
        KeyEvent event
    ) {
        return false;
    }

    @Override
    public boolean onLongPress(
        MotionEvent event
    ) {
        return false;
    }

    @Override
    public boolean readControlKey() {
        return volumeCtrlPressed;
    }

    @Override
    public boolean readAltKey() {
        return false;
    }

    @Override
    public boolean readShiftKey() {
        return false;
    }

    @Override
    public boolean readFnKey() {
        return false;
    }

    @Override
    public boolean onCodePoint(
        int codePoint,
        boolean ctrlDown,
        TerminalSession session
    ) {
        return false;
    }

    @Override
    public void onEmulatorSet() {
    }

    @Override
    public void onTextChanged(
        @NonNull TerminalSession changedSession
    ) {
        runOnUiThread(
            terminalView::onScreenUpdated
        );
    }

    @Override
    public void onTitleChanged(
        @NonNull TerminalSession changedSession
    ) {
    }

    @Override
    public void onSessionFinished(
        @NonNull TerminalSession finishedSession
    ) {
        Log.i(
            TAG,
            "Terminal session finished"
        );
    }

    @Override
    public void onCopyTextToClipboard(
        @NonNull TerminalSession session,
        String text
    ) {
        ClipboardManager clipboard =
            (ClipboardManager)
                getSystemService(
                    CLIPBOARD_SERVICE
                );

        if (clipboard != null) {
            clipboard.setPrimaryClip(
                ClipData.newPlainText(
                    "terminal",
                    text
                )
            );
        }
    }

    @Override
    public void onPasteTextFromClipboard(
        @Nullable TerminalSession session
    ) {
    }

    @Override
    public void onBell(
        @NonNull TerminalSession session
    ) {
    }

    @Override
    public void onColorsChanged(
        @NonNull TerminalSession session
    ) {
        runOnUiThread(
            terminalView::invalidate
        );
    }

    @Override
    public void onTerminalCursorStateChange(
        boolean state
    ) {
    }

    @Override
    public void setTerminalShellPid(
        @NonNull TerminalSession session,
        int pid
    ) {
        Log.d(
            TAG,
            "Terminal PID: " + pid
        );
    }

    @Override
    public Integer getTerminalCursorStyle() {
        return null;
    }

    @Override
    public void logError(
        String tag,
        String message
    ) {
        Log.e(tag, message);
    }

    @Override
    public void logWarn(
        String tag,
        String message
    ) {
        Log.w(tag, message);
    }

    @Override
    public void logInfo(
        String tag,
        String message
    ) {
        Log.i(tag, message);
    }

    @Override
    public void logDebug(
        String tag,
        String message
    ) {
        Log.d(tag, message);
    }

    @Override
    public void logVerbose(
        String tag,
        String message
    ) {
        Log.v(tag, message);
    }

    @Override
    public void logStackTraceWithMessage(
        String tag,
        String message,
        Exception exception
    ) {
        Log.e(
            tag,
            message,
            exception
        );
    }

    @Override
    public void logStackTrace(
        String tag,
        Exception exception
    ) {
        Log.e(
            tag,
            "Exception",
            exception
        );
    }
}
