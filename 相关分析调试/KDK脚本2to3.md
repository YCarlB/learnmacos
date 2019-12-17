# KDK2to3
	lldb环境python3不知道怎么更换
	所以尝试将KDK转换为python3版本
	记录下遇到的问题

## 2to3
	输入lldb -p
	调用 2to3将脚本全部换成python3

## pip
	调用KDK会出现包找不到的情况，由于xcode的python是自己搞得，所以即使外面安装pip，也无法成功
	打开包环境，发现有pip，所以用lldb的python脚本调用pip
	‘’‘
	script from pip._internal import main
	script main(['install', '第三方库名'])

	’‘’

## TypeError: 'value' object cannot be interpreted as an integer

	这是由于python2和python3魔术方法不同
	调用指令的时候会出错
	找到KDK的lldb的core里面的vcvalue
	添加__index__方法，返回int类型，解决bug
