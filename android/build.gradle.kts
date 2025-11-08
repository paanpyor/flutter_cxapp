// TOP-LEVEL GRADLE FILE: android/build.gradle.kts
// This file declares plugin versions and sets up global project configurations.

plugins {
    // 1. Android Gradle Plugin (AGP) - Required for Android build tasks
    // FIX: Updating the version from 8.3.0 to 8.9.1 to resolve the conflict.
    id("com.android.application") version "8.9.1" apply false
    
    // 2. Kotlin Plugin - Required for Kotlin support
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false

    // 3. Google Services Plugin - Declared here with the target version (4.4.4)
    //    The 'apply false' is essential; it tells Gradle to define the version 
    //    without applying it to the project yet.
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Flutter Build Directory Configuration ---
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// This line below is specific to the old Flutter template structure but is often kept:
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

