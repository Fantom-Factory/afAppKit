using dom::Elem
using dom::Win

@Js internal class AppElem {
	
	static Obj? fromSelector(Str selector, Type type, Bool checked) {
		elem := Win.cur.doc.querySelector(selector)
		if (elem == null && checked) throw Err("Could not find ${type.name}: ${selector}")
		return fromElem(elem, type, checked)
	}
	
	static Obj? fromElem(Elem? elem, Type type, Bool checked) {
		if (elem == null) return null
		if (elem.prop("appkit-elem") == null) {			
			if (!elem.style.hasClass("appkit-${type.name.lower}"))
				return checked ? throw ArgErr("Elem does not have class: appkit-${type.name.lower}\n${elem.html}") : null
			appElem := type.method("_make").call(elem)
			elem.setProp("appkit-elem", appElem)
		}

		appObj := elem.prop("appkit-elem")
		if (appObj != null && !appObj.typeof.fits(type))
			return checked ? throw ArgErr("AppElem is not ${type.name}: ${appObj.typeof.qname}\n${elem.html}") : null

		return appObj
	}
	
}
