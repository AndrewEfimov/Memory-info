unit Main;

interface

uses
  System.SysUtils, System.Types, System.Classes, System.UITypes, FMX.Types, FMX.Controls, FMX.Forms, FMX.TabControl,
  FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView, FMX.Utils, FMX.Platform,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.MultiView, FMX.Layouts,
  System.Generics.Collections, java.lang.Runtime, Androidapi.Jni, Androidapi.Jni.App, Androidapi.Helpers,
  Androidapi.Jni.GraphicsContentViewText, Androidapi.Jni.JavaTypes, Androidapi.Jni.Os, Androidapi.JNIBridge,
  Utils;

type
  TProcessInfo = record
    importance: Integer;
    importanceReasonCode: Integer;
    importanceReasonPid: Integer;
    lastTrimLevel: Integer;
    lru: Integer;
    pid: Integer;
    // pkgList :String[];
    processName: string;
    uid: Integer;
  end;

  TFormMain = class(TForm)
    TabControl1: TTabControl;
    tiGeneral: TTabItem;
    tiProcessList: TTabItem;
    StyleBook1: TStyleBook;
    lvGeneralInfo: TListView;
    lvProcessList: TListView;
    tiProcessInfo: TTabItem;
    lvProcessInfo: TListView;
    Timer1: TTimer;
    ToolBar1: TToolBar;
    mvMenu: TMultiView;
    sbMenu: TSpeedButton;
    lvMenu: TListView;
    labHeader: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    labCountProcess: TLabel;
    procedure lvProcessListItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    // Общий обработчик для всех листвью
    procedure UpdateItemObjectSize(const Sender: TObject; const AItem: TListViewItem);
    procedure Timer1Timer(Sender: TObject);
    procedure lvMenuItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    { Private declarations }
    FProcessList: TDictionary<Integer, TProcessInfo>;
    FProcessListMemoryInfo: TJavaObjectArray<JDebug_MemoryInfo>;
    FProcessMergeMemory: array of Integer;
    FThreadProcessList: TThread;
    procedure AddDataInListView(LvObject: TListView; AText, ADetail: string; ATag: Integer = 0);
    procedure AddHeaderInListView(LvObject: TListView; AText: string);
    procedure GetGeneralInfo;
    procedure GetProcessList;
    procedure ThreadProcessListTerminated(Sender: TObject);
    procedure ThreadTerminate;
    function HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.fmx}

procedure TFormMain.AddDataInListView(LvObject: TListView; AText, ADetail: string; ATag: Integer = 0);
var
  LItem: TListViewItem;
begin
  LvObject.BeginUpdate;
  try
    LItem := LvObject.Items.Add;
    LItem.Text := AText;
    LItem.Detail := ADetail;
    LItem.Tag := ATag;
  finally
    LvObject.EndUpdate;
  end;
end;

procedure TFormMain.AddHeaderInListView(LvObject: TListView; AText: string);
var
  LItem: TListViewItem;
begin
  LvObject.BeginUpdate;
  try
    LItem := LvObject.Items.Add;
    LItem.Purpose := TListItemPurpose.Header;
    LItem.Text := AText;
  finally
    LvObject.EndUpdate;
  end;
end;

procedure TFormMain.ThreadTerminate;
begin
  if FThreadProcessList <> nil then
  begin
    FThreadProcessList.OnTerminate := nil;
    FThreadProcessList.Terminate;
    FThreadProcessList := nil;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  aFMXApplicationEventService: IFMXApplicationEventService;
  I: Integer;
  LItem: TListViewItem;
begin
  FProcessList := TDictionary<Integer, TProcessInfo>.Create;
  Timer1.Enabled := False;
  TabControl1.ActiveTab := tiGeneral;
  // Fix text change tab
  labHeader.Text := TabControl1.ActiveTab.Text;
  labCountProcess.Visible := False;

  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService,
    IInterface(aFMXApplicationEventService)) then
    aFMXApplicationEventService.SetApplicationEventHandler(HandleAppEvent)
  else
    Log.d('Application Event Service is not supported.');

  // Menu
  lvMenu.BeginUpdate;
  try
    for I := 0 to TabControl1.TabCount - 2 do
    begin
      LItem := lvMenu.Items.Add;
      LItem.Text := TabControl1.Tabs[I].Text;
      LItem.Tag := I;
    end;
  finally
    lvMenu.EndUpdate;
  end;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;
  ThreadTerminate;
  FProcessList.Free;
  FProcessListMemoryInfo.Free;
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkHardwareBack then
    if TabControl1.ActiveTab = tiProcessInfo then
    begin
      TabControl1.ActiveTab := tiProcessList;
      Key := 0;
    end;
end;

procedure TFormMain.GetGeneralInfo;
var
  ActivityManager: JActivityManager;
  MemoryInfo: JActivityManager_MemoryInfo;
  Runtime: JRuntime;
begin
  ActivityManager := TJActivityManager.Wrap
    (TAndroidHelper.Context.getSystemService(TJContext.JavaClass.ACTIVITY_SERVICE));
  MemoryInfo := TJActivityManager_MemoryInfo.JavaClass.init;
  ActivityManager.getMemoryInfo(MemoryInfo);

  lvGeneralInfo.Items.Clear;
  AddHeaderInListView(lvGeneralInfo, 'API Info');
  AddDataInListView(lvGeneralInfo, 'Total memory:', TUtils.FormatBytes(MemoryInfo.totalMem));
  AddDataInListView(lvGeneralInfo, 'Available memory:', TUtils.FormatBytes(MemoryInfo.availMem));
  AddDataInListView(lvGeneralInfo, 'Threshold:', TUtils.FormatBytes(MemoryInfo.threshold));
  AddDataInListView(lvGeneralInfo, 'Low memory(?):', TUtils.BooleanToString(MemoryInfo.lowMemory));

  AddHeaderInListView(lvGeneralInfo, 'JVM Info (this process)');

  Runtime := TJRuntime.JavaClass.getRuntime;
  AddDataInListView(lvGeneralInfo, 'Max memory:', TUtils.FormatBytes(Runtime.maxMemory));
  AddDataInListView(lvGeneralInfo, 'Total allocated memory:', TUtils.FormatBytes(Runtime.totalMemory));
  AddDataInListView(lvGeneralInfo, 'Used memory:',
    TUtils.FormatBytes(Runtime.totalMemory - Runtime.freeMemory));
  AddDataInListView(lvGeneralInfo, 'Currently allocated free memory:', TUtils.FormatBytes(Runtime.freeMemory));
  AddDataInListView(lvGeneralInfo, 'Total free memory:',
    TUtils.FormatBytes(Runtime.maxMemory - (Runtime.totalMemory - Runtime.freeMemory)));
end;

procedure TFormMain.GetProcessList;
begin
  FThreadProcessList := TThread.CreateAnonymousThread(
    procedure
    var
      ActivityManager: JActivityManager;
      List: JList;
      Iterator: JIterator;
      Process: JActivityManager_RunningAppProcessInfo;
      ProcessInfo: TProcessInfo;
      I: Integer;
    begin
      ActivityManager := TJActivityManager.Wrap(TAndroidHelper.Context.getSystemService
        (TJContext.JavaClass.ACTIVITY_SERVICE));
      List := ActivityManager.getRunningAppProcesses;
      Iterator := List.Iterator;

      FProcessList.Clear;
      SetLength(FProcessMergeMemory, List.size);
      I := 0;
      while Iterator.hasNext do
      begin
        Process := TJActivityManager_RunningAppProcessInfo.Wrap(Iterator.next);
        FProcessMergeMemory[I] := Process.pid;
        Inc(I);

        ProcessInfo.importance := Process.importance;
        ProcessInfo.importanceReasonCode := Process.importanceReasonCode;
        ProcessInfo.importanceReasonPid := Process.importanceReasonPid;
        ProcessInfo.lastTrimLevel := Process.lastTrimLevel;
        ProcessInfo.lru := Process.lru;
        ProcessInfo.pid := Process.pid;
        ProcessInfo.processName := JStringToString(Process.processName);
        ProcessInfo.uid := Process.uid;

        FProcessList.Add(Process.pid, ProcessInfo);

        // Fix memory leak
        Process._Release;
      end;

      FProcessListMemoryInfo := ActivityManager.getProcessMemoryInfo(TUtils.IntArrayToJArray(FProcessMergeMemory));
    end);
  FThreadProcessList.OnTerminate := ThreadProcessListTerminated;
  FThreadProcessList.Start;
end;

function TFormMain.HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
begin
  if AAppEvent = TApplicationEvent.WillBecomeForeground then
    Timer1.Enabled := True;

  if AAppEvent = TApplicationEvent.WillBecomeInactive then
    Timer1.Enabled := False;

  if AAppEvent = TApplicationEvent.BecameActive then
    Timer1.Enabled := True;

  Result := True;
end;

procedure TFormMain.lvMenuItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  TabControl1.TabIndex := AItem.Tag;
  mvMenu.HideMaster;
end;

procedure TFormMain.lvProcessListItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  ProcessInfo: TProcessInfo;
  ActivityManager: JActivityManager;
  ProcessMemoryInfo: TJavaObjectArray<JDebug_MemoryInfo>;
begin
  TabControl1.ActiveTab := tiProcessInfo;

  if FProcessList.ContainsKey(AItem.Tag) then
    if FProcessList.TryGetValue(AItem.Tag, ProcessInfo) then
    begin
      lvProcessInfo.Items.Clear;
      AddHeaderInListView(lvProcessInfo, 'General information');

      AddDataInListView(lvProcessInfo, 'Process name:', ProcessInfo.processName);
      AddDataInListView(lvProcessInfo, 'Process ID:', ProcessInfo.pid.ToString);
      AddDataInListView(lvProcessInfo, 'User ID:', ProcessInfo.uid.ToString);
      AddDataInListView(lvProcessInfo, 'Last trim level:', ProcessInfo.lastTrimLevel.ToString);
      AddDataInListView(lvProcessInfo, 'Importance category:', ProcessInfo.importance.ToString);
      AddDataInListView(lvProcessInfo, 'Additional category:', ProcessInfo.lru.ToString);
      AddDataInListView(lvProcessInfo, 'Reason for importance:', ProcessInfo.importanceReasonCode.ToString);

      ActivityManager := TJActivityManager.Wrap
        (TAndroidHelper.Context.getSystemService(TJContext.JavaClass.ACTIVITY_SERVICE));
      ProcessMemoryInfo := ActivityManager.getProcessMemoryInfo(TUtils.IntArrayToJArray([ProcessInfo.pid]));

      AddDataInListView(lvProcessInfo, 'Total Private Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].getTotalPrivateDirty * 1024));
      AddDataInListView(lvProcessInfo, 'Total Pss:', TUtils.FormatBytes(ProcessMemoryInfo[0].getTotalPss * 1024));
      AddDataInListView(lvProcessInfo, 'Total Shared Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].getTotalSharedDirty * 1024));

      AddHeaderInListView(lvProcessInfo, 'Additional Information');

      AddDataInListView(lvProcessInfo, 'Dalvik Private Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].dalvikPrivateDirty * 1024));
      AddDataInListView(lvProcessInfo, 'Dalvik Pss:', TUtils.FormatBytes(ProcessMemoryInfo[0].dalvikPss * 1024));
      AddDataInListView(lvProcessInfo, 'Dalvik Shared Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].dalvikSharedDirty * 1024));
      AddDataInListView(lvProcessInfo, 'Native Private Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].nativePrivateDirty * 1024));
      AddDataInListView(lvProcessInfo, 'Native Pss:', TUtils.FormatBytes(ProcessMemoryInfo[0].nativePss * 1024));
      AddDataInListView(lvProcessInfo, 'Native Shared Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].nativeSharedDirty * 1024));
      AddDataInListView(lvProcessInfo, 'Other Private Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].otherPrivateDirty * 1024));
      AddDataInListView(lvProcessInfo, 'Other Pss:', TUtils.FormatBytes(ProcessMemoryInfo[0].otherPss * 1024));
      AddDataInListView(lvProcessInfo, 'Other Shared Dirty:',
        TUtils.FormatBytes(ProcessMemoryInfo[0].otherSharedDirty * 1024));
    end;
end;

procedure TFormMain.TabControl1Change(Sender: TObject);
begin
  if TabControl1.ActiveTab = tiGeneral then
  begin
    Timer1.Enabled := True;
    labCountProcess.Visible := False;
  end;

  if TabControl1.ActiveTab = tiProcessList then
  begin
    Timer1.Enabled := True;
    labCountProcess.Visible := True;
  end;

  if TabControl1.ActiveTab = tiProcessInfo then
  begin
    Timer1.Enabled := False;
    labCountProcess.Visible := False;
  end;

  labHeader.Text := TabControl1.ActiveTab.Text;
end;

procedure TFormMain.ThreadProcessListTerminated(Sender: TObject);
var
  I: Integer;
  processName, TotalPrivateDirty, TotalPss, TotalSharedDirty: string;
begin
  lvProcessList.Items.Clear;

  for I := 0 to FProcessListMemoryInfo.Length - 1 do
  begin
    processName := FProcessList[FProcessMergeMemory[I]].processName;
    TotalPrivateDirty := 'Total Private Dirty: ' +
      TUtils.FormatBytes(FProcessListMemoryInfo[I].getTotalPrivateDirty * 1024);
    TotalPss := 'Total Pss: ' + TUtils.FormatBytes(FProcessListMemoryInfo[I].getTotalPss * 1024);
    TotalSharedDirty := 'Total Shared Dirty: ' +
      TUtils.FormatBytes(FProcessListMemoryInfo[I].getTotalSharedDirty * 1024);

    AddDataInListView(lvProcessList, processName, TotalPrivateDirty + SLineBreak + TotalPss + SLineBreak +
      TotalSharedDirty, FProcessMergeMemory[I]);
  end;
  labCountProcess.Text := lvProcessList.ItemCount.ToString;
  SetLength(FProcessMergeMemory, 0);
  FThreadProcessList := nil;
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  if TabControl1.ActiveTab = tiGeneral then
  begin
    ThreadTerminate;
    GetGeneralInfo;
  end;

  if TabControl1.ActiveTab = tiProcessList then
    if FThreadProcessList = nil then
      GetProcessList;

  if TabControl1.ActiveTab = tiProcessInfo then
    ThreadTerminate;
end;

procedure TFormMain.UpdateItemObjectSize(const Sender: TObject; const AItem: TListViewItem);
const
  IntentTop = 1;
  IndentBottom = 1;
  IndentLeft = 6;
var
  LvObject: TListView;
  TextObject, DeailObject: TListItemText;
  TextWidth, DetailWidth, TotalWidth, LItemWidth: Single;
  TextHeight, DetailHeight: Single;
begin
  if Sender is TListView then
    if AItem.Purpose <> TListItemPurpose.Header then
    begin
      LvObject := Sender as TListView;
      TextObject := AItem.Objects.TextObject;
      DeailObject := AItem.Objects.DetailObject;

      if LvObject.ItemAppearance.ItemAppearance = 'ListItemRightDetail' then
      begin
        TextWidth := TUtils.GetTextSize(AItem.Text, TextObject.TextAlign, TextObject.Font).Width;
        DetailWidth := TUtils.GetTextSize(AItem.Detail, DeailObject.TextAlign, DeailObject.Font).Width;
        TotalWidth := TextWidth + DetailWidth;
        LItemWidth := LvObject.Width - LvObject.ItemSpaces.Left - LvObject.ItemSpaces.Right;

        if TotalWidth > LItemWidth then
          DetailWidth := DetailWidth - (TotalWidth - LItemWidth);

        TextObject.PlaceOffset.X := 0;
        TextObject.Width := TextWidth;
        DeailObject.PlaceOffset.X := 0;
        DeailObject.Width := DetailWidth;
      end;

      if LvObject.ItemAppearance.ItemAppearance = 'ImageListItemBottomDetail' then
      begin
        TextHeight := TUtils.GetTextSize(AItem.Text, TextObject.TextAlign, TextObject.Font).Height;
        DetailHeight := TUtils.GetTextSize(AItem.Detail, TextObject.TextAlign, DeailObject.Font).Height;
        AItem.Height := Trunc(TextHeight + DetailHeight + ((IndentBottom + IntentTop) * 2));

        TextObject.PlaceOffset.Y := IntentTop;
        TextObject.Height := TextHeight;
        DeailObject.PlaceOffset.Y := TextHeight + IndentBottom;
        DeailObject.PlaceOffset.X := IndentLeft;
        DeailObject.Height := DetailHeight;
      end;
    end;
end;

end.
