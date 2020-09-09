using dom::Elem
using dom::Event
using dom::Win
using concurrent::Actor

@Js class ErrHandler {
	@Config Str	errTitle 	:= "Shazbot! The computer reported an error!"
	@Config Str	errMsg		:= "Don't worry, it's not your fault - it's ours!\n\nDrop us a quick email explaining what happened and we'll do our best to fix it.\n\nIn the mean time, refresh the page and try again.".replace("\n", "<br>")

	new make(|This|? f := null) { f?.call(this) }

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
	
	** Define |Obj| to utilise it-block funcs.
	Obj? wrap(|Obj?->Obj?| fn) {
		try	return fn(null)
		catch (Err err) {
			onError(err)
			return null	// will never get called
		}
	}

	virtual Void onError(Err? cause := null) {
		log.err("As caught by ErrHandler", cause)
		openModal(errTitle, errMsg)
		if (cause != null)
			throw cause
	}
	
	virtual Void openModal(Str title, Obj body) {
		Modal.createErrDialog(title, body).open
	}

	virtual Log	log() { this.typeof.pod.log }
}
