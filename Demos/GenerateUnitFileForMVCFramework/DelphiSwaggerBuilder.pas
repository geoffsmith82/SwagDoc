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

unit DelphiSwaggerBuilder;

interface

uses
  System.Classes,
  System.Json,
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Swag.Doc,
  Swag.Common.Types,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.Path.Operation.RequestParameter,
  Sample.DelphiUnit.Generate;

type
  TSwagDocToDelphiBuilderBase = class(TObject)
  private

  protected
    fSwagDoc: TSwagDoc;

    function CapitalizeFirstLetter(const pTypeName: string): string;
    function MakeDelphiSafeVariableName(const pName: string): string;
    function RewriteUriToSwaggerWay(const pUri: string): string;
    function OperationIdToFunctionName(pOperation: TSwagPathOperation; pUrl:string): string;
    function GenerateUnitText(pDelphiUnit: TDelphiUnit): string;
    function ConvertSwaggerRequestParameterTypeToDelphiType(pDelphiUnit : TDelphiUnit; pOperation: TSwagPathOperation; pSwaggerType: TSwagRequestParameter): TUnitTypeDefinition;
    function ConvertRefToExceptionType(const pRef: string): string;
    function ConvertRefToType(const pRef: string): string;
    function ConvertRefToVarName(const pRef: string): string;
    function LookupParamRef(pRef: string): TSwagRequestParameter;

    procedure ChildType(pDelphiUnit: TDelphiUnit; pJson: TJSONPair);
    procedure HandleArray(pDelphiUnit : TDelphiUnit; pField : TUnitFieldDefinition; pJson: TJSONPair);
    procedure ConvertSwaggerDefinitionsToTypeDefinitions(pDelphiUnit: TDelphiUnit);
  public
    constructor Create(pSwagDoc: TSwagDoc); reintroduce;
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.TypInfo,
  Json.Common.Helpers;

{ TSwagDocToDelphiMVCFrameworkBuilder }

constructor TSwagDocToDelphiBuilderBase.Create(pSwagDoc: TSwagDoc);
begin
  inherited Create;
  fSwagDoc := pSwagDoc;
end;

function TSwagDocToDelphiBuilderBase.OperationIdToFunctionName(pOperation: TSwagPathOperation; pUrl:string): string;
begin
  Result := pOperation.OperationId.Replace('{', '').Replace('}', '').Replace('-', '').Replace('/', '');
  if Result.Length = 0 then
  begin
    Result := pOperation.OperationToString + pUrl.Replace('/', '').Replace('{', '').Replace('}', '');
  end;
  if not CharInSet(Result[1], ['a'..'z', 'A'..'Z']) then
    Result := 'F' + Result;

  Result := CapitalizeFirstLetter(Result);
end;

function TSwagDocToDelphiBuilderBase.RewriteUriToSwaggerWay(const pUri: string): string;
begin
  Result := pUri.Replace('{', '($').Replace('}', ')');
end;

function TSwagDocToDelphiBuilderBase.CapitalizeFirstLetter(const pTypeName: string): string;
begin
  if pTypeName.Length > 2 then
    Result := Copy(pTypeName, 1, 1).ToUpper + Copy(pTypeName, 2, pTypeName.Length - 1)
  else
    Result := pTypeName;
end;

function TSwagDocToDelphiBuilderBase.MakeDelphiSafeVariableName(const pName: string): string;
begin
  Result := pName.Replace('/', '').Replace('-', '').Replace('.', '')
end;

function TSwagDocToDelphiBuilderBase.ConvertRefToType(const pRef: string): string;
begin
  Result := pRef.Replace('/','').Replace('#','').Replace('.','');
  Result := Copy(Result, 1, 1).ToUpper + Copy(Result,2).Replace('-', '');
  if (Result.ToLower <> 'string') and (Result.ToLower <> 'integer') then
    Result := 'T' + Result;
end;

function TSwagDocToDelphiBuilderBase.ConvertRefToExceptionType(const pRef: string): string;
begin
  Result := pRef.Replace('/','').Replace('#','').Replace('.','');
  Result := Copy(Result, 1, 1).ToUpper + Copy(Result,2).Replace('-', '');
  if (Result.ToLower = 'string') or (Result.ToLower = 'integer') then
    raise Exception.Create('A simple type can not be an exception');
  Result := 'E' + Result;
end;

function TSwagDocToDelphiBuilderBase.ConvertRefToVarName(const pRef: string): string;
begin
  Result := Copy(pRef, pRef.LastIndexOf('/') + 2).Replace('-', '').Replace('.', '');
end;

function TSwagDocToDelphiBuilderBase.LookupParamRef(pRef: string): TSwagRequestParameter;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to fSwagDoc.Parameters.Count - 1 do
  begin
    if (pRef.Length > 0) and (fSwagDoc.Parameters[i].Ref = pRef) then
    begin
      Result := fSwagDoc.Parameters[i];
      OutputDebugString(PChar('ParamRef Found ' + pRef));
      break;
    end;
  end;
end;

procedure TSwagDocToDelphiBuilderBase.HandleArray(pDelphiUnit : TDelphiUnit; pField : TUnitFieldDefinition; pJson: TJSONPair);
var
  vJsonObj: TJSONObject;
  vJsonVal: TJSONValue;
  vJsonPair : TJSONPair;
  vType: string;
begin
  if Assigned(((pJson.JsonValue as TJSONObject).Values['items'] as TJSONObject).Values['type']) then
  begin
    vType := ((pJson.JsonValue as TJSONObject).Values['items'] as TJSONObject).Values['type'].Value;
    if (vType.ToLower <> 'string') and (vType.ToLower <> 'integer') then
      vType := 'T' + vType;
    pField.FieldType := 'array of ' + vType;
  end
  else
  begin
    OutputDebugString(PChar(pJson.ToJSON));
    vJsonVal := (pJson.JsonValue as TJSONObject).Values['items'] as TJSONObject;
    OutputDebugString(PChar(vJsonVal.ToJSON));
    vJsonObj := vJsonVal as TJSONObject;
    if Assigned(vJsonObj.Values['$ref']) then
    begin
      vJsonVal := vJsonObj.Values['$ref'];
      OutputDebugString(PChar(vJsonVal.Value));
      pField.FieldType := 'array of ' + ConvertRefToType(vJsonVal.value);
    end
    else
    begin
      vJsonPair := TJSONPair.Create('properties', vJsonVal);
      ChildType(pDelphiUnit, vJsonPair);
    end;
  end;
end;


procedure TSwagDocToDelphiBuilderBase.ChildType(pDelphiUnit : TDelphiUnit; pJson: TJSONPair);
var
  vTypeInfo: TUnitTypeDefinition;
  vJsonProps: TJSONObject;
  vJsonArray: TJSONObject;
  vJsonType: TJSONValue;
  vFieldInfo: TUnitFieldDefinition;
  vTypeObj: TJSONObject;
  vJsonPropIndex: Integer;
  vValue : string;
  vArrayPair : TJSONPair;
begin
  OutputDebugString(PChar('Child: ' + pJson.ToJSON));
  vTypeInfo := TUnitTypeDefinition.Create;
  vTypeInfo.TypeName := 'TInline' + CapitalizeFirstLetter(pJson.JSONString.Value);

  vJsonProps := (pJson.JSONValue as TJSONObject).Values['properties'] as TJSONObject;
  vJsonArray := (pJson.JSONValue as TJSONObject).Values['items'] as TJSONObject;
  vJsonType := (pJson.JSONValue as TJSONObject).Values['type'];
  if Assigned(vJsonProps) then
  begin
    for vJsonPropIndex := 0 to vJsonProps.Count - 1 do
    begin
      OutputDebugString(PChar(vJsonProps.Pairs[vJsonPropIndex].ToJSON));
      vFieldInfo := TUnitFieldDefinition.Create;
      vFieldInfo.FieldName := MakeDelphiSafeVariableName(vJsonProps.Pairs[vJsonPropIndex].JsonString.Value);
      vTypeObj := vJsonProps.Pairs[vJsonPropIndex].JsonValue as TJSONObject;
      vFieldInfo.FieldType := vTypeObj.Values['type'].Value;
      if vFieldInfo.FieldType = 'number' then
        vFieldInfo.FieldType := 'Double'
      else if vFieldInfo.FieldType = 'object' then
      begin
        vFieldInfo.FieldType := 'T' + CapitalizeFirstLetter(vJsonProps.Pairs[vJsonPropIndex].JsonString.Value);
        ChildType(pDelphiUnit, vJsonProps.Pairs[vJsonPropIndex]);
      end;
      if vTypeObj.TryGetValue('description', vValue) then
        vFieldInfo.AddAttribute('[MVCDoc(' + QuotedStr(vValue) + ')]');

      if vTypeObj.TryGetValue('format', vValue) then
      begin
        if (vFieldInfo.FieldType.ToLower = 'integer') and (vValue.ToLower = 'int64') then
          vFieldInfo.FieldType := 'Int64';
        vFieldInfo.AddAttribute('[MVCFormat(' + QuotedStr(vValue) + ')]');
      end;
      if vTypeObj.TryGetValue('maxLength', vValue) then
        vFieldInfo.AddAttribute('[MVCMaxLength(' + vValue + ')]');
      vTypeInfo.Fields.Add(vFieldInfo);
    end;
  end
  else if Assigned(vJsonArray) and Assigned(vJsonType) then
  begin
    vArrayPair := TJSONPair.Create('properties', vJsonArray.Values['properties']);
    ChildType(pDelphiUnit, vArrayPair);
  end;

  pDelphiUnit.AddType(vTypeInfo);
end;

procedure TSwagDocToDelphiBuilderBase.ConvertSwaggerDefinitionsToTypeDefinitions(pDelphiUnit: TDelphiUnit);
var
  vTypeInfo: TUnitTypeDefinition;
  vJsonProps: TJSONObject;
  vFieldInfo: TUnitFieldDefinition;
  vTypeObj: TJSONObject;
  DefinitionIndex: Integer;
  vJsonPropIndex: Integer;
  vValue : string;
begin
  for DefinitionIndex := 0 to fSwagDoc.Definitions.Count - 1 do
  begin
    vTypeInfo := TUnitTypeDefinition.Create;
    vTypeInfo.TypeName := 'TDefinitions' + CapitalizeFirstLetter(fSwagDoc.Definitions[DefinitionIndex].Name).Replace('-', '').Replace('.','').Replace('[','').Replace(']','');

    vJsonProps := fSwagDoc.Definitions[DefinitionIndex].JsonSchema.Values['properties'] as TJSONObject;
    if not Assigned(vJsonProps) then
      continue;
    for vJsonPropIndex := 0 to vJsonProps.Count - 1 do
    begin
      OutputDebugString(PChar(vJsonProps.Pairs[vJsonPropIndex].ToJSON));
      vFieldInfo := TUnitFieldDefinition.Create;
      vFieldInfo.FieldName := MakeDelphiSafeVariableName(vJsonProps.Pairs[vJsonPropIndex].JsonString.Value);
      if vFieldInfo.FieldName <> vJsonProps.Pairs[vJsonPropIndex].JsonString.Value then
        vFieldInfo.AddAttribute('[MVCNameAs(' + vJsonProps.Pairs[vJsonPropIndex].JsonString.Value.QuotedString + ')');

      vTypeObj := vJsonProps.Pairs[vJsonPropIndex].JsonValue as TJSONObject;
      if Assigned(vTypeObj.Values['type']) then
        vFieldInfo.FieldType := vTypeObj.Values['type'].Value
      else if Assigned(vTypeObj.Values['$ref']) then
        vFieldInfo.FieldType := ConvertRefToType(vTypeObj.Values['$ref'].Value)
      else
        vFieldInfo.FieldType := 'String';

      if vFieldInfo.FieldType = 'number' then
        vFieldInfo.FieldType := 'Double'
      else if vFieldInfo.FieldType = 'object' then
      begin
        vFieldInfo.FieldType := 'T' + CapitalizeFirstLetter(vJsonProps.Pairs[vJsonPropIndex].JsonString.Value);
        ChildType(pDelphiUnit, vJsonProps.Pairs[vJsonPropIndex]);
      end
      else if vFieldInfo.FieldType = 'array' then
      begin
        HandleArray(pDelphiUnit, vFieldInfo, vJsonProps.Pairs[vJsonPropIndex]);
      end;
      if vTypeObj.TryGetValue('description', vValue) then
      begin
        if vValue.Trim.Length > 0 then
          vFieldInfo.AddAttribute('[MVCDoc(' + SafeDescription(vValue) + ')]');
      end;
      if vTypeObj.TryGetValue('format', vValue) then
      begin
        if (vFieldInfo.FieldType.ToLower = 'integer') and (vValue.ToLower = 'int64') then
          vFieldInfo.FieldType := 'Int64';
        vFieldInfo.AddAttribute('[MVCFormat(' + QuotedStr(vValue) + ')]');
      end;
      if vTypeObj.TryGetValue('maxLength', vValue) then
        vFieldInfo.AddAttribute('[MVCMaxLength(' + vValue + ')]');
      if vTypeObj.TryGetValue('minimum', vValue) then
        vFieldInfo.AddAttribute('[MVCMinimum(' + vValue + ')]');
      if vTypeObj.TryGetValue('maximum', vValue) then
        vFieldInfo.AddAttribute('[MVCMaximum(' + vValue + ')]');
      vTypeInfo.Fields.Add(vFieldInfo);
    end;
    pDelphiUnit.AddType(vTypeInfo);
  end;
end;

function TSwagDocToDelphiBuilderBase.ConvertSwaggerRequestParameterTypeToDelphiType(pDelphiUnit : TDelphiUnit; pOperation: TSwagPathOperation; pSwaggerType: TSwagRequestParameter): TUnitTypeDefinition;
var
  vSwaggerType: TSwagTypeParameter;
  vJson: TJSONObject;
  vJsonPair : TJSONPair;
begin
  Result := TUnitTypeDefinition.Create;
  vSwaggerType := pSwaggerType.TypeParameter;
  case vSwaggerType of
    stpNotDefined:
    begin
      if Assigned(pSwaggerType.Schema.JsonSchema) then
      begin
        if Assigned(pSwaggerType.Schema.JsonSchema.Values['$ref']) then
          Result.TypeName := ConvertRefToType(pSwaggerType.Schema.JsonSchema.Values['$ref'].Value)
        else
        begin
          Result.TypeName := pSwaggerType.Schema.JsonSchema.Values['type'].Value;
          if Result.TypeName = 'array' then
          begin
            if Assigned(pSwaggerType.Schema.JsonSchema.Values['items']) then
              if Assigned((pSwaggerType.Schema.JsonSchema.Values['items'] as TJSONObject).Values['$ref']) then
                Result.TypeName := 'array of ' + ConvertRefToType((pSwaggerType.Schema.JsonSchema.Values['items'] as TJSONObject).Values['$ref'].Value)
            else if Assigned((pSwaggerType.Schema.JsonSchema.Values['items'] as TJSONObject).Values['type']) then  // fixes missing array types
              Result.TypeName := 'array of ' + (pSwaggerType.Schema.JsonSchema.Values['items'] as TJSONObject).Values['type'].Value
          end
          else if Result.TypeName = 'object' then
          begin
            OutputDebugString(PChar(pSwaggerType.Schema.Name));
            OutputDebugString(PChar(pSwaggerType.Schema.JsonSchema.ToJSON));
            vJsonPair := TJSONPair.Create('properties', pSwaggerType.Schema.JsonSchema.Values['properties']);
            ChildType(pDelphiUnit, vJsonPair);
            Result.TypeName := 'TInline' + CapitalizeFirstLetter(pSwaggerType.Schema.Name);
//            OutputDebugString(PChar(pSwaggerType.Schema.));
//            raise Exception.Create('Error Message');
//            OperationIdToFunctionName(pOperation.OperationId, pOperation.)

//            Result := Result;
          end;
        end;
      end;
    end;
    stpString: Result.TypeName := 'String';
    stpNumber: Result.TypeName := 'Double';
    stpInteger: Result.TypeName := 'Integer';
    stpBoolean: Result.TypeName := 'Boolean';
    stpArray:
    begin
      vJson := pSwaggerType.Schema.JsonSchema;
      if Assigned(vJson) then
      begin
        OutputDebugString(PChar('TYPE: ' + vJson.ToJson));
        Result.TypeName := 'array of ' + pSwaggerType.Schema.JsonSchema.Values['type'].Value;
      end
      else
      begin
        if Assigned(pSwaggerType.Items) then
        begin
          if Assigned(pSwaggerType.Items.Values['type']) then
          begin
            Result.TypeName := 'array of ' + pSwaggerType.Items.Values['type'].Value;
          end
          else
            Result.TypeName := 'array of ';
        end;
      end;
    end;
    stpFile: Result.TypeName := 'err File';
  end;
end;

function TSwagDocToDelphiBuilderBase.GenerateUnitText(pDelphiUnit: TDelphiUnit): string;
begin
  pDelphiUnit.Title := fSwagDoc.Info.Title;
  pDelphiUnit.Description := fSwagDoc.Info.Description;
  pDelphiUnit.License := fSwagDoc.Info.License.Name;
  Result := pDelphiUnit.Generate;
end;

end.
