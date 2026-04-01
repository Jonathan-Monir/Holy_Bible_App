// android/app/build.gradle
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ivrayem.holy_bible"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = "holy-bible-key"
            keyPassword = "HolyBible@Ivraym2026"      // ← make sure this matches exactly
            storeFile = file("holy-bible-release.jks")
            storePassword = "HolyBible@Ivraym2026"    // ← and this too
        }
    }

    defaultConfig {
        applicationId = "com.ivrayem.holy_bible"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") // ← changed from "debug"
        }
    }
}

flutter {
    source = "../.."
}
