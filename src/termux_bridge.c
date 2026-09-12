#include <jni.h>
#include <android/native_activity.h>
#include <android_native_app_glue.h>

struct android_app *GetAndroidApp(void);

static int check_exception(JNIEnv *env) {
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionClear(env);
        return 1;
    }
    return 0;
}

int termux_run_test(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity) return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    JNIEnv *env = NULL;
    int attached = 0;

    if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) != JNI_OK) {
        if ((*vm)->AttachCurrentThread(vm, (void **)&env, NULL) != JNI_OK)
            return -2;

        attached = 1;
    }

    jclass intentClass = (*env)->FindClass(env, "android/content/Intent");
    if (!intentClass || check_exception(env)) return -3;

    jmethodID intentCtor =
        (*env)->GetMethodID(env, intentClass, "<init>", "()V");

    jobject intent =
        (*env)->NewObject(env, intentClass, intentCtor);

    jmethodID setClassName =
        (*env)->GetMethodID(
            env,
            intentClass,
            "setClassName",
            "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;"
        );

    jmethodID setAction =
        (*env)->GetMethodID(
            env,
            intentClass,
            "setAction",
            "(Ljava/lang/String;)Landroid/content/Intent;"
        );

    jmethodID putStringExtra =
        (*env)->GetMethodID(
            env,
            intentClass,
            "putExtra",
            "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;"
        );

    jmethodID putStringArrayExtra =
        (*env)->GetMethodID(
            env,
            intentClass,
            "putExtra",
            "(Ljava/lang/String;[Ljava/lang/String;)Landroid/content/Intent;"
        );

    jmethodID putBooleanExtra =
        (*env)->GetMethodID(
            env,
            intentClass,
            "putExtra",
            "(Ljava/lang/String;Z)Landroid/content/Intent;"
        );

    jstring termuxPackage =
        (*env)->NewStringUTF(env, "com.termux");

    jstring serviceName =
        (*env)->NewStringUTF(env, "com.termux.app.RunCommandService");

    (*env)->CallObjectMethod(
        env,
        intent,
        setClassName,
        termuxPackage,
        serviceName
    );

    jstring action =
        (*env)->NewStringUTF(env, "com.termux.RUN_COMMAND");

    (*env)->CallObjectMethod(
        env,
        intent,
        setAction,
        action
    );

    jstring pathKey =
        (*env)->NewStringUTF(env, "com.termux.RUN_COMMAND_PATH");

    jstring bashPath =
        (*env)->NewStringUTF(
            env,
            "/data/data/com.termux/files/usr/bin/bash"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        putStringExtra,
        pathKey,
        bashPath
    );

    jclass stringClass =
        (*env)->FindClass(env, "java/lang/String");

    jobjectArray args =
        (*env)->NewObjectArray(env, 2, stringClass, NULL);

    jstring arg0 =
        (*env)->NewStringUTF(env, "-lc");

    jstring arg1 =
        (*env)->NewStringUTF(
            env,
            "echo 'Hello from Termux AppForge' > ~/termux_appforge_bridge_test.txt"
        );

    (*env)->SetObjectArrayElement(env, args, 0, arg0);
    (*env)->SetObjectArrayElement(env, args, 1, arg1);

    jstring argsKey =
        (*env)->NewStringUTF(
            env,
            "com.termux.RUN_COMMAND_ARGUMENTS"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        putStringArrayExtra,
        argsKey,
        args
    );

    jstring backgroundKey =
        (*env)->NewStringUTF(
            env,
            "com.termux.RUN_COMMAND_BACKGROUND"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        putBooleanExtra,
        backgroundKey,
        JNI_TRUE
    );

    if (check_exception(env)) return -4;

    jclass activityClass =
        (*env)->GetObjectClass(env, activity);

    jmethodID startService =
        (*env)->GetMethodID(
            env,
            activityClass,
            "startService",
            "(Landroid/content/Intent;)Landroid/content/ComponentName;"
        );

    jobject result =
        (*env)->CallObjectMethod(
            env,
            activity,
            startService,
            intent
        );

    if (check_exception(env) || result == NULL)
        return -5;

    if (attached)
        (*vm)->DetachCurrentThread(vm);

    return 0;
}
