unit java.lang.Process;

interface

uses
  AndroidAPI.JNIBridge,
  Androidapi.JNI.JavaTypes;

type
  JProcess = interface;

  JProcessClass = interface(JObjectClass)
    ['{23225FD1-B984-4EF7-99E8-FC1062C3F6CC}']
  end;

  [JavaSignature('java/lang/Process')]
  JProcess = interface(JObject)
    ['{957C599A-C4DE-4A2E-BCDE-2903E06F45F1}']
    function exitValue: Integer; cdecl;
    function getErrorStream: JInputStream; cdecl;
    function getInputStream: JInputStream; cdecl;
    function getOutputStream: JOutputStream; cdecl;
    function waitFor: Integer; cdecl;
    procedure destroy ; cdecl;
  end;

  TJProcess = class(TJavaGenericImport<JProcessClass, JProcess>)
  end;

implementation

procedure RegisterTypes;
begin
  TRegTypes.RegisterType('java.lang.Process.JProcess', TypeInfo(java.lang.Process.JProcess));
end;

initialization

RegisterTypes;

end.
