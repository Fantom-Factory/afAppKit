
fan.afAppKit.StickySidebarPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.afAppKit.StickySidebarPeer.prototype.$ctor = function(self) {};

fan.afAppKit.StickySidebarPeer.windowInnerSize = function() {
	return fan.graphics.Size.makeInt(window.innerWidth, window.innerHeight);
};

fan.afAppKit.StickySidebarPeer.clientSize = function(fanElem) {
	var elem	= fanElem.peer.elem;
	var w		= elem.offsetWidth  || 0;
	var h		= elem.offsetHeight || 0;
	if (!elem.m_clientSize || elem.m_clientSize.m_w != w || elem.m_clientSize.m_h != h)
		elem.m_clientSize = fan.graphics.Size.makeInt(w, h);
	return elem.m_clientSize;
};

// Get current coordinates left and top of specific element.
fan.afAppKit.StickySidebarPeer.offsetPoint = function(fanElem) {
	var element	= fanElem.peer.elem;
	var result	= {left: 0, top: 0};

	do {
		let offsetTop	= element.offsetTop;
		let offsetLeft	= element.offsetLeft;

		if (!isNaN(offsetTop))
			result.top += offsetTop;

		if (!isNaN(offsetLeft))
			result.left += offsetLeft;

		element = ("BODY" == element.tagName) ? element.parentElement : element.offsetParent;
	} while(element)

	return fan.graphics.Point.makeInt(result.left, result.top);
}

fan.afAppKit.StickySidebarPeer.docScrollPoint = function() {
	var top	 = document.documentElement.scrollTop  || document.body.scrollTop;
	var left = document.documentElement.scrollLeft || document.body.scrollLeft;
	return fan.graphics.Point.makeInt(left, top);
}

fan.afAppKit.StickySidebarPeer.resizeSensor = function(fanElem, fn) {
	new ResizeSensor(fanElem.peer.elem, function() {
		fn.call(self);
	});
}
