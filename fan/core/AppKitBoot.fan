using afPickle::Pickle
using dom::Elem
using dom::Doc
using dom::Win

@Js class AppKitBoot {

	** This is the main entry point to the Js App
	virtual Void init(Str appTypeStr, Str configStr) {
		try {
			appType := Pickle.readObj(appTypeStr)
			config	:= Pickle.readObj(configStr)
			iocObjs	:= iocObjs
			doInit(appType, iocObjs, config)

		} catch (Err cause) {
			// don't bother with ErrHandler during init - it's too much chicken + egg
			log.err("Could not initialise AppKit page", cause)
			
			// re-throw to ensure tests still fail
			throw cause
		}
	}

	** Hook to pre-configure the IoC with ready-made objects.
	virtual Type:Obj iocObjs() {
		objs := Type:Obj?[:]
		// keep any err-handling set by tests
		if (AppKitErrHandler.cur != null)
			objs[AppKitErrHandler#] = AppKitErrHandler.cur
		return objs
	}

	@NoDoc
	MiniIoc doInit(Type appType, Type:Obj iocObjs, Str:Obj? config) {
		appNom := config["appName"	 ]?.toStr ?: AppKitBoot#.pod.name
		appVer := config["appVersion"]?.toStr ?: AppKitBoot#.pod.version.toStr
		logLogo(appNom, appVer)

		injector := MiniIoc(iocObjs, config)
		errHand	 := (AppKitErrHandler) injector.get(AppKitErrHandler#)
		errHand.init

		log.info("Initialising page: ${appType.qname}")
		appPage  := injector.build(appType)
		
		try appPage.typeof.method("init", false)?.callOn(appPage, null)
		catch (Err err) errHand.onError(err)

		return injector
	}

	Void logLogo(Str name, Str ver) {
		tag  := "presents ${name} v${ver}"
		logo := Str<|   _____         __               _____        __                
		               / ___/_  _____/ /_____ ______  / ___/_  ____/ /_________  __ __
		              / __/ _ \/ _  / __/ _  / , , / / __/ _ \/ __/ __/ _  / __|/ // /
		             /_/  \_,_/_//_/\__/____/_/_/_/ /_/  \_,_/___/\__/____/_/   \_, / 
		                                                                       /___/  |>
		lines	  := logo.split('\n', false)
		lines[-1] = StrBuf().add(lines[-1]).replaceRange(57-tag.size..<57, tag).toStr
		text	  := lines.join("\n")
		log.info("\n${text}\n\n")
	}
	
	virtual Log	log() { this.typeof.pod.log }
}
