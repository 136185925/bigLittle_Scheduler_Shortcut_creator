import 'dart:async';
import 'package:scheduler/river.dart';
import 'package:system_info2/system_info2.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:cmd_plus/cmd_plus.dart';
import 'package:process_run/process_run.dart';

import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'package:process_run/shell.dart';
import 'package:process_run/cmd_run.dart';

String sourceText = "";
String targetText = "";
String myText = "msedge";
const List<String> list = <String>['只用大核', '只用小核', '只用大核+超线程'];

void getSchedule() async {
  String s = r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ';
  //if (sourceText != '' && targetText != '') {
  s = s + r'-ExecutionPolicy Bypass "Get-Process ';
  s = s + "$sourceText | Select-Object ";
  s = s + r'ProcessorAffinity"';

  var shell = Shell();
  var process = await shell.run(s);

  String result = processResultToDebugString(process.first);
  //final intRegex = RegExp(r'(\d{10})', multiLine: false);
  List<String> newResult = result.split("-----------------");
  List<String> newResult2 = newResult[1].split("\n");
  List<String> newResult3 = newResult2[1].split(" ");
  // final match = intRegex.firstMatch(result)!;
  // final message = jsonEncode(match[1]!);
  final newMessage = newResult3.last.replaceAll(RegExp('[^0-9]'), '');
  // print("123123");
  // print(newMessage);
  int num = int.parse(newMessage);
  targetText = num.toRadixString(2).toString();
  // print(targetText);
  // print(num.toRadixString(2));
}

String forceBig() {
  String num = "";
  int bigC = Platform.numberOfProcessors - SysInfo.cores.length;
  for (int i = 0; i < bigC; i++) {
    num = num + "01";
  }
  var val = int.parse(num, radix: 2).toRadixString(10);
  return val;
}

String forceBigT() {
  String num = "";
  int bigC = Platform.numberOfProcessors - SysInfo.cores.length;
  for (int i = 0; i < bigC; i++) {
    num = num + "11";
  }
  var val = int.parse(num, radix: 2).toRadixString(10);
  return val;
}

String forceSmall() {
  String num = "";
  int bigC = Platform.numberOfProcessors - SysInfo.cores.length;
  int smallC = SysInfo.cores.length - bigC;
  for (int i = 0; i < smallC; i++) {
    num = num + "1";
  }
  for (int i = 0; i < bigC; i++) {
    num = num + "00";
  }
  var val = int.parse(num, radix: 2).toRadixString(10);
  return val;
}

void setSchedule(choice) async {
  String val = forceBig();
  if (choice == "big") {
    val = forceBig();
  } else if (choice == "small") {
    val = forceSmall();
  } else if (choice == "bigT") {
    val = forceBigT();
  }

  String s = r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ';
  //if (sourceText != '' && targetText != '') {
  s = s + r'-ExecutionPolicy Bypass "$p = Get-Process ';
  s = s + "$sourceText; ";
  s = s + r'$p.ProcessorAffinity = ';
  s = s + "$val";
  s = s + r'"';
  print(forceBig());

  var shell = Shell();
  var process = await shell.run(s);

  // String result = processResultToDebugString(process.first);
  // final intRegex = RegExp(r'(\d{10})', multiLine: false);
  // final match = intRegex.firstMatch(result)!;
  // final message = jsonEncode(match[1]!);
  // final newMessage = message.replaceAll(RegExp('[^0-9]'), '');
  // int num = int.parse(newMessage);
  // targetText = num.toRadixString(2).toString();
  // print(targetText);
  // print(num.toRadixString(2));
}

final myProvider = ChangeNotifierProvider<RegValues>((ref) => RegValues());
String powerStatus = '';
String rawPowerStatus = '';
int calculated = 100;

void getPowerStatus() {
  var keyPath = r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes';
  var key = Registry.openPath(RegistryHive.localMachine, path: keyPath);

  // print('Values:');
  // for (final value in key.values) {
  //   print(' - ${value.toString()}');
  // }
  final currentPowerScheme = key.getValueAsString('ActivePowerScheme');
  // if (currentPowerScheme != null) {
  //   print('Windows build number: $currentPowerScheme');
  // }

  if (currentPowerScheme == "e9a42b02-d5df-448d-aa00-03f14749eb61") {
    powerStatus = "卓越性能";
    rawPowerStatus = currentPowerScheme ?? '';
  } else if (currentPowerScheme == "381b4222-f694-41f0-9685-ff5bb260df2e") {
    powerStatus = "平衡";
    rawPowerStatus = currentPowerScheme ?? '';
  } else if (currentPowerScheme == "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c") {
    powerStatus = "高性能";
    rawPowerStatus = currentPowerScheme ?? '';
  } else if (currentPowerScheme == "a1841308-3541-4fab-bc81-f71556f20b4a") {
    powerStatus = "节能";
    rawPowerStatus = currentPowerScheme ?? '';
  } else {
    powerStatus = currentPowerScheme ?? '';
    rawPowerStatus = currentPowerScheme ?? '';
  }

  key.close();
}

Future<void> setPowerStatusAC() async {
  double val = SysInfo.cores.length / Platform.numberOfProcessors;
  val = (val * 100).ceilToDouble();
  calculated = val.round();
  final cmdPlus = CmdPlus();
  if (powerStatus != '') {
    await cmdPlus.run(
        "powercfg -setacvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2",
        []);
    await cmdPlus.run(
        "powercfg -setacvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 $calculated",
        []);
    await cmdPlus.run(
        "powercfg -setacvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 7f2f5cfa-f10c-4823-b5e1-e93ae85f46b5 0",
        []);
  }
  await cmdPlus.close();
}

Future<void> setPowerStatusDC() async {
  double val = SysInfo.cores.length / Platform.numberOfProcessors;
  val = (val * 100).ceilToDouble();
  calculated = val.round();
  final cmdPlus = CmdPlus();
  if (powerStatus != '') {
    await cmdPlus.run(
        "powercfg -setdcvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2",
        []);
    await cmdPlus.run(
        "powercfg -setdcvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 $calculated",
        []);
    await cmdPlus.run(
        "powercfg -setdcvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 7f2f5cfa-f10c-4823-b5e1-e93ae85f46b5 0",
        []);
  }
  await cmdPlus.close();
}

Future<void> restoreDefault() async {
  final cmdPlus = CmdPlus();
  if (powerStatus != '') {
    await cmdPlus.run(
        "powercfg -setacvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5",
        []);
    await cmdPlus.run(
        "powercfg -setdcvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5",
        []);
    await cmdPlus.run(
        "powercfg -setacvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100",
        []);
    await cmdPlus.run(
        "powercfg -setdcvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100",
        []);
    await cmdPlus.run(
        "powercfg -setacvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 7f2f5cfa-f10c-4823-b5e1-e93ae85f46b5 4",
        []);
    await cmdPlus.run(
        "powercfg -setdcvalueindex $rawPowerStatus 54533251-82be-4824-96c1-47b60b740d00 7f2f5cfa-f10c-4823-b5e1-e93ae85f46b5 4",
        []);
  }

  await cmdPlus.close();
}

void main() {
  getPowerStatus();
  runApp(ProviderScope(child: MyApp()));
  // Timer.periodic(const Duration(seconds: 2), (timer) {
  //   print('delayed execution');
  // });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});
  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  String dropdownValue = list.first;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('QQ群135483909'),
            Text('调度先锋V1.0'),
          ],
        ),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(child: _Card1(powerStatus)),
            // Expanded(child: _Card2(context)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("指定你想运行的程序的调度方式，例如 qq "),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入被运行软件的名称，并去掉exe',
                      ),
                      onChanged: (value) {
                        sourceText = value;
                      },
                    ),
                  ),
                  Text("当前的调度模式 从小核到大核为 "),
                  Text(
                    targetText,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      getSchedule();
                      Timer.periodic(const Duration(seconds: 1), (timer) {
                        setState(() {});
                      });
                    },
                    child: Text("获取当前应用的调度模式"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("选择你想要的调度策略:"),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: dropdownValue,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          underline: Container(
                            height: 2,
                            color: Colors.deepPurpleAccent,
                          ),
                          onChanged: (String? value) {
                            // This is called when the user selects an item.
                            setState(() {
                              dropdownValue = value!;
                            });
                          },
                          items: list
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (dropdownValue == "只用大核") {
                              setSchedule("big");
                            } else if (dropdownValue == "只用小核") {
                              setSchedule("small");
                            } else if (dropdownValue == "只用大核+超线程") {
                              setSchedule("bigT");
                            }
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("消息"),
                                    content: Text("完成"),
                                  );
                                });
                          });
                        },
                        child: Text("设置你想要的调度"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            targetText = "";
                          });
                        },
                        child: Text("刷新/清空"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _Card1(value) {
  return Container(
    margin: EdgeInsets.all(15.0),
    decoration: BoxDecoration(
      //olor: Colors.grey,
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(('操作系统 : ${SysInfo.operatingSystemName}')),
              Text(('内核架构 : ${SysInfo.rawKernelArchitecture}')),
              Text(('内核版本 : ${SysInfo.kernelVersion}')),
              Text(('CPU : ${SysInfo.cores.first.name}')),
              Text(('物理核心数 : ${SysInfo.cores.length}')),
              Text(('总线程数 : ${Platform.numberOfProcessors}')),
              Text(
                  ('总物理内存 : ${SysInfo.getTotalPhysicalMemory() ~/ 1048576} MB')),
              Text(
                  ('可用物理内存 : ${SysInfo.getFreePhysicalMemory() ~/ 1048576} MB')),
              Text(('当前电源计划 : $value')),
            ],
          ),
          //   print
        )
      ],
    ),
  );
}

Widget _Card2(context) {
  return Container(
    margin: EdgeInsets.all(15.0),
    decoration: BoxDecoration(
      color: Colors.yellow,
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Text(
      '0',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}

// void main() {




// final subkey = key.createKey("DemoTestKey");

// const dword = RegistryValue('TestDWORD', RegistryValueType.int32, 0xFACEFEED);
// subkey.createValue(dword);

// const qword =
//     RegistryValue('TestQWORD', RegistryValueType.int64, 0x0123456789ABCDEF);
// subkey.createValue(qword);

// const string = RegistryValue(
//   'TestString',
//   RegistryValueType.string,
//   'The human race has one really effective weapon, and that is laughter.',
// );
// subkey
//   ..createValue(string)
//   ..close();

// key.close();


// }
