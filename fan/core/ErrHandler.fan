using dom::Elem
using dom::Event
using dom::Win

@Js class ErrHandler {
	// FIXME config inject these msgs? Wot about some non Steve generic msgs?
	static const Str	errTitle 	:= "Shazbot! The computer reported an error!"
	static const Str	errMsg		:= "Don't worry, it's not your fault - it's ours!\n\nSteve can fix it (he can fix anything!) but he needs to know about it first. Just drop us a quick email telling us what happened and Steve will do his best.\n\nCheers,\n\nFantom Factory.".replace("\n", "<br>")

	new make(|This|? f := null) { f?.call(this) }

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
	
	** Define |Obj| to utilise it-block funcs
	Void wrap(|Obj?| fn) {
		try	fn(null)
		catch (Err err) onError(err)
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
