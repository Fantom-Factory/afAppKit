
fan.afAppKit.ResizeObserverPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.afAppKit.ResizeObserverPeer.prototype.$ctor = function(self) {
	this.observer = new ResizeObserver(function(entries) {
		var list = fan.afAppKit.ResizeObserverPeer.$makeEntryList(entries);
		var args = fan.sys.List.make(fan.sys.Obj.$type, [list]);
		self.m_callback.callOn(self, args);
	});
}

fan.afAppKit.ResizeObserverPeer.prototype.observe = function(self, target, opts) {
	var config = null;
	if (opts != null)
		config = {
			box:	opts.get("box"),
		};
	this.observer.observe(target.peer.elem, config);
	return self;
}

fan.afAppKit.ResizeObserverPeer.prototype.unobserve = function(self, fanElem) {
	this.observer.unobserve(fanElem.peer.elem);
	return self
}

fan.afAppKit.ResizeObserverPeer.prototype.disconnect = function(self) {
	this.observer.disconnect();
	return self
}

fan.afAppKit.ResizeObserverPeer.$makeEntry = function(entry) {
	var fanEntry = fan.afAppKit.ResizeEntry.make();

	fanEntry.m_target		= fan.dom.ElemPeer.wrap(entry.target);
	fanEntry.m_contentRect	= fan.graphics.Rect.makeInt(entry.contentRect.x, entry.contentRect.y, entry.contentRect.width, entry.contentRect.height);

	return fanEntry;
}

fan.afAppKit.ResizeObserverPeer.$makeEntryList = function(entries) {
	var list = new Array();
		for (var i=0; i<entries.length; i++)
	list.push(fan.afAppKit.ResizeObserverPeer.$makeEntry(entries[i]));
	return fan.sys.List.make(fan.afAppKit.ResizeEntry.$type, list);
}
