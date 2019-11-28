lldb -p 查看路径
配置环境
export PYTHONPATH= /Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.fremework/Resources/Python

创建SBDebugger

GetSelectedTarget选择target
GetCommandInterpreter 选择控制台

然后可以用python和lldb正常交互了


获取结构地址v=target/FindGlobalVariables(name,1).GetValueAtIndex(0)
v.GetChildMemberWithName

