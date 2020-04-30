{******************************************************************************}
{                                                                              }
{  Delphi SwagDoc Library                                                      }
{  Copyright (c) 2018 Marcelo Jaloto                                           }
{  https://github.com/marcelojaloto/SwagDoc                                    }
{                                                                              }
{  Sample author: geoffsmith82 - 2019                                          }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

unit Sample.DelphiUnit.Generate;

interface

uses
  System.Classes,
  System.Json,
  System.SysUtils,
  System.StrUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.Generics.Defaults;

type
  TUnitTypeDefinition = class;

  TUnitFieldDefinition = class
  strict private
    fFieldName: string;
    fFieldType: string;
    fVisibility: TMemberVisibility;
    fAttributes: TStringList;
    fDescription: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddAttribute(const pAttribute: string);

    function GenerateInterface(pOnType: TUnitTypeDefinition): string;
    function IsSimpleType: Boolean;

    property FieldName: string read fFieldName write fFieldName;
    property FieldType: string read fFieldType write fFieldType;
    property Visibility: TMemberVisibility read fVisibility write fVisibility;
    property Description: string read fDescription write fDescription;
  end;

  TUnitParameter = class
  strict private
    fFlags: TParamFlags;
    fType: TUnitTypeDefinition;
    fParamName: string;
    fAttributes: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddAttribute(const pAttribute: string);

    property Attributes: TStringList read fAttributes write fAttributes;
    property ParamName: string read fParamName write fParamName;
    property Flags: TParamFlags read fFlags write fFlags;
    property ParamType: TUnitTypeDefinition read fType write fType;
  end;

  TUnitPropertyDefinition = class
  strict private
    fFieldName: string;
    fFieldType: string;
    fVisibility: TMemberVisibility;
    fAttributes: TStringList;
    fDescription: string;
    FPropWrite: string;
    FPropRead: string;
    fParams: TObjectList<TUnitParameter>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddAttribute(const pAttribute: string);

    function GenerateInterface(pOnType: TUnitTypeDefinition): string;
    function IsSimpleType: Boolean;

    procedure AddParameter(pParam: TUnitParameter);

    property PropertyRead: string read FPropRead write fPropRead;
    property PropertyWrite: string read FPropWrite write FPropWrite;
    property PropertyName: string read fFieldName write fFieldName;
    property PropertyType: string read fFieldType write fFieldType;
    property Visibility: TMemberVisibility read fVisibility write fVisibility;
    property Description: string read fDescription write fDescription;
  end;

  TUnitMethod = class
  strict private
    fAttributes: TStringList;
    fMethodKind: TMethodKind;
    fVisibility: TMemberVisibility;
    fName: string;
    fIsStatic: Boolean;
    fIsClassMethod: Boolean;
    fIsOverrideMethod: Boolean;
    fReturnType: TUnitTypeDefinition;
    fParams: TObjectList<TUnitParameter>;
    fVars: TObjectList<TUnitParameter>;
    fContent: TStringList;
    fParentType: TUnitTypeDefinition;

    procedure ParametersToDelphiString(var pParamString: string; pIncludeAttributes: Boolean);
    function ParametersToDelphiSignature: string;
    procedure MethodLocalVarsToDelphiString(pFuncSL: TStringList);

    function MethodKindToDelphiString(var pHasReturn: Boolean): string;
    function GetIsConstructor: Boolean;
    function GetIsDestructor: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddParameter(pParam: TUnitParameter);
    procedure AddLocalVariable(pVar: TUnitParameter);
    procedure AddAttribute(const pAttribute: string);

    function GetParameters: TArray<TUnitParameter>;
    function GenerateInterface(pOnType: TUnitTypeDefinition): string;
    function GenerateImplementation(pOnType: TUnitTypeDefinition): string;
    function Signature: string;

    property Content: TStringList read fContent write fContent;
    property MethodKind: TMethodKind read fMethodKind write fMethodKind;
    property Visibility: TMemberVisibility read fVisibility write fVisibility;
    property Name: string read fName write fName;
    property IsConstructor: Boolean read GetIsConstructor;
    property IsDestructor: Boolean read GetIsDestructor;
    property IsClassMethod: Boolean read fIsClassMethod write fIsClassMethod;
    property IsOverrideMethod: Boolean read fIsOverrideMethod write fIsOverrideMethod;
    // Static: No 'Self' parameter
    property IsStatic: Boolean read fIsStatic write fIsStatic;
    property ReturnType: TUnitTypeDefinition read fReturnType write fReturnType;
    property ParentType: TUnitTypeDefinition read fParentType write fParentType;
  end;

  TUnitTypeDefinition = class
  strict private
    fTypeName: string;
    fTypeInheritedFrom: string;
    fAttributes: TStringList;
    fTypeKind: TTypeKind;
    fForwardDeclare: Boolean;
    fGuid : TGUID;
    fFields: TObjectList<TUnitFieldDefinition>;
    fProperties : TObjectList<TUnitPropertyDefinition>;
    fMethods: TObjectList<TUnitMethod>;
  protected
    fCurrentVisibility: TMemberVisibility;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddAttribute(const pAttribute: string);
    procedure AddMethod(const pMethod: TUnitMethod);

    function GetMethods: TArray<TUnitMethod>;
    function GenerateInterface: string;
    function GenerateForwardInterface: string;

    function GetMethodsByName(const pMethodName: string): TArray<TUnitMethod>;
    function LookupPropertyByName(const pTypeName: string): TUnitPropertyDefinition;

    property Guid: TGUID read fGuid write fGuid;
    property TypeName: string read fTypeName write fTypeName;
    property TypeKind: TTypeKind read fTypeKind write fTypeKind;
    property TypeInherited: string read fTypeInheritedFrom write fTypeInheritedFrom;
    property ForwardDeclare: Boolean read fForwardDeclare write fForwardDeclare;
    property Fields: TObjectList<TUnitFieldDefinition> read fFields;
    property Methods: TObjectList<TUnitMethod> read fMethods;
    property Properties: TObjectList<TUnitPropertyDefinition> read fProperties;
  end;

  TDelphiObjectNode = class
  protected
    FContainedObject : TUnitTypeDefinition;
    FEdges : TObjectList<TDelphiObjectNode>;
    FParents : TObjectList<TDelphiObjectNode>;
    procedure DependencyResolve(pList: TObjectList<TDelphiObjectNode>; pNode: TDelphiObjectNode);
  public
    constructor Create(pType: TUnitTypeDefinition);
    destructor Destroy; override;
    procedure AddEdge(pNode: TDelphiObjectNode);
  end;

  TDelphiObjectNodeComparer = class(TComparer<TDelphiObjectNode>)
    function Compare(const Left, Right: TDelphiObjectNode): Integer; override;
  end;



  TDelphiObjectList = class
  private
    fListOfTypes : TObjectList<TDelphiObjectNode>;
    function FindNode(const pTypeName: string): TDelphiObjectNode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddType(pType : TUnitTypeDefinition);
    procedure OrderedList(pList : TObjectList<TUnitTypeDefinition>);
  end;

  TDelphiUnit = class
  strict private
    fInterfaceUses: TStringList;
    fImplementationUses: TStringList;
    fInterfaceConstant: TStringList;
    fInterfaceVar: TStringList;
    fImplementationConstant: TStringList;
    fUnitName: string;
    fTitle: string;
    fDescription: string;
    fLicense: string;
    fTypeDefinitions: TObjectList<TUnitTypeDefinition>;
    fUnitHasResourceFile: Boolean;
    fUnitMethods : TObjectList<TUnitMethod>;
  private
    function GenerateInterfaceVar: string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure SaveToFile(const pFilename: string);

    function Generate: string;
    function GenerateInterfaceSectionStart: string; virtual;
    function GenerateInterfaceUses: string; virtual;
    function GenerateImplementationSectionStart: string; virtual;
    function GenerateImplementationUses: string; virtual;
    function GenerateImplementationConstants: string; virtual;
    function CreateGUID: TGuid;

    procedure AddInterfaceUnit(const pFilename: string); virtual;
    procedure AddInterfaceConstant(const pName: string; const pValue: string);
    procedure AddInterfaceVar(const pName:string; pTypeInfo: TUnitTypeDefinition);
    procedure AddImplementationUnit(const pFilename: string); virtual;
    procedure AddImplementationConstant(const pName: string; const pValue: string);
    procedure AddUnitMethod(pMethod: TUnitMethod);
    function LookupUnitMethodByName(const pMethodName: string): TUnitMethod;
    procedure AddType(pTypeInfo: TUnitTypeDefinition);
    function LookupTypeByName(const pTypeName: string): TUnitTypeDefinition;
    function RemoveInterfaceUnit(const pFilename: string): Boolean; virtual;
    function RemoveImplementationUnit(const pFilename: string): Boolean; virtual;
    procedure SortTypeDefinitions;

    property UnitFile: string read fUnitName write fUnitName;
    property UnitHasResourceFile: Boolean read fUnitHasResourceFile write fUnitHasResourceFile;
    property Title: string read fTitle write fTitle;
    property Description: string read fDescription write fDescription;
    property License: string read fLicense write fLicense;
  end;

  TDelphiDPR = class(TDelphiUnit)

  end;

function SafeDescription(const pDescription: string): string;

implementation

uses
  System.IOUtils
  ;

function MemberVisibilityToString(const pVisibility: TMemberVisibility): string;
begin
  case pVisibility of
    mvPrivate: Result := 'private';
    mvProtected: Result := 'protected';
    mvPublic: Result := 'public';
    mvPublished: Result := 'published';
  end;
end;

function SafeDescription(const pDescription: string): string;
begin
  { TODO : Needs more work to make description safe }
  Result := QuotedStr(Trim(pDescription)).Replace(#13#10,'').Replace(#13,'').Replace(#10,'');
end;

function DelphiVarName(const pVarName: string):string;
const
  reservedWords : array [0.. 64] of string = ('and', 'array', 'as', 'asm', 'begin', 'case', 'class', 'const', 'constructor', 'destructor', 'dispinterface', 'div', 'do', 'downto', 'else', 'end', 'except', 'exports', 'file', 'finalization', 'finally', 'for', 'function', 'goto', 'if', 'implementation', 'in', 'inherited', 'initialization', 'inline', 'interface', 'is', 'label', 'library', 'mod', 'nil', 'not', 'object', 'of', 'or', 'out', 'packed', 'procedure', 'program', 'property', 'raise', 'record', 'repeat', 'resourcestring', 'set', 'shl', 'shr', 'string', 'then', 'threadvar', 'to', 'try', 'type', 'unit', 'until', 'uses', 'var', 'while', 'with', 'xor');
var
  i: Integer;
  tmpVar: string;
begin
  Result := pVarName;
  tmpVar := pVarName.ToLower;
  for i := 0 to Length(reservedWords) - 1 do
  begin
    if reservedWords[i] = tmpVar then
    begin
      Result := '&' + Result;
      Break;
    end;
  end;
end;

{ TDelphiUnit }

procedure TDelphiUnit.AddImplementationConstant(const pName, pValue: string);
begin
  fImplementationConstant.AddPair(pName, pValue);
end;

procedure TDelphiUnit.AddImplementationUnit(const pFilename: string);
var
  vInterfaceIndex : Integer;
begin
  vInterfaceIndex := fInterfaceUses.IndexOf(pFilename);
  if vInterfaceIndex < 0 then
  begin
    if fImplementationUses.IndexOf(pFilename) < 0 then
      fImplementationUses.Add(pFilename);
  end;
end;

function TDelphiUnit.RemoveImplementationUnit(const pFilename: string): Boolean;
var
  vInterfaceIndex : Integer;
begin
  Result := False;
  vInterfaceIndex := fInterfaceUses.IndexOf(pFilename);
  if vInterfaceIndex >= 0 then
  begin
    fInterfaceUses.Delete(vInterfaceIndex);
    Result := True;
  end;
end;

procedure TDelphiUnit.AddInterfaceVar(const pName: string; pTypeInfo: TUnitTypeDefinition);
begin
  fInterfaceVar.AddPair(pName, pTypeInfo.TypeName);
end;

procedure TDelphiUnit.AddInterfaceConstant(const pName, pValue: string);
begin
  fInterfaceConstant.AddPair(pName, pValue);
end;

procedure TDelphiUnit.AddInterfaceUnit(const pFilename: string);
var
  vInterfaceIndex : Integer;
begin
  vInterfaceIndex := fImplementationUses.IndexOf(pFilename);
  if vInterfaceIndex > 0 then
    fImplementationUses.Delete(vInterfaceIndex);

  if fInterfaceUses.IndexOf(pFilename) < 0 then
    fInterfaceUses.Add(pFilename);
end;

function TDelphiUnit.RemoveInterfaceUnit(const pFilename: string): Boolean;
var
  vInterfaceIndex : Integer;
begin
  Result := False;
  vInterfaceIndex := fImplementationUses.IndexOf(pFilename);
  if vInterfaceIndex >= 0 then
  begin
    fImplementationUses.Delete(vInterfaceIndex);
    Result := True;
  end;
end;

procedure TDelphiUnit.AddType(pTypeInfo: TUnitTypeDefinition);
begin
  if fTypeDefinitions.Count > 0 then
  begin
    if not Assigned(LookupTypeByName(pTypeInfo.TypeName)) then
      fTypeDefinitions.Add(pTypeInfo);
  end
  else
    fTypeDefinitions.Add(pTypeInfo);
end;

procedure TDelphiUnit.AddUnitMethod(pMethod: TUnitMethod);
begin
  if fUnitMethods.Count > 0 then
  begin
    if not Assigned(LookupUnitMethodByName(pMethod.Name)) then
      fUnitMethods.Add(pMethod);
  end
  else
    fUnitMethods.Add(pMethod);
end;

function TDelphiUnit.LookupUnitMethodByName(const pMethodName: string): TUnitMethod;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to fUnitMethods.Count - 1 do
  begin
    if fUnitMethods[i].Name = pMethodName then
    begin
      Result := fUnitMethods[i];
      Exit;
    end;
  end;
end;

function TDelphiUnit.LookupTypeByName(const pTypeName: string): TUnitTypeDefinition;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to fTypeDefinitions.Count - 1 do
  begin
    if fTypeDefinitions[i].TypeName = pTypeName then
    begin
      Result := fTypeDefinitions[i];
      Exit;
    end;
  end;
end;


constructor TDelphiUnit.Create;
begin
  fInterfaceUses := TStringList.Create;
  fInterfaceConstant := TStringList.Create;
  fInterfaceVar := TStringList.Create;
  fImplementationConstant := TStringList.Create;
  fImplementationUses := TStringList.Create;
  fTypeDefinitions := TObjectList<TUnitTypeDefinition>.Create(false);
  fUnitMethods := TObjectList<TUnitMethod>.Create(false);
end;

destructor TDelphiUnit.Destroy;
begin
  FreeAndNil(fInterfaceUses);
  FreeAndNil(fImplementationUses);
  FreeAndNil(fInterfaceConstant);
  FreeAndNil(fInterfaceVar);
  FreeAndNil(fImplementationConstant);
  FreeAndNil(fTypeDefinitions);
  inherited;
end;

function TDelphiUnit.GenerateImplementationConstants: string;
var
  vConstList : TStringList;
  vImpIndex : Integer;
begin
  vConstList := TStringList.Create;
  try
    if fImplementationConstant.Count > 0 then
    begin
      vConstList.Add('const');
      for vImpIndex := 0 to fImplementationConstant.Count - 1 do
      begin
        vConstList.Add('  ' + fImplementationConstant.Names[vImpIndex] + ' = ' + fImplementationConstant.ValueFromIndex[vImpIndex] + ';');
      end;
    end;
    Result := vConstList.Text;
  finally
    FreeAndNil(vConstList);
  end;
end;

function TDelphiUnit.GenerateInterfaceVar: string;
var
  vVarList : TStringList;
  vImpIndex : Integer;
begin
  vVarList := TStringList.Create;
  try
    if fInterfaceVar.Count > 0 then
    begin
      vVarList.Add('var');
      for vImpIndex := 0 to fInterfaceVar.Count - 1 do
      begin
        vVarList.Add('  ' + fInterfaceVar.Names[vImpIndex] + ' : ' + fInterfaceVar.ValueFromIndex[vImpIndex] + ';');
      end;
    end;
    Result := vVarList.Text;
  finally
    FreeAndNil(vVarList);
  end;
end;

function TDelphiUnit.GenerateImplementationSectionStart: string;
var
  vImplementationSection: TStringList;
begin
  vImplementationSection := TStringList.Create;
  try
    vImplementationSection.Add('');
    vImplementationSection.Add('implementation');
    vImplementationSection.Add('');
    Result := vImplementationSection.Text;
  finally
    FreeAndNil(vImplementationSection);
  end;
end;

function TDelphiUnit.GenerateImplementationUses: string;
var
  vUsesList: TStringList;
  vImplIndex: Integer;
begin
  vUsesList := TStringList.Create;
  try
    if fUnitHasResourceFile then
    vUsesList.Add('{$R *.dfm}');
    vUsesList.Add('');
    if fImplementationUses.Count > 0 then
    begin
      vUsesList.Add('uses');
      for vImplIndex := 0 to fImplementationUses.Count - 1 do
      begin
        if vImplIndex = 0 then
          vUsesList.Add('    ' + fImplementationUses[vImplIndex])
        else
          vUsesList.Add('  , ' + fImplementationUses[vImplIndex]);
      end;
      vUsesList.Add('  ;');
    end;
    vUsesList.Add('');
    Result := vUsesList.Text;
  finally
    FreeAndNil(vUsesList);
  end;
end;

function TDelphiUnit.GenerateInterfaceSectionStart: string;
var
  vInterfaceSectionList: TStringList;
begin
  vInterfaceSectionList := TStringList.Create;
  try
    vInterfaceSectionList.Add('unit ' + TPath.GetFileNameWithoutExtension(UnitFile) + ';');
    vInterfaceSectionList.Add('');
    vInterfaceSectionList.Add('interface');
    vInterfaceSectionList.Add('');
    Result := vInterfaceSectionList.Text;
  finally
    FreeAndNil(vInterfaceSectionList);
  end;
end;

function TDelphiUnit.GenerateInterfaceUses: string;
var
  vUsesList: TStringList;
  vUseIndex: Integer;
begin
  vUsesList := TStringList.Create;
  try
    if fInterfaceUses.Count > 0 then
    begin
      vUsesList.Add('uses');
      for vUseIndex := 0 to fInterfaceUses.Count - 1 do
      begin
        if vUseIndex = 0 then
          vUsesList.Add('    ' + fInterfaceUses[vUseIndex])
        else
          vUsesList.Add('  , ' + fInterfaceUses[vUseIndex]);
      end;
      vUsesList.Add('  ;');
    end;
    vUsesList.Add('');
    Result := vUsesList.Text;
  finally
    FreeAndNil(vUsesList);
  end;
end;

function TDelphiUnit.Generate: string;
var
  vIndex: Integer;
  vMethod: TUnitMethod;
  vUnitFileList: TStringList;
  vForwardAlreadyDeclared: Boolean;
begin
  vForwardAlreadyDeclared := False;
  vUnitFileList := TStringList.Create;
  try
    vUnitFileList.Add(GenerateInterfaceSectionStart);
    vUnitFileList.Add(GenerateInterfaceUses);
    vUnitFileList.Add('(*');
    vUnitFileList.Add('Title: ' + Title);
    vUnitFileList.Add('Description: ' + Description);
    vUnitFileList.Add('License: ' + License);
    vUnitFileList.Add('*)');
    vUnitFileList.Add('');
    vUnitFileList.Add('type');

    SortTypeDefinitions;

    for vIndex := 0 to fTypeDefinitions.Count - 1 do
    begin
      if fTypeDefinitions[vIndex].ForwardDeclare then
      begin
        if not vForwardAlreadyDeclared then
          vUnitFileList.Add('{ Forward Decls }');
        vUnitFileList.Add(fTypeDefinitions[vIndex].GenerateForwardInterface);
        vForwardAlreadyDeclared := True;
      end;
    end;

    vUnitFileList.Add('');
    vUnitFileList.Add('// Now the full declarations');

    for vIndex := 0 to fTypeDefinitions.Count - 1 do
    begin
      vUnitFileList.Add(fTypeDefinitions[vIndex].GenerateInterface);
    end;

    if fInterfaceConstant.Count > 0 then
    begin
      vUnitFileList.Add('const');
      for vIndex := 0 to fInterfaceConstant.Count - 1 do
      begin
        vUnitFileList.Add('  ' + fInterfaceConstant.Names[vIndex] + ' = ' + fInterfaceConstant.ValueFromIndex[vIndex] + ';');
      end;
    end;

    vUnitFileList.Add(GenerateInterfaceVar);
    vUnitFileList.Add('');
    vUnitFileList.Add('{ Global Functions }');
    vUnitFileList.Add('');
    for vIndex := 0 to fUnitMethods.Count - 1 do
    begin
      vUnitFileList.Add(fUnitMethods[vIndex].GenerateInterface(nil));
    end;


    vUnitFileList.Add(GenerateImplementationSectionStart);
    vUnitFileList.Add(GenerateImplementationUses);
    vUnitFileList.Add('');
    GenerateImplementationConstants;

    vUnitFileList.Add('');
    vUnitFileList.Add('{ Global Functions }');
    vUnitFileList.Add('');
    for vIndex := 0 to fUnitMethods.Count - 1 do
    begin
      vUnitFileList.Add(fUnitMethods[vIndex].GenerateImplementation(nil));
    end;

    for vIndex := 0 to fTypeDefinitions.Count - 1 do
    begin
      if fTypeDefinitions[vIndex].TypeKind = tkInterface then
        continue;

      vUnitFileList.Add('');
      vUnitFileList.Add('{ ' + fTypeDefinitions[vIndex].TypeName + ' }');
      vUnitFileList.Add('');
      for vMethod in fTypeDefinitions[vIndex].GetMethods do
      begin
        vUnitFileList.Add(vMethod.GenerateImplementation(fTypeDefinitions[vIndex]));
      end;
    end;
    vUnitFileList.Add('end.');
    Result := vUnitFileList.Text;
  finally
    FreeAndNil(vUnitFileList);
  end;
end;

function TDelphiUnit.CreateGUID: TGuid;
var
  vGuid: TGUID;
begin
  System.SysUtils.CreateGuid(vGuid);
  Result := vGuid;
end;

procedure TDelphiUnit.SaveToFile(const pFilename: string);
begin
  fUnitName := TPath.GetFileNameWithoutExtension(pFilename);
  TFile.WriteAllText(pFilename, Generate);
end;

procedure TDelphiUnit.SortTypeDefinitions;
var
  vList : TDelphiObjectList;
  vOrderedList : TObjectList<TUnitTypeDefinition>;
  vDefinitionIndex: Integer;
begin
  vList := TDelphiObjectList.Create;
  for vDefinitionIndex := 0 to fTypeDefinitions.Count - 1 do
  begin
    vList.AddType(fTypeDefinitions[vDefinitionIndex]);
  end;

  vOrderedList := TObjectList<TUnitTypeDefinition>.Create;
  vList.OrderedList(vOrderedList);
  fTypeDefinitions.Clear;

  for vDefinitionIndex := 0 to vOrderedList.Count - 1 do
  begin
    fTypeDefinitions.Add(vOrderedList[vDefinitionIndex]);
  end;
end;

{ TTypeDefinition }

procedure TUnitTypeDefinition.AddMethod(const pMethod: TUnitMethod);
var
  I : Integer;
  vMatched : Boolean;
  vMatchingMethod: TUnitMethod;
begin
  vMatched := False;
  for I := 0 to fMethods.Count - 1 do
  begin
    vMatchingMethod := fMethods[i];
    if (vMatchingMethod.Signature = pMethod.Signature) then
    begin
      vMatched := True;
      break;
    end;
  end;

  if (not vMatched) or (fMethods.Count = 0) then
  begin
    pMethod.ParentType := Self;
    fMethods.Add(pMethod);
  end;
end;

constructor TUnitTypeDefinition.Create;
begin
  fAttributes := TStringList.Create;
  fFields := TObjectList<TUnitFieldDefinition>.Create;
  fMethods := TObjectList<TUnitMethod>.Create;
  fProperties := TObjectList<TUnitPropertyDefinition>.Create;
  fTypeKind := tkClass;
  fForwardDeclare := False;
end;

destructor TUnitTypeDefinition.Destroy;
begin
  FreeAndNil(fAttributes);
  FreeAndNil(fFields);
  FreeAndNil(fProperties);
  FreeAndNil(fMethods);
  inherited;
end;

procedure TUnitTypeDefinition.AddAttribute(const pAttribute: string);
begin
  fAttributes.Add(pAttribute);
end;

function TUnitTypeDefinition.GenerateForwardInterface: string;
begin
  if fTypeKind = tkClass then
    Result := '  ' + TypeName + ' = class;'
  else if fTypeKind = tkRecord then
    raise Exception.Create('Records can not be forward declared')
  else if fTypeKind = tkInterface then
    Result := '  ' + TypeName + ' = interface;'
  else
    Result := '  ' + TypeName + 'xxxx';
end;

function TUnitTypeDefinition.GenerateInterface: string;
var
  vInterfaceList: TStringList;
  vAttributeIndex: Integer;
  vFieldIndex: Integer;
begin
  vInterfaceList := TStringList.Create;
  try
    if Assigned(fAttributes) then
    begin
      for vAttributeIndex := 0 to fAttributes.Count - 1 do
      begin
        vInterfaceList.Add(fAttributes[vAttributeIndex]);
      end;
    end;
    if fTypeKind = tkClass then
    begin
      if TypeInherited.Length > 0 then
        vInterfaceList.Add('  ' + TypeName + ' = class(' + TypeInherited + ')')
      else
        vInterfaceList.Add('  ' + TypeName + ' = class');
    end
    else if fTypeKind = tkRecord then
    begin
      vInterfaceList.Add('  ' + TypeName + ' = record');
    end
    else if fTypeKind = tkInterface then
    begin
      if TypeInherited.Length > 0 then
      begin
        vInterfaceList.Add('  ' + TypeName + ' = interface(' + TypeInherited + ')');
        vInterfaceList.Add('    [' + GUIDToString(fGuid).QuotedString + ']');
      end
      else
      begin
        vInterfaceList.Add('  ' + TypeName + ' = interface');
        vInterfaceList.Add('    [' + GUIDToString(fGuid).QuotedString + ']');
      end;
    end;

    for vFieldIndex := 0 to fFields.Count - 1 do
    begin
      vInterfaceList.Add(TrimRight(fFields[vFieldIndex].GenerateInterface(Self)));
    end;

    for vFieldIndex := 0 to fMethods.Count - 1 do
    begin
      vInterfaceList.Add(TrimRight(fMethods[vFieldIndex].GenerateInterface(Self)));
    end;

    for vFieldIndex := 0 to fProperties.Count - 1 do
    begin
      vInterfaceList.Add(TrimRight(fProperties[vFieldIndex].GenerateInterface(Self)));
    end;

    vInterfaceList.Add('  end;');

    Result := vInterfaceList.Text;
  finally
    FreeAndNil(vInterfaceList);
  end;
end;

function TUnitTypeDefinition.GetMethods: TArray<TUnitMethod>;
var
  vMethodIndex: Integer;
begin
  SetLength(Result, fMethods.Count);
  for vMethodIndex := 0 to fMethods.Count - 1 do
  begin
    Result[vMethodIndex] := fMethods[vMethodIndex];
  end;
end;

function TUnitTypeDefinition.GetMethodsByName(const pMethodName: string): TArray<TUnitMethod>;
var
  vMethodIndex : Integer;
  idx : Integer;
begin
  Result := nil;
  idx := 0;
  for vMethodIndex := 0 to fMethods.Count - 1 do
  begin
    if fMethods[vMethodIndex].Name = pMethodName then
    begin
      SetLength(Result, idx + 1);
      Result[idx] := fMethods[vMethodIndex];
      Inc(idx);
    end;
  end;
end;

function TUnitTypeDefinition.LookupPropertyByName(const pTypeName: string): TUnitPropertyDefinition;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to fProperties.Count - 1 do
  begin
    if fProperties[i].PropertyName = pTypeName then
    begin
      Result := fProperties[i];
      Exit;
    end;
  end;
end;

{ TFieldDefinition }

constructor TUnitFieldDefinition.Create;
begin
  fAttributes := TStringList.Create;
end;

destructor TUnitFieldDefinition.Destroy;
begin
  FreeAndNil(fAttributes);
  inherited Destroy;
end;

procedure TUnitFieldDefinition.AddAttribute(const pAttribute: string);
begin
  fAttributes.Add(pAttribute);
end;

function TUnitFieldDefinition.GenerateInterface(pOnType: TUnitTypeDefinition): string;
var
  vAttributeIndex: Integer;
  vInterfaceList: TStringList;
  vType: string;
begin
  vInterfaceList := TStringList.Create;
  try
    if (pOnType.TypeKind = tkClass) and  (pOnType.fCurrentVisibility <> Visibility) then
    begin
      pOnType.fCurrentVisibility := Visibility;
      vInterfaceList.Add('  ' + MemberVisibilityToString(Visibility));
    end;

    vType := fFieldType;
    for vAttributeIndex := 0 to fAttributes.Count - 1 do
    begin
      vInterfaceList.Add('    ' + fAttributes[vAttributeIndex]);
    end;

    if Description.Length > 0 then
      vInterfaceList.Add('    [MVCDoc(' + SafeDescription(Description) + ')]');

    vInterfaceList.Add('    ' + DelphiVarName(fFieldName) + ' : ' + vType + ';');
    Result := vInterfaceList.Text;
  finally
    FreeAndNil(vInterfaceList);
  end;
end;

function TUnitFieldDefinition.IsSimpleType: Boolean;
begin
  Result := MatchText(FieldType, ['String', 'Boolean', 'Integer', 'LongInt', 'Int64', 'Single', 'Double', 'Float32', 'Float64']);
end;

{ TUnitMethod }

constructor TUnitMethod.Create;
begin
  fParams := TObjectList<TUnitParameter>.Create;
  fAttributes := TStringList.Create;
  fVars := TObjectList<TUnitParameter>.Create;
  fContent := TStringList.Create;
end;

destructor TUnitMethod.Destroy;
begin
  FreeAndNil(fParams);
  FreeAndNil(fAttributes);
  FreeAndNil(fVars);
  FreeAndNil(fContent);
  inherited Destroy;
end;

procedure TUnitMethod.AddAttribute(const pAttribute: string);
begin
  fAttributes.Add(pAttribute);
end;

procedure TUnitMethod.AddLocalVariable(pVar: TUnitParameter);
begin
  fVars.Add(pVar);
end;

procedure TUnitMethod.AddParameter(pParam: TUnitParameter);
begin
  fParams.Add(pParam);
end;

procedure TUnitMethod.MethodLocalVarsToDelphiString(pFuncSL: TStringList);
var
  vVarIndex: Integer;
begin
  if fVars.Count <= 0 then
    Exit;

  pFuncSL.Add('var');
  for vVarIndex := 0 to fVars.Count - 1 do
  begin
    pFuncSL.Add('  ' + fVars[vVarIndex].ParamName + ' : ' + fVars[vVarIndex].ParamType.TypeName + ';');
  end;
end;

procedure TUnitMethod.ParametersToDelphiString(var pParamString: string; pIncludeAttributes: Boolean);
var
  vParam: TUnitParameter;
  vParamFlagString: string;
  vParamName: string;
  vParamAttributeString : string;
  vAttributeIndex: Integer;
begin
  pParamString := '(';
  for vParam in GetParameters do
  begin
    vParamFlagString := '';
    if pfConst in vParam.Flags then
      vParamFlagString := 'const'
    else if pfVar in vParam.Flags then
      vParamFlagString := 'var'
    else if pfOut in vParam.Flags then
      vParamFlagString := 'out'
    else if pfArray in vParam.Flags then
      vParamFlagString := 'array of';
    if vParamFlagString.Length > 0 then
      vParamFlagString := vParamFlagString + ' ';

    if pIncludeAttributes then
    begin
      for vAttributeIndex := 0 to vParam.Attributes.Count - 1 do
      begin
        vParamAttributeString := vParamAttributeString + ' ' + vParam.Attributes[vAttributeIndex];
      end;

      vParamAttributeString := Trim(vParamAttributeString) + ' ';
      if(vParamAttributeString = ' ') then
        vParamAttributeString := '';
    end;

    vParamName := DelphiVarName(vParam.ParamName);
    pParamString := pParamString + vParamAttributeString + vParamFlagString + vParamName + ': ' + vParam.ParamType.TypeName + '; ';
  end;
  if pParamString.EndsWith('; ') then
    pParamString := pParamString.Remove(pParamString.Length - 2);
  pParamString := pParamString + ')';
  if pParamString = '()' then
    pParamString := '';
end;

function TUnitMethod.ParametersToDelphiSignature: string;
var
  vParam: TUnitParameter;
  vParamFlagString: string;
  vParamString: string;
begin
  vParamString := '(';
  for vParam in GetParameters do
  begin
    vParamFlagString := '';
    if pfConst in vParam.Flags then
      vParamFlagString := 'const'
    else if pfVar in vParam.Flags then
      vParamFlagString := 'var'
    else if pfOut in vParam.Flags then
      vParamFlagString := 'out'
    else if pfArray in vParam.Flags then
      vParamFlagString := 'array of';
    if vParamFlagString.Length > 0 then
      vParamFlagString := vParamFlagString + ' ';

    vParamString := vParamString + vParamFlagString + ': ' + vParam.ParamType.TypeName + '; ';
  end;
  if vParamString.EndsWith('; ') then
    vParamString := vParamString.Remove(vParamString.Length - 2);
  vParamString := vParamString + ')';
  if vParamString = '()' then
    vParamString := '';

  Result := vParamString;
end;

function TUnitMethod.Signature: string;
var
  vHasReturn : Boolean;
begin
  Result := MethodKindToDelphiString(vHasReturn) + Name;
  Result := Result + ParametersToDelphiSignature;
  Result := Result.ToLower;  // Delphi is case insensitive
end;

function TUnitMethod.MethodKindToDelphiString(var pHasReturn: Boolean): string;
begin
  pHasReturn := False;

  case MethodKind of
    mkProcedure:
      Result := 'procedure';
    mkFunction:
      begin
        Result := 'function';
        pHasReturn := True;
      end;
    mkDestructor:
      Result := 'destructor';
    mkConstructor:
      Result := 'constructor';
    mkClassFunction:
      begin
        Result := 'class function';
        pHasReturn := True;
      end;
    mkClassProcedure:
      Result := 'class procedure';
    mkClassConstructor:
      Result := 'class constructor';
    mkClassDestructor:
      Result := 'class destructor';
  else
    Result := 'unknown';
  end;
end;

function TUnitMethod.GenerateImplementation(pOnType: TUnitTypeDefinition): string;
var
  vProcTypeString: string;
  vHasReturn: Boolean;
  vParamString: string;
  vClassNameProcIn: string;
  vFunctionList: TStringList;
begin
  vHasReturn := False;
  vClassNameProcIn := '';
  vProcTypeString := MethodKindToDelphiString(vHasReturn);

  if Assigned(pOnType) then
    vClassNameProcIn := pOnType.TypeName + '.';
  ParametersToDelphiString(vParamString, False);

  if vHasReturn then
    Result := vProcTypeString + ' ' + vClassNameProcIn + fName + vParamString + ': ' + ReturnType.TypeName + ';'
  else
    Result := vProcTypeString + ' ' + vClassNameProcIn + fName + vParamString + ';';

  vFunctionList := TStringList.Create;
  try
    vFunctionList.Text := Result;

    MethodLocalVarsToDelphiString(vFunctionList);

    vFunctionList.Add('begin');
    vFunctionList.AddStrings(Content);
    vFunctionList.Add('end;');

    Result := vFunctionList.Text;
  finally
    FreeAndNil(vFunctionList);
  end;
end;

function TUnitMethod.GenerateInterface(pOnType: TUnitTypeDefinition): string;
var
  vProcTypeString: string;
  vHasReturn: Boolean;
  vParamString: string;
  vAttributeString: string;
  vVisibility : string;
  vLeftPadding : string;
begin
  vHasReturn := False;
  vProcTypeString := MethodKindToDelphiString(vHasReturn);

  vLeftPadding := '    ';
  if not Assigned(pOnType) then
    vLeftPadding := '  ';

  ParametersToDelphiString(vParamString, True);

  if vHasReturn then
    Result := vLeftPadding + vProcTypeString + ' ' + fName + vParamString + ': ' + ReturnType.TypeName + ';'
  else
    Result := vLeftPadding + vProcTypeString + ' ' + fName + vParamString + ';';

  if IsOverrideMethod then
  begin
    if (Assigned(fParentType) and (fParentType.TypeKind <> tkInterface)) or not Assigned(fParentType) then
      Result := Result + ' override;';
  end;

  vAttributeString := fAttributes.Text;

  if Assigned(pOnType) and (pOnType.TypeKind = tkClass) and (pOnType.fCurrentVisibility <> Visibility) then
  begin
    vVisibility := '  ' + MemberVisibilityToString(Visibility) + System.sLineBreak;
    pOnType.fCurrentVisibility := Visibility;
  end;

  Result := vVisibility  + vAttributeString + Result;
end;

function TUnitMethod.GetIsConstructor: Boolean;
begin
  Result := MethodKind = mkConstructor;
end;

function TUnitMethod.GetIsDestructor: Boolean;
begin
  Result := MethodKind = mkDestructor;
end;

function TUnitMethod.GetParameters: TArray<TUnitParameter>;
var
  vParam: Integer;
begin
  SetLength(Result, fParams.Count);
  for vParam := 0 to fParams.Count - 1 do
  begin
    Result[vParam] := fParams[vParam];
  end;
end;

{ TUnitParameter }

constructor TUnitParameter.Create;
begin
  fAttributes := TStringList.Create;
end;

destructor TUnitParameter.Destroy;
begin
  FreeAndNil(fAttributes);
  FreeAndNil(fType);
  inherited Destroy;
end;

procedure TUnitParameter.AddAttribute(const pAttribute: string);
begin
  fAttributes.Add(pAttribute);
end;

{ TDelphiObjectList }

procedure TDelphiObjectList.AddType(pType: TUnitTypeDefinition);
var
  vNode : TDelphiObjectNode;
begin
   vNode := TDelphiObjectNode.Create(pType);
   fListOfTypes.Add(vNode);
end;

constructor TDelphiObjectList.Create;
begin
  fListOfTypes := TObjectList<TDelphiObjectNode>.Create;
end;

destructor TDelphiObjectList.Destroy;
begin
  FreeAndNil(fListOfTypes);
  inherited;
end;

function TDelphiObjectList.FindNode(const pTypeName: string): TDelphiObjectNode;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to fListOfTypes.Count-1 do
  begin
    OutputDebugString(PChar(fListOfTypes[i].FContainedObject.TypeName));
    if (CompareText(pTypeName,fListOfTypes[i].FContainedObject.TypeName)=0) then
    begin
      Result := fListOfTypes[i];
      Exit;
    end;
  end;
end;

procedure TDelphiObjectList.OrderedList(pList: TObjectList<TUnitTypeDefinition>);
var
  l, x, i : Integer;
  vTypeName : string;
  vRoot : TDelphiObjectNode;
  vNode : TDelphiObjectNode;
  vParam : TUnitParameter;
  vNodeObjList : TObjectList<TDelphiObjectNode>;
  vOrderedNodeObjList : TObjectList<TDelphiObjectNode>;
  vInheritTypes:  TArray<string>;
begin
  for l := 0 to fListOfTypes.Count - 1 do
  begin
    // Handle object / interfaces inherited from
    if Pos(',', fListOfTypes[l].FContainedObject.TypeInherited) < 0 then
    begin
      if fListOfTypes[l].FContainedObject.TypeInherited.Length > 0 then
      begin
        vNode := FindNode(fListOfTypes[l].FContainedObject.TypeInherited.Trim);
        if Assigned(vNode) then
          fListOfTypes[l].AddEdge(vNode);
      end;
    end
    else
    begin
      vInheritTypes := fListOfTypes[l].FContainedObject.TypeInherited.Split([',']);
      for x := 0 to Length(vInheritTypes) - 1 do
      begin
        vNode := FindNode(vInheritTypes[x].Trim);
        if Assigned(vNode) then
          fListOfTypes[l].AddEdge(vNode);
      end;
    end;

    // Handle Field Types used
    for x := 0 to fListOfTypes[l].FContainedObject.Fields.Count - 1 do
    begin
      vTypeName := fListOfTypes[l].FContainedObject.Fields[x].FieldType;
      if vTypeName.StartsWith('array of ') then
        vTypeName := Copy(vTypeName , 10);
      if not fListOfTypes[l].FContainedObject.Fields[x].IsSimpleType then
      begin
        vNode := findNode(vTypeName);
        if Assigned(vNode) then
          fListOfTypes[l].AddEdge(vNode);
      end;
    end;
    // Handle Types used in methods of class
    for x := 0 to fListOfTypes[l].fContainedObject.Methods.Count - 1 do
    begin
      for vParam in fListOfTypes[l].fContainedObject.Methods[x].GetParameters do
      begin
        vTypeName := vParam.ParamType.TypeName;
        if vTypeName.StartsWith('array of ') then
          vTypeName := Copy(vTypeName , 10);
        vNode := FindNode(vTypeName);
        if Assigned(vNode) then
          fListOfTypes[l].AddEdge(vNode);
      end;
      // Handle Return Type from function
      if (fListOfTypes[l].fContainedObject.Methods[x].MethodKind = mkFunction) or
         (fListOfTypes[l].fContainedObject.Methods[x].MethodKind = mkClassFunction) or
         (fListOfTypes[l].fContainedObject.Methods[x].MethodKind = mkSafeFunction) then
      begin
        vTypeName := fListOfTypes[l].fContainedObject.Methods[x].ReturnType.TypeName;
        if vTypeName.StartsWith('array of ') then
          vTypeName := Copy(vTypeName , 10);
        vNode := FindNode(vTypeName);
        if Assigned(vNode) then
          fListOfTypes[l].AddEdge(vNode);
      end;
    end;
  end;

  pList.Clear;
  vNodeObjList := nil;
  vOrderedNodeObjList := nil;
  vRoot := nil;
  try
    vNodeObjList := TObjectList<TDelphiObjectNode>.Create(TDelphiObjectNodeComparer.Create);
    vOrderedNodeObjList := TObjectList<TDelphiObjectNode>.Create(False);
    for i := 0 to fListOfTypes.Count - 1 do
    begin
      vNodeObjList.Add(fListOfTypes[i])
    end;

    vNodeObjList.Sort;

    for i := 0 to vNodeObjList.Count - 1 do
    begin
      if(vNodeObjList[i].FParents.Count = 0) then
      begin
        vRoot := vNodeObjList[i];
        vRoot.DependencyResolve(vOrderedNodeObjList, vRoot);
      end;
    end;

    for i := 0 to vOrderedNodeObjList.Count - 1 do
    begin
      pList.Add(vOrderedNodeObjList[i].FContainedObject);
    end;
  finally
    FreeAndNil(vNodeObjList);
    FreeAndNil(vOrderedNodeObjList);
  end;
end;

{ TDelphiObjectNode }

procedure TDelphiObjectNode.AddEdge(pNode: TDelphiObjectNode);
begin
  FEdges.Add(pNode);
  pNode.FParents.Add(self);
end;

constructor TDelphiObjectNode.Create(pType: TUnitTypeDefinition);
begin
  FContainedObject := pType;
  FEdges := TObjectList<TDelphiObjectNode>.Create(false);
  FParents := TObjectList<TDelphiObjectNode>.Create(false);
end;

destructor TDelphiObjectNode.Destroy;
begin
  FreeAndNil(FEdges);
  FreeAndNil(FParents);
  inherited;
end;

procedure TDelphiObjectNode.DependencyResolve(pList: TObjectList<TDelphiObjectNode>; pNode: TDelphiObjectNode);
var
  i : Integer;
begin
  for i := 0 to pNode.FEdges.Count - 1 do
  begin
   if (pList.IndexOf(pNode) < 0) then
     begin
       DependencyResolve(pList, pNode.FEdges[i]);
     end;
  end;
  if (pList.IndexOf(pNode) < 0) then
    pList.Add(pNode);
end;

function TDelphiObjectNodeComparer.Compare(const Left, Right: TDelphiObjectNode): Integer;
begin
  Result := Right.FParents.Count - Left.FParents.Count;
end;

{ TUnitPropertyDefinition }

procedure TUnitPropertyDefinition.AddAttribute(const pAttribute: string);
begin
  fAttributes.Add(pAttribute);
end;

procedure TUnitPropertyDefinition.AddParameter(pParam: TUnitParameter);
begin
  fParams.Add(pParam);
end;

constructor TUnitPropertyDefinition.Create;
begin
  fAttributes := TStringList.Create;
  fParams := TObjectList<TUnitParameter>.Create;
end;

destructor TUnitPropertyDefinition.Destroy;
begin
  FreeAndNil(fAttributes);
  FreeAndNil(fParams);
  inherited;
end;




function TUnitPropertyDefinition.GenerateInterface(pOnType: TUnitTypeDefinition): string;
var
  vVisibility : string;
  i: Integer;
  paramStr: string;
begin
  if (pOnType.TypeKind = tkClass) and  (pOnType.fCurrentVisibility <> Visibility) then
  begin
    vVisibility := '  ' + MemberVisibilityToString(Visibility) + System.sLineBreak;
    pOnType.fCurrentVisibility := Visibility;
  end;

  for i := 0 to fParams.Count - 1 do
  begin
    if i > 0 then
      paramStr := paramStr + ', ';
    paramStr := fparams[i].ParamName + ': ' + fParams[i].ParamType.TypeName;
  end;
  if paramStr.Length > 0 then
    paramStr := '[' + paramStr + ']';
  Result := vVisibility + '    property ' + DelphiVarName(PropertyName) + paramStr + ':' + PropertyType;
  if PropertyRead.Length > 0 then
    Result := Result + ' read ' + PropertyRead;
  if PropertyWrite.Length > 0 then
    Result := Result + ' write ' + PropertyWrite;
  Result := Result + ';';
end;

function TUnitPropertyDefinition.IsSimpleType: Boolean;
begin
  Result := MatchText(PropertyType, ['String', 'Boolean', 'Integer', 'LongInt', 'Int64', 'Single', 'Double', 'Float32', 'Float64']);
end;

end.

