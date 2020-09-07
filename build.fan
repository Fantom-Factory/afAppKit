using build::BuildPod

class Build : BuildPod {

	new make() {
		podName = "afAppKit"
		summary = "My Awesome appKit project"
		version = Version("0.0.1")

		meta = [
			"pod.dis"		: "App Kit",
		]

		depends = [
			// ---- Fantom Core -----------------
			"sys        1.0.73 - 1.0",
			"dom        1.0.73 - 1.0",
		]

		srcDirs = [`fan/`, `fan/appkit/`, `fan/core/`, `fan/util/`]
		resDirs = [`doc/`]
		jsDirs	= [`js/`]
	}
}
