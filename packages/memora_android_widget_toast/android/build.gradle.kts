plugins {
    id("com.android.library")
}

val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION
    .substringBefore('.')
    .toInt()

if (agpMajor < 9) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.memora.android_widget_toast"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 23
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
