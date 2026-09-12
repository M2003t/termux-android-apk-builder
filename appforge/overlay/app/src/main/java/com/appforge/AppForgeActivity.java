package com.appforge;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.termux.app.TermuxActivity;

public class AppForgeActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setTitle("Termux AppForge");

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setPadding(dp(24), dp(24), dp(24), dp(24));
        root.setBackgroundColor(Color.rgb(15, 17, 22));

        TextView title = new TextView(this);
        title.setText("Termux AppForge");
        title.setTextColor(Color.WHITE);
        title.setTextSize(30);
        title.setGravity(Gravity.CENTER);

        TextView subtitle = new TextView(this);
        subtitle.setText(
            "Native Android development\n" +
            "directly on your phone"
        );
        subtitle.setTextColor(Color.LTGRAY);
        subtitle.setTextSize(16);
        subtitle.setGravity(Gravity.CENTER);
        subtitle.setPadding(0, dp(12), 0, dp(32));

        Button terminalButton = new Button(this);
        terminalButton.setText("Open Terminal");

        terminalButton.setOnClickListener(view -> {
            Intent intent =
                new Intent(
                    AppForgeActivity.this,
                    TermuxActivity.class
                );

            startActivity(intent);
        });

        root.addView(
            title,
            new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        );

        root.addView(
            subtitle,
            new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        );

        root.addView(
            terminalButton,
            new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(56)
            )
        );

        setContentView(root);
    }

    private int dp(int value) {
        float density =
            getResources()
                .getDisplayMetrics()
                .density;

        return Math.round(value * density);
    }
}
