allprojects {
    repositories {
        google()
        mavenCentral()
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

/**
 * ✅ FIX (AGP 8+): Prevent "Namespace not specified" for old Android plugins
 * مثل flutter_windowmanager
 *
 * ✅ بدون afterEvaluate علشان ما يطلعش:
 * Cannot run Project.afterEvaluate(Action) when the project is already evaluated.
 */
subprojects {

    // يشتغل بمجرد ما Plugin يتحط على الـ subproject
    plugins.whenPluginAdded {

        val isAndroidModule =
            this.javaClass.name == "com.android.build.gradle.LibraryPlugin" ||
            this.javaClass.name == "com.android.build.gradle.AppPlugin"

        if (!isAndroidModule) return@whenPluginAdded

        val androidExt = extensions.findByName("android") ?: return@whenPluginAdded

        try {
            // اقرأ namespace (لو موجود)
            val getNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
            val currentNamespace = getNamespace?.invoke(androidExt) as? String

            if (currentNamespace.isNullOrBlank()) {
                val setNamespace = androidExt.javaClass.methods.firstOrNull {
                    it.name == "setNamespace" && it.parameterTypes.size == 1
                }

                // fallback آمن لو group فاضي أو مش صالح
                val grp = project.group?.toString().orEmpty()
                val fallback = "com.${rootProject.name}.${project.name}"
                    .replace(Regex("[^A-Za-z0-9_.]"), "_")

                val ns = if (grp.isBlank() || !grp.contains(".")) fallback else grp

                setNamespace?.invoke(androidExt, ns)
            }
        } catch (_: Throwable) {
            // تجاهل أي اختلافات بين إصدارات AGP / Plugins
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}