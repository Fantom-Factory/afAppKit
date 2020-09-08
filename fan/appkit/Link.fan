using dom

**
** Hyperlink anchor element
**
** - domkit 1.0.75
@Js class Link {

	Elem elem { private set }
	
	private new _make(Elem elem) {
		this.elem = elem

		if (elem.tagName != "a")
			throw ArgErr("Elem not an anchor: ${elem.html}")
	}

	static new fromSelector(Str selector, Bool checked := true) {
		elem := Win.cur.doc.querySelector(selector)
		if (elem == null && checked) throw Err("Could not find Link: ${selector}")
		return fromElem(elem)
	}
	
	static new fromElem(Elem? elem) {
		if (elem == null) return null
		if (elem.prop(Link#.qname) == null)
			elem.setProp(Link#.qname, Link._make(elem))
		return elem.prop(Link#.qname)
	}

	** The target attribute specifies where to open the linked document.
	Str target {
		get { this->target }
		set { this->target = it }
	}

	** URI to hyperlink to.
	Uri url {
		get { Uri.decode(elem->href ?: "") }
		set { elem->href = it.encode }
	}
}