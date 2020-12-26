using dom::Elem
using dom::Event
using dom::Win
using concurrent::Actor

@Js class ErrHandler {
	// MiniIoc will inject config for "afAppKit.clientErrTitle"
	@Config Str?	clientErrTitle 	:= "Shazbot! The computer reported an error!"
	@Config Str?	clientErrMsg	:= "Don't worry, it's not your fault - it's ours!\n\nRefresh the page and try again.".replace("\n", "<br>")
	
	new make(|This|? f := null) {
		f?.call(this)
		
		// let static field qnames also be injected
		// it's a "little" fudge but does let us define err msgs in JS code
		// I'd like to set them via Actors, like DomJax, but it's too chicken + egg
		clientErrTitle	= findStr(clientErrTitle)
		clientErrMsg	= findStr(clientErrMsg)
	}

	Void init() {
		Actor.locals["appKit.errHandler"] = this
	}
	
	static ErrHandler instance() {
		Actor.locals["appKit.errHandler"]
	}
	
	Void onClick(Obj? obj, |Event, Elem| fn) {
		onEvent("click", obj, fn)
	}

	Void onEvent(Str type, Obj? obj, |Event, Elem| fn) {
		if (obj == null) return

		elems := null as Elem[]
		if (elems == null && obj is List)
			elems = obj
		if (elems == null && obj is Elem)
			elems = Elem[obj]
		if (elems == null)
			elems = Win.cur.doc.querySelectorAll(obj.toStr)

		elems.each |elem| {
			elem.onEvent(type, false) |event| {
				try fn(event, elem)
				catch (Err cause) {
					log.err("Error in '$type' event handler")
					onError(cause)
				}
			}			
		}
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
		log.err("As caught by ErrHandler", cause)
		openModal(clientErrTitle, clientErrMsg)
	}
	
	virtual Void openModal(Str title, Obj body) {
		Modal.createErrDialog(title, body).open
	}

	virtual Log	log() { this.typeof.pod.log }
	
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
}
