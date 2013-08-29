program LanguageTests;

{$SetPEFlags $0001}

{$IFNDEF VER200}
{.$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}

uses
  Classes,
  Forms,
  Windows,
  TestFrameWork,
  GUITestRunner,
  SysUtils,
  dwsXPlatform,
  dwsMathComplexFunctions in '..\Source\dwsMathComplexFunctions.pas',
  dwsMath3DFunctions in '..\Source\dwsMath3DFunctions.pas',
  dwsDebugFunctions in '..\Source\dwsDebugFunctions.pas',
  dwsLinq,
  dwsLinqSql in '..\Libraries\LinqLib\dwsLinqSql.pas',
  dwsLinqJson in '..\Libraries\LinqLib\dwsLinqJson.pas',
  UScriptTests in 'UScriptTests.pas',
  UAlgorithmsTests in 'UAlgorithmsTests.pas',
  UdwsUnitTests in 'UdwsUnitTests.pas',
  UdwsUnitTestsStatic in 'UdwsUnitTestsStatic.pas',
  UHTMLFilterTests in 'UHTMLFilterTests.pas',
  UCornerCasesTests in 'UCornerCasesTests.pas',
  UdwsClassesTests in 'UdwsClassesTests.pas',
  dwsClasses in '..\Libraries\ClassesLib\dwsClasses.pas',
  UdwsDataBaseTests in 'UdwsDataBaseTests.pas',
  UdwsFunctionsTests in 'UdwsFunctionsTests.pas',
  UCOMConnectorTests in 'UCOMConnectorTests.pas',
  UTestDispatcher in 'UTestDispatcher.pas',
  UDebuggerTests in 'UDebuggerTests.pas',
  UdwsUtilsTests in 'UdwsUtilsTests.pas',
  UMemoryTests in 'UMemoryTests.pas',
  UBuildTests in 'UBuildTests.pas',
  USourceUtilsTests in 'USourceUtilsTests.pas',
  ULocalizerTests in 'ULocalizerTests.pas',
  dwsRTTIFunctions,
  UJSONTests in 'UJSONTests.pas',
  UJSONConnectorTests in 'UJSONConnectorTests.pas',
  UTokenizerTests in 'UTokenizerTests.pas',
  ULanguageExtensionTests in 'ULanguageExtensionTests.pas',
  UJITTests in 'UJITTests.pas',
{$IFDEF WIN32}
  UJITx86Tests in 'UJITx86Tests.pas',
  ULinqTests in 'ULinqTests.pas',
{$IF RTLVersion >= 21}
  dwsSynSQLiteDatabase in '..\Libraries\DatabaseLib\dwsSynSQLiteDatabase.pas',
  URTTIExposeTests in 'URTTIExposeTests.pas',
  USpecialTestsRTTI in 'USpecialTestsRTTI.pas',
{$IFEND}
{$ENDIF}
  ULinqJsonTests in 'ULinqJsonTests.pas';

{$R *.res}

var
{$IF RTLVersion >= 23}
   procAffinity, systAffinity : NativeUInt;
{$ELSE}
   procAffinity, systAffinity : DWORD;
{$IFEND}
begin
   DirectSet8087CW($133F);
   GetProcessAffinityMask(GetCurrentProcess, procAffinity, systAffinity);
   SetProcessAffinityMask(GetCurrentProcess, systAffinity);
   SetDecimalSeparator('.');
   ReportMemoryLeaksOnShutdown:=True;
   Application.Initialize;
   GUITestRunner.RunRegisteredTests;
end.

