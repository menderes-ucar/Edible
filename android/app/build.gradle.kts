import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
}

val mapsProperties = Properties()
val mapsPropertiesFiles = listOf(
    rootProject.file("secrets.properties"),
    rootProject.file("local.properties"),
)
for (propertiesFile in mapsPropertiesFiles) {
    if (propertiesFile.isFile) {
        propertiesFile.inputStream().use { input -> mapsProperties.load(input) }
        if (!mapsProperties.getProperty("MAPS_API_KEY").isNullOrBlank()) break
    }
}
val mapsApiKey = mapsProperties.getProperty("MAPS_API_KEY")?.trim().orEmpty()

if (mapsApiKey.isBlank()) {
    logger.warn("MAPS_API_KEY is missing. Add MAPS_API_KEY=... to android/local.properties or android/secrets.properties.")
}

// RELEASE KEYSTORE
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }
}

android {
    namespace = "com.mndrs.edible"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.mndrs.edible"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}

flutter {
    source = "../.."
}