plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.example.monitoramentohidrometeorologico"
    compileSdk {
        version = release(37)
    }

    defaultConfig {
        applicationId = "com.example.monitoramentohidrometeorologico"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            optimization {
                enable = false
            }
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    testOptions {
        // Permite usar classes do Android (ex.: Log) nos testes JVM sem falhar
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    implementation(libs.activity.ktx)
    implementation(libs.appcompat)
    implementation(libs.constraintlayout)
    implementation(libs.material)

    // Pessoa A — dados, integração e serviços
    implementation(libs.okhttp)        // cliente HTTP (HTTPS, timeouts)
    implementation(libs.gson)          // conversão do JSON da API
    implementation(libs.work.runtime)  // tarefa periódica de alertas (HM-07)

    testImplementation(libs.junit)
    testImplementation(libs.okhttp.mockwebserver) // simula a API nos testes de falha
    androidTestImplementation(libs.espresso.core)
    androidTestImplementation(libs.ext.junit)
}