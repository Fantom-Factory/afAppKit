using afPickle::Pickle

const class AppMain {
	
	** The URL where pod resources are served from.
	const	Uri?	podBaseUrl	
	
	new make(Uri? podBaseUrl) {
		this.podBaseUrl	= podBaseUrl
	}
	
	Str render(Type pageType, Str:Obj? pageConfig) {
		args	:= [pageType, pageConfig]
		argStrs	:= args.map |arg| { Pickle.writeObj(arg) }
		jargs	:= argStrs.map |Str arg->Str| { "args.add(${arg.toCode});" }
		podBase	:= podBaseUrl == null ? "" : "fan.sys.UriPodBase = '${podBaseUrl}';"

		pageMethod := AppInit#init
		return 
			"fan.sys.TimeZone.m_cur = fan.sys.TimeZone.fromStr('UTC');
			 ${podBase}
			 
			 var args = fan.sys.List.make(fan.sys.Obj.\$type);
			 ${jargs.join('\n'.toChar)}
			 
			 var method = fan.sys.Slot.findMethod('${pageMethod.qname}', true);
			 method.callOn(method.parent().make(), args);"
	}
}
