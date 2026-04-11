plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.footbox"

    compileSdk = 36  // UPDATED to match the highest plugin requirement
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.footbox"
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // Keep targetSdk aligned
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


flutter {
    source = "../.."
}
