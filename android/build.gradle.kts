allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// geocoding_android (and possibly other plugins) hardcode a stale
// compileSdk in their own build.gradle, below what their own transitive
// androidx deps now require — bumping :app's compileSdk alone doesn't fix
// that, since each library module's compileSdk is independent. Force every
// Android library subproject to build against the same, newer compileSdk.
subprojects {
    // Needs to run after the subproject's own build.gradle has already set
    // (and would otherwise win with) its own stale compileSdk — but
    // evaluationDependsOn(":app") above means some plugin subprojects are
    // already evaluated by the time this registers, where afterEvaluate
    // would throw, so apply immediately for those instead.
    val forceCompileSdk: () -> Unit = {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let {
            it.compileSdk = 36
        }
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
