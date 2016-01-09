unit user_util;

{$mode objfpc}{$H+}

interface

uses
  security_util, user_model,
  fpcgi, common, Math, Classes, SysUtils;

const
  PASSWORD_LENGTH_MIN = 5;
  USER_GROUP_DEFAULT_ID = 1;
  USER_GROUP_DEFAULT_NAME = 'Users';
  {$include define_cms.inc}

type

  { TUsersUtil }

  TUsersUtil = class(TUserModel)
  private
    function getLoggedInUserID: longint;
  public
    constructor Create(const DefaultTableName: string = '');
    destructor Destroy; override;
    property UserIdLoggedIn: longint read getLoggedInUserID;

    function isLoggedIn: boolean;
    function Login(const Username: string; const Password: string;
      RememberMe: boolean = False): boolean;
    function Logout: boolean;

    function checkPermission(Component: string = ''; Instance: string = '';
      Level: integer = ACCESS_NONE): boolean;

  end;

implementation

uses
  fastplaz_handler, group_util, permission_util;

{ TUsersUtil }

function TUsersUtil.getLoggedInUserID: longint;
var
  uid: string;
begin
  Result := 0;
  if SessionController.IsExpired then
  begin
    Logout;
    Exit;
  end;

  uid := _SESSION['uid'];
  if uid <> '' then  //-- simple check
    Result := s2i(uid);
end;

constructor TUsersUtil.Create(const DefaultTableName: string);
begin
  inherited Create;
end;

destructor TUsersUtil.Destroy;
begin
  inherited Destroy;
end;

function TUsersUtil.isLoggedIn: boolean;
var
  uid: string;
begin
  Result := False;
  if SessionController.IsExpired then
  begin
    Logout;
    Exit;
  end;

  uid := _SESSION['uid'];
  if uid <> '' then  //-- simple check
    Result := True;
end;

function TUsersUtil.Login(const Username: string; const Password: string;
  RememberMe: boolean): boolean;
var
  hashedData: string;
begin
  Result := False;
  if FindFirst([USER_FIELDNAME_USERNAME + '="' + Username + '"'],
    USER_FIELDNAME_ID + ' desc') then
  begin
    hashedData := Data[USER_FIELDNAME_PASSWORD];
    with TSecurityUtil.Create do
    begin
      if CheckSaltedHash(Password, hashedData) then
      begin
        // save session
        _SESSION['uid'] := Data[USER_FIELDNAME_ID];
        _SESSION['uname'] := Data[USER_FIELDNAME_USERNAME];
        _SESSION['rememberme'] := RememberMe;

        Result := True;
      end;
      Free;
    end;
  end
  else
    SessionController.EndSession;
end;

function TUsersUtil.Logout: boolean;
begin
  try
    SessionController.EndSession(False);
  except
  end;
  Result := True;
end;

function TUsersUtil.checkPermission(Component: string; Instance: string;
  Level: integer): boolean;
begin
  Result := False;

  if UserIdLoggedIn = 0 then
  begin
    Exit;
  end;

  with TPermissionUtil.Create() do
  begin
    Result := checkPermission(Component, Instance, Level);
    Free;
  end;

end;

end.
