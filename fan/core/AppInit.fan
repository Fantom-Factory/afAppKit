using dom::Elem
using dom::Doc
using dom::Win

@Js class AppInit {

	** This is the main entry point to the Js App
	virtual Void init(Type appType, Str:Obj? config) {
		iocObjs		:= iocObjs
		errHandler	:= iocObjs[ErrHandler#] as ErrHandler
		if (errHandler == null) {
			iocObjs		= iocObjs.rw.set(ErrHandler#, ErrHandler())
			errHandler	= iocObjs[ErrHandler#]
		}

		try doInit(appType, iocObjs, config)
		catch (Err cause) {
			errHandler.log.err("Could not initialise page")
			errHandler.onError(cause)
		}
	}

	** Hook to pre-configure the IoC with ready-made objects
	virtual Type:Obj iocObjs() {
		Type:Obj?[
			ErrHandler#	: ErrHandler()
		]
	}

	@NoDoc
	Void doInit(Type appType, Type:Obj iocObjs, Str:Obj? config) {
		appNom := config["appName"	 ]?.toStr ?: AppInit#.pod.name
		appVer := config["appVersion"]?.toStr ?: AppInit#.pod.version.toStr
		logLogo(appNom, appVer)

		injector := MiniIoc(iocObjs, config)
		appPage  := injector.build(appType)
		appPage.typeof.method("init", false)?.callOn(appPage, null)
	}

	
	Void logLogo(Str name, Str ver) {
		tag  := "powers ${name} v${ver}"
		logo := Str<|   _____         __               _____        __                
		               / ___/_  _____/ /_____ ______  / ___/_  ____/ /_________  __ __
		              / __/ _ \/ _  / __/ _  / , , / / __/ _ \/ __/ __/ _  / __|/ // /
		             /_/  \_,_/_//_/\__/____/_/_/_/ /_/  \_,_/___/\__/____/_/   \_, / 
		                                                                       /___/  |>
		lines	  := logo.split('\n', false)
		lines[-1] = StrBuf().add(lines[-1]).replaceRange(57-tag.size..<57, tag).toStr
		text	  := lines.join("\n")
		typeof.pod.log.info("\n${text}\n\n")
	}
}
