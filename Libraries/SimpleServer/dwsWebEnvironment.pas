{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    Copyright Creative IT.                                            }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsWebEnvironment;

interface

uses
   Classes, SysUtils, StrUtils, DateUtils,
   dwsExprs, dwsUtils;

type
   TWebRequestAuthentication = (
      wraNone,
      wraFailed,
      wraBasic,
      wraDigest,
      wraNTLM,
      wraNegotiate,
      wraKerberos
   );
   TWebRequestAuthentications = set of TWebRequestAuthentication;

   TWebRequestMethodVerb = (
      wrmvUnknown,
      wrmvOPTIONS,
      wrmvGET,
      wrmvHEAD,
      wrmvPOST,
      wrmvPUT,
      wrmvDELETE,
      wrmvTRACE,
      wrmvCONNECT,
      wrmvTRACK,
      wrmvMOVE,
      wrmvCOPY,
      wrmvPROPFIND,
      wrmvPROPPATCH,
      wrmvMKCOL,
      wrmvLOCK,
      wrmvUNLOCK,
      wrmvSEARCH
   );

   TWebRequest = class
      private
         FCookies : TStrings;
         FQueryFields : TStrings;
         FCustom : TObject;

      protected
         FPathInfo : String;
         FQueryString : String;

         function GetHeaders : TStrings; virtual; abstract;
         function GetCookies : TStrings;
         function GetQueryFields : TStrings;

         function GetUserAgent : String;

         function GetAuthentication : TWebRequestAuthentication; virtual;
         function GetAuthenticatedUser : String; virtual;

         function PrepareCookies : TStrings; virtual;
         function PrepareQueryFields : TStrings; virtual;

      public
         constructor Create;
         destructor Destroy; override;

         function Header(const headerName : String) : String;

         function RemoteIP : String; virtual; abstract;

         function RawURL : RawByteString; virtual; abstract;
         function URL : String; virtual; abstract;
         function Method : String; virtual; abstract;
         function MethodVerb : TWebRequestMethodVerb; virtual; abstract;
         function Security : String; virtual; abstract;

         function ContentData : RawByteString; virtual; abstract;
         function ContentType : RawByteString; virtual; abstract;

         property PathInfo : String read FPathInfo write FPathInfo;
         property QueryString : String read FQueryString write FQueryString;
         property UserAgent : String read GetUserAgent;

         property Headers : TStrings read GetHeaders;
         property Cookies : TStrings read GetCookies;
         property QueryFields : TStrings read GetQueryFields;

         function HasQueryField(const name : String) : Boolean;

         property Authentication : TWebRequestAuthentication read GetAuthentication;
         property AuthenticatedUser : String read GetAuthenticatedUser;

         // custom object field, freed with the request
         property Custom : TObject read FCustom write FCustom;
   end;

   TWebResponseCookieFlag = (wrcfSecure = 1, wrcfHttpOnly = 2);

   TWebResponseCookie = class
      public
         Name : String;
         Value : String;
         ExpiresGMT : TDateTime;
         Domain : String;
         Path : String;
         MaxAge : Integer;
         Flags : Integer;

         procedure WriteStringLn(dest : TWriteOnlyBlockStream);
   end;

   TWebResponseCookies = class (TSimpleList<TWebResponseCookie>)
      public
         function AddCookie(const name : String) : TWebResponseCookie;
   end;

   TWebResponse = class
      private
         FStatusCode : Integer;
         FContentData : RawByteString;
         FContentType : RawByteString;
         FContentEncoding : RawByteString;
         FHeaders : TStrings;
         FCookies : TWebResponseCookies;  // lazy initialization
         FCompression : Boolean;

      protected
         procedure SetContentText(const textType : RawByteString; const text : String);
         function GetCookies : TWebResponseCookies;

      public
         constructor Create;
         destructor Destroy; override;

         procedure Clear; virtual;

         function HasHeaders : Boolean; inline;
         function HasCookies : Boolean; inline;
         function CompiledHeaders : RawByteString;

         property StatusCode : Integer read FStatusCode write FStatusCode;
         property ContentText[const textType : RawByteString] : String write SetContentText;
         property ContentData : RawByteString read FContentData write FContentData;
         property ContentType : RawByteString read FContentType write FContentType;
         property ContentEncoding : RawByteString read FContentEncoding write FContentEncoding;

         property Headers : TStrings read FHeaders;
         property Cookies : TWebResponseCookies read GetCookies;
         property Compression : Boolean read FCompression write FCompression;
   end;

   IWebEnvironment = interface
      ['{797FDC50-0643-4290-88D1-8BD3C0D7C303}']
      function GetWebRequest : TWebRequest;
      function GetWebResponse : TWebResponse;

      property WebRequest : TWebRequest read GetWebRequest;
      property WebResponse : TWebResponse read GetWebResponse;
   end;

   TWebEnvironment = class (TInterfacedSelfObject, IdwsEnvironment, IWebEnvironment)
      protected
         function GetWebRequest : TWebRequest;
         function GetWebResponse : TWebResponse;

      public
         WebRequest : TWebRequest;
         WebResponse : TWebResponse;
   end;

   TWebEnvironmentHelper = class helper for TProgramInfo
      function WebEnvironment : IWebEnvironment; inline;
      function WebRequest : TWebRequest; inline;
      function WebResponse : TWebResponse; inline;
   end;

const
   cWebRequestAuthenticationToString : array [TWebRequestAuthentication] of String = (
      'None', 'Failed', 'Basic', 'Digest', 'NTLM', 'Negotiate', 'Kerberos'
   );

const
   cWebRequestMethodVerbs : array [TWebRequestMethodVerb] of String = (
      '?', 'OPTIONS', 'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE',
      'CONNECT', 'TRACK', 'MOVE', 'COPY', 'PROPFIND', 'PROPPATCH',
      'MKCOL', 'LOCK', 'UNLOCK', 'SEARCH' );

   cHTMTL_UTF8_CONTENT_TYPE = 'text/html; charset=utf-8';

implementation

// ------------------
// ------------------ TWebEnvironmentHelper ------------------
// ------------------

// WebEnvironment
//
function TWebEnvironmentHelper.WebEnvironment : IWebEnvironment;
begin
   Result:=(Execution.Environment as IWebEnvironment);
end;

// WebRequest
//
function TWebEnvironmentHelper.WebRequest : TWebRequest;
begin
   Result:=WebEnvironment.WebRequest;
end;

// WebResponse
//
function TWebEnvironmentHelper.WebResponse : TWebResponse;
begin
   Result:=WebEnvironment.WebResponse;
end;

// ------------------
// ------------------ TWebRequest ------------------
// ------------------

// Create
//
constructor TWebRequest.Create;
begin
   inherited;
end;

// Destroy
//
destructor TWebRequest.Destroy;
begin
   FQueryFields.Free;
   FCookies.Free;
   FCustom.Free;
   inherited;
end;

// PrepareCookies
//
function TWebRequest.PrepareCookies : TStrings;
var
   base, next, p : Integer;
   cookieField : String;
begin
   Result:=TFastCompareTextList.Create;

   cookieField:=Header('Cookie');
   p:=0;
   base:=1;
   while True do begin
      p:=PosEx('=', cookieField, base);
      next:=PosEx(';', cookieField, p);
      if (p>base) and (next>p) then begin
         Result.Add(Trim(Copy(cookieField, base, p-base))
                    +'='
                    +Copy(cookieField, p+1, next-p));
         base:=next+1;
      end else Break;
   end;
   if (p>base) and (base<Length(cookieField)) then
      Result.Add(Trim(Copy(cookieField, base, p-base))
                 +'='
                 +Copy(cookieField, p+1));
end;

// PrepareQueryFields
//
function TWebRequest.PrepareQueryFields : TStrings;
var
   fields : String;
   base, next : Integer;
begin
   Result:=TStringList.Create;

   fields:=QueryString;
   base:=1;
   while True do begin
      next:=PosEx('&', fields, base);
      if next>base then begin
         Result.Add(Copy(fields, base, next-base));
         base:=next+1;
      end else begin
         if base<Length(fields) then
            Result.Add(Copy(fields, base));
         Break;
      end;
   end;
end;

// Header
//
function TWebRequest.Header(const headerName : String) : String;
begin
   Result:=Headers.Values[headerName];
end;

// GetCookies
//
function TWebRequest.GetCookies : TStrings;
begin
   if FCookies=nil then
      FCookies:=PrepareCookies;
   Result:=FCookies;
end;

// GetQueryFields
//
function TWebRequest.GetQueryFields : TStrings;
begin
   if FQueryFields=nil then
      FQueryFields:=PrepareQueryFields;
   Result:=FQueryFields;
end;

// HasQueryField
//
function TWebRequest.HasQueryField(const name : String) : Boolean;
var
   i, n : Integer;
   fields : TStrings;
   elem : String;
begin
   fields:=QueryFields;
   for i:=0 to fields.Count-1 do begin
      elem:=fields[i];
      if StrBeginsWith(elem, name) then begin
         n:=Length(name);
         if (Length(elem)=n) or (elem[n+1]='=') then
            Exit(True);
      end;
   end;
   Result:=False;
end;

// GetUserAgent
//
function TWebRequest.GetUserAgent : String;
begin
   Result:=Header('User-Agent');
end;

// GetAuthentication
//
function TWebRequest.GetAuthentication : TWebRequestAuthentication;
begin
   Result:=wraNone;
end;

// GetAuthenticatedUser
//
function TWebRequest.GetAuthenticatedUser : String;
begin
   Result:='';
end;

// ------------------
// ------------------ TWebEnvironment ------------------
// ------------------

// GetWebRequest
//
function TWebEnvironment.GetWebRequest : TWebRequest;
begin
   Result:=WebRequest;
end;

// GetWebResponse
//
function TWebEnvironment.GetWebResponse : TWebResponse;
begin
   Result:=WebResponse;
end;

// ------------------
// ------------------ TWebResponse ------------------
// ------------------

// Create
//
constructor TWebResponse.Create;
begin
   inherited;
   FHeaders:=TFastCompareStringList.Create;
   FCompression:=True;
end;

// Destroy
//
destructor TWebResponse.Destroy;
begin
   FHeaders.Free;
   FCookies.Free;
   inherited;
end;

// Clear
//
procedure TWebResponse.Clear;
begin
   FStatusCode:=200;
   FContentType:=cHTMTL_UTF8_CONTENT_TYPE;
   FContentData:='';
   FContentEncoding:='';
   FHeaders.Clear;
   if FCookies<>nil then
      FCookies.Clear;
end;

// HasHeaders
//
function TWebResponse.HasHeaders : Boolean;
begin
   Result:=(FHeaders.Count>0) or HasCookies;
end;

// CompiledHeaders
//
function TWebResponse.CompiledHeaders : RawByteString;
var
   i, p : Integer;
   wobs : TWriteOnlyBlockStream;
   buf : String;
begin
   wobs:=TWriteOnlyBlockStream.Create;
   try
      for i:=0 to Headers.Count-1 do begin
         buf:=FHeaders[i];
         p:=Pos('=', buf);
         wobs.WriteSubString(buf, 1, p-1);
         wobs.WriteString(': ');
         wobs.WriteSubString(buf, p+1);
         wobs.WriteCRLF;
      end;
      if HasCookies then
         for i:=0 to Cookies.Count-1 do
            FCookies[i].WriteStringLn(wobs);
      Result:=wobs.ToUTF8String;
   finally
      wobs.Free;
   end;
end;

// HasCookies
//
function TWebResponse.HasCookies : Boolean;
begin
   Result:=(FCookies<>nil) and (FCookies.Count>0);
end;

// SetContentText
//
procedure TWebResponse.SetContentText(const textType : RawByteString; const text : String);
begin
   ContentType:='text/'+textType+'; charset=utf-8';
   ContentData:=UTF8Encode(text);
end;

// GetCookies
//
function TWebResponse.GetCookies : TWebResponseCookies;
begin
   if FCookies=nil then
      FCookies:=TWebResponseCookies.Create;
   Result:=FCookies;
end;

// ------------------
// ------------------ TWebResponseCookies ------------------
// ------------------

// WriteStringLn
//
procedure TWebResponseCookie.WriteStringLn(dest : TWriteOnlyBlockStream);
const
   cMonths : array [1..12] of String = (
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' );
   cWeekDays : array [1..7] of String = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' );
var
   y, m, d : Word;
   h, n, s, z : Word;
begin
   dest.WriteString('Set-Cookie: ');
   dest.WriteString(Name);
   dest.WriteChar('=');
   dest.WriteString(Value);

   if ExpiresGMT<>0 then begin
      dest.WriteString('; Expires=');
      if ExpiresGMT<0 then
         dest.WriteString('Sat, 01 Jan 2000 00:00:01 GMT')
      else begin
         dest.WriteString(cWeekDays[DayOfTheWeek(ExpiresGMT)]);
         DecodeDateTime(ExpiresGMT, y, m, d, h, n, s, z);
         dest.WriteString(Format(', %.02d %s %d %.02d:%.02d:%.02d GMT',
                                 [d, cMonths[m], y, h, n, s]));
      end;
   end;

   if MaxAge<>0 then begin
      dest.WriteString('; Max-Age=');
      dest.WriteString(MaxAge);
   end;

   if Path<>'' then begin
      dest.WriteString('; Path=');
      dest.WriteString(Path);
   end;

   if Domain<>'' then begin
      dest.WriteString('; Domain=');
      dest.WriteString(Domain);
   end;

   if (Flags and Ord(wrcfSecure))<>0 then
      dest.WriteString('; Secure');

   if (Flags and Ord(wrcfHttpOnly))<>0 then
      dest.WriteString('; HttpOnly');

   dest.WriteCRLF;
end;

// ------------------
// ------------------ TWebResponseCookie ------------------
// ------------------

// AddCookie
//
function TWebResponseCookies.AddCookie(const name : String) : TWebResponseCookie;
begin
   Result:=TWebResponseCookie.Create;
   Result.Name:=name;
   Add(Result);
end;

end.
