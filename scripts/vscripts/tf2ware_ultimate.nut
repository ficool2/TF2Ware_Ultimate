::ROOT  <- getroottable()
::CONST <- getconsttable()

if (!("ConstantNamingConvention" in CONST))
{
	foreach (a, b in Constants)
		foreach (k, v in b)
			CONST[k] <- v == null ? 0 : v
}

IncludeScript("tf2ware_ultimate/const",    ROOT)
IncludeScript("tf2ware_ultimate/items",    ROOT)
IncludeScript("tf2ware_ultimate/vcd",      ROOT)
IncludeScript("tf2ware_ultimate/util",     ROOT)
IncludeScript("tf2ware_ultimate/config",   ROOT)
IncludeScript("tf2ware_ultimate/location", ROOT)
IncludeScript("tf2ware_ultimate/bot",      ROOT)
IncludeScript("tf2ware_ultimate/sdr",      ROOT)
IncludeScript("tf2ware_ultimate/dev",      ROOT)
IncludeScript("tf2ware_ultimate/plugin",   ROOT)
IncludeScript("tf2ware_ultimate/main",     ROOT)

if ("Ware_Events" in ROOT)
	Ware_Events.clear()
else
	::Ware_Events <- {}
IncludeScript("tf2ware_ultimate/events", Ware_Events)
__CollectGameEventCallbacks(Ware_Events)

MarkForPurge(self)