
fan.afAppKit.JsUtilPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.afAppKit.JsUtilPeer.prototype.$ctor = function(self) {};

// this method does work, it's just that the offset solution seems easier!
//fan.afAppKit.JsUtil.toLocalDateTime = function(date) {
//	var utc		= date.toUtc();
//	var local	= new Date(Date.UTC(utc.year(), utc.month().ordinal(), utc.day(), utc.hour(), utc.min(), utc.sec()));
//	return fan.sys.DateTime.make(local.getFullYear(), fan.sys.Month.m_vals.get(local.getMonth()), local.getDate(), local.getHours(), local.getMinutes(), local.getSeconds());
//}

fan.afAppKit.JsUtilPeer.getTimezoneOffset = function() {
	return new Date().getTimezoneOffset();
};

fan.afAppKit.JsUtilPeer.getScrollbarWidth = function() {
	var scrollDiv = document.createElement("div");
	scrollDiv.className = "modal-scrollbar-measure";
	document.body.appendChild(scrollDiv);
	var scrollbarWidth = scrollDiv.getBoundingClientRect().width - scrollDiv.clientWidth;
	document.body.removeChild(scrollDiv);
	return scrollbarWidth;
};

// https://stackoverflow.com/questions/400212/how-do-i-copy-to-the-clipboard-in-javascript
fan.afAppKit.JsUtilPeer.copyToClipboard = function(text) {

	// try to copy the easy way first
	if (navigator.clipboard) {
		// don't bother reporting errors
		navigator.clipboard.writeText(text);
		return text;
	}

	// the fallback copy method
	var textArea = document.createElement("textarea");
	textArea.value = text;

	// svoid scrolling to bottom
	textArea.style.top = "0";
	textArea.style.left = "0";
	textArea.style.position = "fixed";
	document.body.appendChild(textArea);
	textArea.focus();
	textArea.select();

	try { document.execCommand('copy'); }
	catch (err) { /* meh */ }

	document.body.removeChild(textArea);
	return text;
};
