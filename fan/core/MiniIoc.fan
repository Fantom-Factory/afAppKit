
** A very poor man's IoC that's concerned with object construction only.
**  + Config field injection (keyed off.last.dot.name) 
** 
** IoC limitations:
**  - only 1 instance of any type may exist 
**  - no field injection; it-block & ctor construction only
**  - no service configuration, distributed or otherwise
**  - no type hierarchy lookup, injected types must be explicitly defined (or Mixin + Impl)
**  - only 1 (global) scope
@Js class MiniIoc {

	private Str:Obj?	config
	private Type:Obj?	cache
	
	new make([Type:Obj]? cache := null, [Str:Obj?]? config := null) {
		this.cache  = cache?.rw	 ?: Type:Obj?[:]
		this.config = config?.rw ?:  Str:Obj?[:]
	}

	** Gets or builds (and caches) the given type.
	@Operator
	Obj get(Type type) {
		getOrBuildVal(type)
	}

	** Creates a new instance of the given type.
	Obj build(Type type, Obj?[]? ctorArgs := null) {
		plan := Field.makeSetFunc(createPlan(type))
		args := (ctorArgs ?: Obj?[,]).add(plan)
		return type.make(args)
	}
	
	private Field:Obj? createPlan(Type type) {
		plan := Field:Obj?[:]
		type.fields.each |field| {
			if (field.isStatic) return
			if (field.hasFacet(Config#)) {
				config := getConfig(field.name, field.type)
				if (config != null)	// allow default field values if config not provided
					plan[field] = config
			}
			if (field.hasFacet(Inject#))
				plan[field] = getOrBuildVal(field.type)
		}
		return plan
	}
	
	private Obj? getConfig(Str name, Type type) {
		key := name.contains(".") ? name : config.keys.find |key| { key.split('.').last == name }
		val := key == null ? null : config[key]
		
		if (val == null)	  return null
		switch (type) {
			case Bool#		: return val.toStr.toBool
			case Duration#	: return Duration(val.toStr)
			case Int#		: return val.toStr.toInt
			case Str#		: return val.toStr
			case Uri#		: return val.toStr.toUri
		}
		return val
	}
	
	private Obj? getOrBuildVal(Type type) {
		switch (type) {
			case MiniIoc#	: return this
			case Log#		: return typeof.pod.log
			default			: return cache.getOrAdd(type) { autobuild(type) }
		}
		throw UnsupportedErr("Could not inject: $type.qname")
	}
	
	private Obj autobuild(Type type) {
		try {
			if (type.isMixin) type = Type.find(type.qname + "Impl", true)
			ctors := type.methods.findAll { it.isCtor }.sortr |p1, p2| { p1.params.size <=> p2.params.size }
			ctor  := ctors.find { it.hasFacet(Inject#) } ?: ctors.first
			if (ctor == null)
				throw Err("No IoC ctor found on ${type.qname}")
		
			args := ctor.params.map {
				it.type.fits(Func#) ? Field.makeSetFunc(createPlan(type)) : getOrBuildVal(it.type)
			}
			
			return ctor.callList(args)

		} catch (Err err)
			throw Err("Could not autobuild $type", err)
	}
}

@Js internal facet class Inject {}
@Js internal facet class Config {}
