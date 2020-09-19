using dom::Elem
using graphics::Rect

** ResizeObserver invokes a callback when an dimensions of an element changes.
** 
** See [Resize Observer API]`https://developer.mozilla.org/en-US/docs/Web/API/Resize_Observer_API`
@Js class ResizeObserver {

	private Func? callback

	** Constructor.
	new make(|ResizeEntry[]| callback) {
		this.callback = callback
	}

	** Register to receive resize events for given node.
	** Valid options:
	**  - "box": 'content-box' (the default) or 'border-box'
	native This observe(Elem target, [Str:Obj?]? opts := null)

	** Ends the observing of a specified node.
	native This unobserve(Elem target)
	
	** Disconnect this observer from receiving resize events.
	native This disconnect()
}

** ResizeRec represents an individual element resize.
@Js class ResizeEntry {

	** It-block constructor.
	new make(|This|? f := null) { f?.call(this) }

	** Target node that was resized.
	Elem target

	** The new size of the observed node. 
	Rect contentRect 
}
