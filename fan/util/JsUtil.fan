using dom::Elem
using dom::CssDim

@Js const class JsUtil {
	
	** Returns a new DateTime in the user's time zone.
	** Note the date is correct, but the TimeZone is not - we just adjust the time.
	static DateTime toLocalTs(DateTime dateTime) {
		dateTime.toUtc.minus(utcOffset)
	}

	static Duration utcOffset() {
		1min * (Env.cur.runtime == "js" ? getTimezoneOffset : (TimeZone.cur.offset(Date.today.year) + TimeZone.cur.dstOffset(Date.today.year)).toMin)
	}

	** Returns the offset in minutes.
	private native static Int getTimezoneOffset()
	
	native static Float getScrollbarWidth()
	
	static Void addScrollbarWidth(Elem elem, Str propName) {
		className := "data-addScrollbarWidth-${propName}"
		
		// don't double up the padding when called multiple times
		if (!elem.style.hasClass(className)) {
			scrollbarWidth	:= JsUtil.getScrollbarWidth
			parseFloat		:= |Str prop->Float| { CssDim(prop.trimToNull ?: "0px").val.toFloat }
			oldProp 		:= parseFloat(elem.style.get(propName))
			elem.setProp(className, oldProp)
			elem.style.set(propName, "${oldProp + scrollbarWidth}px")
			elem.style.addClass(className)
		}
	}

	static Void removeScrollbarWidth(Elem elem, Str propName) {
		className	:= "data-addScrollbarWidth-${propName}"
		if (elem.style.hasClass(className)) {
			oldProp 	:= elem.prop(className)
			elem.style.set(propName, "${oldProp}px") 
			elem.setProp(className, null)
			elem.style.removeClass(className)
		}
	}
	
	native static Str copyToClipboard(Str text)
}
