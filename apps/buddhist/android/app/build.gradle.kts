import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// User-approved dedicated Buddhist key. Christian signing remains unchanged.
val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signingProperties.load(it) }
val releaseKey = rootProject.file("buddhist-release.jks")

android {
    namespace = "com.onaria.buddhist"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "com.onaria.buddhist"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        if (signingFile.exists() && releaseKey.exists()) {
            create("onariaRelease") {
                keyAlias = signingProperties["keyAlias"] as String?
                keyPassword = signingProperties["keyPassword"] as String?
                storeFile = releaseKey
                storePassword = signingProperties["storePassword"] as String?
            }
        }
    }
    buildTypes {
        release {
            // Missing key permits compilation of an UNSIGNED artifact only.
            signingConfig = signingConfigs.findByName("onariaRelease")
        }
    }
}
kotlin {
    compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 }
}
flutter { source = "../.." }
