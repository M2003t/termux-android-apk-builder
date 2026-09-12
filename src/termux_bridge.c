#include <jni.h>
#include <stdio.h>
#include <string.h>

#include "raylib.h"
#include "android_native_app_glue.h"
extern struct android_app *GetAndroidApp(void);

#define TERMUX_PACKAGE "com.termux"
#define TERMUX_PERMISSION "com.termux.permission.RUN_COMMAND"
#define TERMUX_SERVICE "com.termux.app.RunCommandService"

static char versionBuffer[128] = "unknown";

static JNIEnv *get_env(JavaVM *vm, int *attached) {
    JNIEnv *env = NULL;
    *attached = 0;

    jint status = (*vm)->GetEnv(
        vm,
        (void **)&env,
        JNI_VERSION_1_6
    );

    if (status == JNI_OK)
        return env;

    if ((*vm)->AttachCurrentThread(vm, &env, NULL) != JNI_OK)
        return NULL;

    *attached = 1;
    return env;
}

static int check_exception(JNIEnv *env) {
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
        return 1;
    }

    return 0;
}

static void detach_if_needed(JavaVM *vm, int attached) {
    if (attached)
        (*vm)->DetachCurrentThread(vm);
}


/* ---------------------------------------------------------
   Is Termux installed and visible?
   1  = yes
   0  = no / not visible
   <0 = JNI diagnostic error
   --------------------------------------------------------- */
int termux_package_status(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity)
        return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    int attached = 0;
    JNIEnv *env = get_env(vm, &attached);

    if (!env)
        return -2;

    jclass activityClass =
        (*env)->GetObjectClass(env, activity);

    jmethodID getPackageManager =
        (*env)->GetMethodID(
            env,
            activityClass,
            "getPackageManager",
            "()Landroid/content/pm/PackageManager;"
        );

    if (!getPackageManager || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -3;
    }

    jobject packageManager =
        (*env)->CallObjectMethod(
            env,
            activity,
            getPackageManager
        );

    if (!packageManager || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -4;
    }

    jclass pmClass =
        (*env)->GetObjectClass(env, packageManager);

    jmethodID getPackageInfo =
        (*env)->GetMethodID(
            env,
            pmClass,
            "getPackageInfo",
            "(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;"
        );

    if (!getPackageInfo || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -5;
    }

    jstring packageName =
        (*env)->NewStringUTF(env, TERMUX_PACKAGE);

    jobject packageInfo =
        (*env)->CallObjectMethod(
            env,
            packageManager,
            getPackageInfo,
            packageName,
            0
        );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return 0;
    }

    int result = packageInfo ? 1 : 0;

    detach_if_needed(vm, attached);
    return result;
}


/* ---------------------------------------------------------
   Does Android know the RUN_COMMAND permission definition?
   --------------------------------------------------------- */
int termux_permission_definition_status(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity)
        return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    int attached = 0;
    JNIEnv *env = get_env(vm, &attached);

    if (!env)
        return -2;

    jclass activityClass =
        (*env)->GetObjectClass(env, activity);

    jmethodID getPackageManager =
        (*env)->GetMethodID(
            env,
            activityClass,
            "getPackageManager",
            "()Landroid/content/pm/PackageManager;"
        );

    jobject packageManager =
        (*env)->CallObjectMethod(
            env,
            activity,
            getPackageManager
        );

    if (!packageManager || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -3;
    }

    jclass pmClass =
        (*env)->GetObjectClass(env, packageManager);

    jmethodID getPermissionInfo =
        (*env)->GetMethodID(
            env,
            pmClass,
            "getPermissionInfo",
            "(Ljava/lang/String;I)Landroid/content/pm/PermissionInfo;"
        );

    if (!getPermissionInfo || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -4;
    }

    jstring permission =
        (*env)->NewStringUTF(
            env,
            TERMUX_PERMISSION
        );

    jobject permissionInfo =
        (*env)->CallObjectMethod(
            env,
            packageManager,
            getPermissionInfo,
            permission,
            0
        );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return 0;
    }

    int result = permissionInfo ? 1 : 0;

    detach_if_needed(vm, attached);
    return result;
}


/* ---------------------------------------------------------
   Current grant state for our APK
   1 = granted
   0 = denied
   --------------------------------------------------------- */
int termux_permission_status(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity)
        return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    int attached = 0;
    JNIEnv *env = get_env(vm, &attached);

    if (!env)
        return -2;

    jclass activityClass =
        (*env)->GetObjectClass(env, activity);

    jmethodID checkSelfPermission =
        (*env)->GetMethodID(
            env,
            activityClass,
            "checkSelfPermission",
            "(Ljava/lang/String;)I"
        );

    if (!checkSelfPermission || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -3;
    }

    jstring permission =
        (*env)->NewStringUTF(
            env,
            TERMUX_PERMISSION
        );

    jint result =
        (*env)->CallIntMethod(
            env,
            activity,
            checkSelfPermission,
            permission
        );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return -4;
    }

    detach_if_needed(vm, attached);

    return result == 0 ? 1 : 0;
}


/* ---------------------------------------------------------
   Ask Android PermissionController for RUN_COMMAND
   --------------------------------------------------------- */
int termux_request_permission(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity)
        return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    int attached = 0;
    JNIEnv *env = get_env(vm, &attached);

    if (!env)
        return -2;

    jclass activityClass =
        (*env)->GetObjectClass(env, activity);

    jmethodID requestPermissions =
        (*env)->GetMethodID(
            env,
            activityClass,
            "requestPermissions",
            "([Ljava/lang/String;I)V"
        );

    if (!requestPermissions || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -3;
    }

    jclass stringClass =
        (*env)->FindClass(
            env,
            "java/lang/String"
        );

    jobjectArray permissions =
        (*env)->NewObjectArray(
            env,
            1,
            stringClass,
            NULL
        );

    jstring permission =
        (*env)->NewStringUTF(
            env,
            TERMUX_PERMISSION
        );

    (*env)->SetObjectArrayElement(
        env,
        permissions,
        0,
        permission
    );

    (*env)->CallVoidMethod(
        env,
        activity,
        requestPermissions,
        permissions,
        1001
    );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return -4;
    }

    detach_if_needed(vm, attached);
    return 0;
}


/* ---------------------------------------------------------
   Open our Android App Info page
   --------------------------------------------------------- */
int termux_open_app_settings(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity)
        return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    int attached = 0;
    JNIEnv *env = get_env(vm, &attached);

    if (!env)
        return -2;

    jclass intentClass =
        (*env)->FindClass(
            env,
            "android/content/Intent"
        );

    jclass uriClass =
        (*env)->FindClass(
            env,
            "android/net/Uri"
        );

    if (!intentClass ||
        !uriClass ||
        check_exception(env)) {

        detach_if_needed(vm, attached);
        return -3;
    }

    jmethodID parseUri =
        (*env)->GetStaticMethodID(
            env,
            uriClass,
            "parse",
            "(Ljava/lang/String;)Landroid/net/Uri;"
        );

    jstring packageUri =
        (*env)->NewStringUTF(
            env,
            "package:com.m2003t.termuxappforge"
        );

    jobject uri =
        (*env)->CallStaticObjectMethod(
            env,
            uriClass,
            parseUri,
            packageUri
        );

    jmethodID ctor =
        (*env)->GetMethodID(
            env,
            intentClass,
            "<init>",
            "(Ljava/lang/String;Landroid/net/Uri;)V"
        );

    jstring action =
        (*env)->NewStringUTF(
            env,
            "android.settings.APPLICATION_DETAILS_SETTINGS"
        );

    jobject intent =
        (*env)->NewObject(
            env,
            intentClass,
            ctor,
            action,
            uri
        );

    jclass activityClass =
        (*env)->GetObjectClass(
            env,
            activity
        );

    jmethodID startActivity =
        (*env)->GetMethodID(
            env,
            activityClass,
            "startActivity",
            "(Landroid/content/Intent;)V"
        );

    (*env)->CallVoidMethod(
        env,
        activity,
        startActivity,
        intent
    );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return -4;
    }

    detach_if_needed(vm, attached);
    return 0;
}


/* ---------------------------------------------------------
   Send a real RUN_COMMAND intent to Termux
   --------------------------------------------------------- */
int termux_run_test(void) {
    struct android_app *app = GetAndroidApp();

    if (!app || !app->activity)
        return -1;

    JavaVM *vm = app->activity->vm;
    jobject activity = app->activity->clazz;

    int attached = 0;
    JNIEnv *env = get_env(vm, &attached);

    if (!env)
        return -2;

    jclass intentClass =
        (*env)->FindClass(
            env,
            "android/content/Intent"
        );

    if (!intentClass || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -3;
    }

    jmethodID ctor =
        (*env)->GetMethodID(
            env,
            intentClass,
            "<init>",
            "()V"
        );

    jobject intent =
        (*env)->NewObject(
            env,
            intentClass,
            ctor
        );

    jmethodID setClassName =
        (*env)->GetMethodID(
            env,
            intentClass,
            "setClassName",
            "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;"
        );

    jstring packageName =
        (*env)->NewStringUTF(
            env,
            TERMUX_PACKAGE
        );

    jstring serviceName =
        (*env)->NewStringUTF(
            env,
            TERMUX_SERVICE
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        setClassName,
        packageName,
        serviceName
    );

    jmethodID setAction =
        (*env)->GetMethodID(
            env,
            intentClass,
            "setAction",
            "(Ljava/lang/String;)Landroid/content/Intent;"
        );

    jstring action =
        (*env)->NewStringUTF(
            env,
            "com.termux.RUN_COMMAND"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        setAction,
        action
    );

    jmethodID putExtraString =
        (*env)->GetMethodID(
            env,
            intentClass,
            "putExtra",
            "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;"
        );

    jstring pathKey =
        (*env)->NewStringUTF(
            env,
            "com.termux.RUN_COMMAND_PATH"
        );

    jstring bashPath =
        (*env)->NewStringUTF(
            env,
            "/data/data/com.termux/files/usr/bin/bash"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        putExtraString,
        pathKey,
        bashPath
    );

    jclass stringClass =
        (*env)->FindClass(
            env,
            "java/lang/String"
        );

    jobjectArray args =
        (*env)->NewObjectArray(
            env,
            2,
            stringClass,
            NULL
        );

    jstring arg0 =
        (*env)->NewStringUTF(
            env,
            "-lc"
        );

    jstring arg1 =
        (*env)->NewStringUTF(
            env,
            "echo 'Hello from Termux AppForge' > ~/termux_appforge_bridge_test.txt"
        );

    (*env)->SetObjectArrayElement(
        env,
        args,
        0,
        arg0
    );

    (*env)->SetObjectArrayElement(
        env,
        args,
        1,
        arg1
    );

    jmethodID putExtraArray =
        (*env)->GetMethodID(
            env,
            intentClass,
            "putExtra",
            "(Ljava/lang/String;[Ljava/lang/String;)Landroid/content/Intent;"
        );

    jstring argsKey =
        (*env)->NewStringUTF(
            env,
            "com.termux.RUN_COMMAND_ARGUMENTS"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        putExtraArray,
        argsKey,
        args
    );

    jmethodID putExtraBool =
        (*env)->GetMethodID(
            env,
            intentClass,
            "putExtra",
            "(Ljava/lang/String;Z)Landroid/content/Intent;"
        );

    jstring backgroundKey =
        (*env)->NewStringUTF(
            env,
            "com.termux.RUN_COMMAND_BACKGROUND"
        );

    (*env)->CallObjectMethod(
        env,
        intent,
        putExtraBool,
        backgroundKey,
        JNI_TRUE
    );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return -4;
    }

    jclass activityClass =
        (*env)->GetObjectClass(
            env,
            activity
        );

    jmethodID startService =
        (*env)->GetMethodID(
            env,
            activityClass,
            "startService",
            "(Landroid/content/Intent;)Landroid/content/ComponentName;"
        );

    if (!startService || check_exception(env)) {
        detach_if_needed(vm, attached);
        return -5;
    }

    jobject result =
        (*env)->CallObjectMethod(
            env,
            activity,
            startService,
            intent
        );

    if (check_exception(env)) {
        detach_if_needed(vm, attached);
        return -6;
    }

    detach_if_needed(vm, attached);

    return result ? 0 : -7;
}
