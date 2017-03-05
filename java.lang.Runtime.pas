unit java.lang.Runtime;

interface

uses
  AndroidAPI.JNIBridge,
  Androidapi.JNI.JavaTypes,
  java.lang.Process;

type
  JRuntime = interface;

  JRuntimeClass = interface(JObjectClass)
    ['{C90AEB90-F6FA-4C71-8784-32E3E1E1F398}']
    function getRuntime: JRuntime; cdecl;
    procedure runFinalizersOnExit(run: boolean); deprecated; cdecl;
  end;

  [JavaSignature('java/lang/Runtime')]
  JRuntime = interface(JObject)
    ['{9F608DAC-17CB-4D9B-AE00-AE447DFEEFB5}']
    function availableProcessors: Integer; cdecl;
    function exec(prog: JString): JProcess; cdecl; overload;
    function exec(prog: JString; envp: TJavaArray<JString>): JProcess; cdecl; overload;
    function exec(prog: JString; envp: TJavaArray<JString>; directory: JFile): JProcess; cdecl; overload;
    function exec(progArray: TJavaArray<JString>): JProcess; cdecl; overload;
    function exec(progArray: TJavaArray<JString>; envp: TJavaArray<JString>): JProcess; cdecl; overload;
    function exec(progArray: TJavaArray<JString>; envp: TJavaArray<JString>; directory: JFile): JProcess; cdecl; overload;
    function freeMemory: Int64; cdecl;
    function getLocalizedInputStream(stream: JInputStream): JInputStream; deprecated; cdecl;
    function getLocalizedOutputStream(stream: JOutputStream): JOutputStream; deprecated; cdecl;
    function maxMemory: Int64; cdecl;
    function removeShutdownHook(hook: JThread): boolean; cdecl;
    function totalMemory: Int64; cdecl;
    procedure addShutdownHook(hook: JThread); cdecl;
    procedure exit(code: Integer); cdecl;
    procedure gc; cdecl;
    procedure halt(code: Integer); cdecl;
    procedure load(pathName: JString); cdecl;
    procedure loadLibrary(libName: JString); cdecl;
    procedure runFinalization; cdecl;
    procedure traceInstructions(enable: boolean); cdecl;
    procedure traceMethodCalls(enable: boolean); cdecl;
  end;

  TJRuntime = class(TJavaGenericImport<JRuntimeClass, JRuntime>)
  end;

implementation

procedure RegisterTypes;
begin
  TRegTypes.RegisterType('java.lang.Runtime.JRuntime', TypeInfo(java.lang.Runtime.JRuntime));
end;

initialization

RegisterTypes;

end.
