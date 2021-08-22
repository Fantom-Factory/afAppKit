using dom::Elem
using dom::Event
using dom::Win
using concurrent::Actor

@Js class AppKitErrHandler {
	@Inject	Log		log

	// MiniIoc will inject config for "afAppKit.clientErrTitle"
	@Config Str?	clientErrTitle 	:= "Shazbot! The computer reported an error!"
	@Config Str?	clientErrMsg	:= "Don't worry, it's not your fault - it's ours!\n\nRefresh the page and try again.".replace("\n", "<br>")
	private	Func?	onErrFn
	
	new make(|This|? f := null) {
		log				= this.typeof.pod.log

		f?.call(this)
		
		// let static field qnames also be injected
		// it's a "little" fudge but does let us define err msgs in JS code
		// I'd like to set them via Actors, like DomJax, but it's too chicken + egg
		clientErrTitle	= findStr(clientErrTitle)
		clientErrMsg	= findStr(clientErrMsg)
		onErrFn 		= onErrFn ?: |Str title, Str msg, Err cause| {
			log.err("As caught by ErrHandler", cause)
			openModal(title, msg)
		}
	}

	Void init() {
		Actor.locals["afAppKit.errHandler"] = this
	}

	static AppKitErrHandler cur() {
		Actor.locals["afAppKit.errHandler"]
	}

	@NoDoc @Deprecated { msg="Use cur() instead." }
	static AppKitErrHandler instance() { cur }

	Void onClick(Obj? obj, |Event, Elem| fn) {
		onEvent("click", obj, fn)
	}

	Void onEvent(Str type, Obj? obj, |Event, Elem| fn) {
		toElemList(obj).each |elem| {
			elem.onEvent(type, false) |event| {
				try fn(event, elem)
				catch (Err cause) {
					log.err("Error in '$type' event handler")
					onError(cause)
				}
			}			
		}
	}
	
	Int onTimeout(Duration delay, |Win| fn) {
		Win.cur.setTimeout(delay, wrapFn(fn))
	}
	
	Void setErrHandler(|Str title, Str msg, Err cause|? fn) {
		this.onErrFn = fn
	}
	
	** Executes the given 'fn' inside the ErrHandler.
	** 
	** Defines |Obj| to utilise it-block funcs.
	Void wrap(|Obj?|? fn) {
		if (fn == null) return
		wrapFn(fn)(null)
	}
	
	** Returns a 'fn', that when called, executes inside the ErrHandler.
	** 
	** Defines |Obj| to utilise it-block funcs.
	|Obj?|? wrapFn(|Obj?|? fn) {
		if (fn == null) return null
		return |Obj? arg| {
			try	fn(arg)
			catch (Err err)	onError(err)
		}
	}

	** Returns a 'fn', that when called, executes inside the ErrHandler.
	** 
	** Defines |Obj| to utilise it-block funcs.
	|Obj? arg -> Obj?|? wrapObjFn(|Obj?->Obj?|? fn) {
		if (fn == null) return null
		return |Obj? arg -> Obj?| {
			try	return fn(arg)
			catch (Err err) {
				onError(err)
				return null
			}
		}
	}

	virtual Void onError(Err? cause := null) {
		onErrFn?.call(clientErrTitle, clientErrMsg, cause)
	}
	
	virtual Void openModal(Str title, Obj body) {
		Modal.createErrDialog(title, body).open
	}

	private Str findStr(Str str) {
		// check if str *looks* like a qname
		if (str.contains("::") && str.contains(".") && !str.contains(" ")) {
			field := Field.findField(str, false)
			if (field != null)
				str = field.get(null).toStr
			else
				log.warn("Could not resolve field for err string: $str")
		}
		return str
	}

	private Elem[] toElemList(Obj? obj) {
		if (obj == null) return Elem#.emptyList

		elems := null as Elem[]
		if (elems == null && obj is List)
			elems = obj
		if (elems == null && obj is Elem)
			elems = Elem[obj]
		if (elems == null)
			elems = Win.cur.doc.querySelectorAll(obj.toStr)
		
		return elems
	}
}
