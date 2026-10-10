import com.android.build.api.variant.LibraryAndroidComponentsExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.4" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
        // Add the Huawei repository for AGCP plugin
        maven("https://developer.huawei.com/repo/")
    }
    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
        classpath("com.huawei.agconnect:agcp:1.5.2.300")
    }
}


allprojects {
    repositories {
        google()
        mavenCentral()
        // Add the Huawei repository for AGCP plugin
        maven("https://developer.huawei.com/repo/")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        // file_picker 11.0.2 仅按 AGP 主版本跳过 KGP，未考虑关闭内置 Kotlin 的兼容模式。
        if (project.name == "file_picker" &&
            project.findProperty("android.builtInKotlin")?.toString() == "false") {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
        // 等插件自己的 DSL 配置结束后统一目标版本，避免被 Java 8 配置覆盖。
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { android ->
                android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
                if (android.namespace.isNullOrBlank()) {
                    android.namespace = "cn.anoxia.${project.name.replace('-', '_')}"
                }
            }
        }
    }

    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }

}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
