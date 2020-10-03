using build::BuildPod

class Build : BuildPod {

	new make() {
		podName = "afAppKit"
		summary = "A bit of a useful mess!"
		version = Version("0.0.3")

		meta = [
			"pod.dis"		: "App Kit",
		]

		depends = [
			// ---- Fantom Core -----------------
			"sys        1.0.73 - 1.0",
			"concurrent 1.0.73 - 1.0",

			// ---- Fantom Web ------------------
			"dom        1.0.73 - 1.0",
			"graphics   1.0.73 - 1.0",

			// ---- Fantom Factory Web ----------
			"afPickle   0.0.4  - 1.0",
		]

		srcDirs = [`fan/`, `fan/appkit/`, `fan/core/`, `fan/util/`]
		resDirs = [`doc/`]
		jsDirs	= [`js/`]
	}
}
