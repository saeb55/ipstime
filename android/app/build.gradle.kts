plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_complete_demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // Désugaring nécessaire pour compatibilité API < 26
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.flutter_complete_demo"

        // ✅ FIX : valeur minimale forcée à 23 pour local_auth
        // car flutter.minSdkVersion peut être inférieur (et donc planter)
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // 🔐 garde la config debug pour simplifier les tests
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Lib Kotlin standard
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // ✅ Désugaring nécessaire pour compatibilité Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
