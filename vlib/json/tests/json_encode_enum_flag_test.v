import json

@[flag; json_as_number]
pub enum Permission {
	exec
	write
	read
}

@[flag]
pub enum LogLevel {
	error
	warning
	info
	debug
}

@[flag]
enum TestEnum {
	one
	two
	three
}

type TestAlias = TestEnum
type TestSum = TestEnum | string
type TestSum2 = Permission | string
type TestAliasAttr = Permission

struct TestStruct {
	test  []TestEnum
	test2 TestEnum
	test3 TestAlias
	test4 TestSum
	test5 Permission
	test6 LogLevel
}

struct TestStruct2 {
	a TestAliasAttr
	b TestSum2
	c TestSum2
	d TestSum2
}

struct Test {
	ab ?int
	a  ?Permission
}

struct Test2 {
	a ?LogLevel
}

type TSum = Permission | string
type TSum2 = LogLevel | string

struct Test3 {
	a ?TSum
}

struct Test4 {
	a ?TSum2
}

fn test_encode_with_flag_enum() {
	out := json.encode(TestStruct{
		test:  [TestEnum.one | TestEnum.two, TestEnum.one]
		test2: TestEnum.two | TestEnum.three
		test3: TestEnum.one
		test4: TestEnum.two | TestEnum.one
		test5: Permission.read | Permission.write
		test6: LogLevel.debug | LogLevel.info
	})
	assert out == '{"test":["one | two","one"],"test2":"two | three","test3":"one","test4":"one | two","test5":6,"test6":"info | debug"}'
}

fn test_encode_direct_enum() {
	assert json.encode(TestEnum.one) == '"one"'
	assert json.encode(TestEnum.one | TestEnum.three) == '"one | three"'
}

fn test_decode_alias_and_sumtype() {
	assert json.decode(TestStruct, '{"test":["one","one"],"test2":"two","test3": "one", "test4": "two", "test5":6, "test6": "error | warning"}')! == TestStruct{
		test:  [.one, .one]
		test2: .two
		test3: TestAlias(.one)
		test4: TestSum('two')
		test5: .read | .write
		test6: .warning | .error
	}
}

fn test_enum_attr() {
	assert dump(json.encode(Permission.read)) == '4'
	assert dump(json.encode(Permission.exec)) == '1'
	assert dump(json.encode(Permission.write | Permission.read)) == '6'

	assert dump(json.encode(LogLevel.info)) == '"info"'
	assert dump(json.encode(LogLevel.error)) == '"error"'
	assert dump(json.encode(LogLevel.warning | LogLevel.debug)) == '"warning | debug"'
}

fn test_enum_attr_decode() {
	assert json.decode(TestStruct2, '{"a": 1, "b":4, "c": "test", "d": 6}')! == TestStruct2{
		a: .exec
		b: Permission.read
		c: 'test'
		d: TestSum2(Permission.write | .read)
	}
}

fn test_enum_attr_encode() {
	assert json.encode(TestStruct2{
		a: .exec
		b: Permission.read
		c: 'test'
		d: TestSum2(Permission.write | .read)
	}) == '{"a":1,"b":4,"c":"test","d":6}'
}

fn test_option_enum() {
	assert dump(json.encode(Test{none, none})) == '{}'
	assert dump(json.encode(Test{none, Permission.exec | Permission.read})) == '{"a":5}'
	t := dump(json.decode(Test, '{"a":5}')!)
	assert t.ab == none
	assert t.a? == .exec | .read

	t2 := dump(json.decode(Test, '{"a":null}')!)
	assert t2.a == none

	assert json.encode(Test2{none}) == '{}'
	assert dump(json.encode(Test2{LogLevel.error | .debug})) == '{"a":"error | debug"}'
	z1 := dump(json.decode(Test2, '{"a":"warning"}')!)
	assert z1.a? == .warning
	z2 := dump(json.decode(Test2, '{"a":"debug | warning"}')!)
	assert z2.a? == .debug | .warning
	a := dump(json.decode(Test2, '{"a": null}')!)
	assert a.a == none
}

fn test_option_sumtype_enum() {
	assert dump(json.encode(Test3{none})) == '{}'
	assert dump(json.encode(Test3{ a: 'foo' })) == '{"a":"foo"}'
	assert dump(json.encode(Test3{ a: Permission.write })) == '{"a":2}'
	assert dump(json.encode(Test3{ a: Permission.exec | Permission.read })) == '{"a":5}'

	assert dump(json.encode(Test4{none})) == '{}'
	assert dump(json.encode(Test4{ a: 'foo' })) == '{"a":"foo"}'
	assert dump(json.encode(Test4{ a: LogLevel.warning })) == '{"a":"warning"}'
	assert dump(json.encode(Test4{ a: LogLevel.debug | LogLevel.info })) == '{"a":"info | debug"}'
}
