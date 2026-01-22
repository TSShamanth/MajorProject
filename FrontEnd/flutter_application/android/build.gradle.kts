import org.gradle.api.GradleException

if (!JavaVersion.current().isCompatibleWith(JavaVersion.VERSION_11)) {
    throw GradleException("Java ${JavaVersion.current()} detected. This build requires Java 11 or higher. Set JAVA_HOME or add 'org.gradle.java.home' in android/gradle.properties pointing to a JDK 11+.")
}

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
