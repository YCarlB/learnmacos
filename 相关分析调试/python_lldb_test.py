#!/usr/bin/python
import lldb

d = lldb.SBDebugger.Create()
d.SetAsync(False)

ci = d.GetCommandInterpreter()

res = lldb.SBCommandReturnObject()
ci.HandleCommand(
	'command script import "/Library/Developer/KDKs/KDK_10.15_19A471t.kdk/System/Library/Kernels/kernel.development'
	'.dSYM/Contents/Resources/Python/kernel.py"',
	res)

ci.HandleCommand('settings set target.load-script-from-symbol-file true', res)
ci.HandleCommand('kdp-remote ', res)
ci.HandleCommand('showallkmods', res)
print res.GetOutput()
p = ci.GetProcess()
# x/20xg $rip
while 1:
	s = raw_input("te:")
	if s != 'c':
		print ci.HandleCommand(s, res)
		print res.GetOutput()
	else:
		p.Continue()

# export PYTHONPATH=/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Resources/Python
