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

unit Sample.MvcControllerClientFileBuilder;

interface

uses
  System.Classes,
  System.Json,
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Swag.Doc,
  Swag.Common.Types,
  Swag.Doc.Path.Operation,
  Swag.Doc.Path.Operation.Response,
  Swag.Doc.Path.Operation.RequestParameter,
  Sample.DelphiUnit.Generate;

type
  TSwagDocToDelphiMVCControllerBuilder = class(TObject)
  strict private
    fSwagDoc: TSwagDoc;

    function CapitalizeFirstLetter(const pTypeName: string): string;
    function RewriteUriToSwaggerWay(const pUri: string): string;
    function OperationIdToFunctionName(pOperation: TSwagPathOperation): string;
    function RewriteUriToDelphiMVCFrameworkWay(const pUri: string): string;
    function GenerateUnitText(pDelphiUnit: TDelphiUnit): string;
    function ConvertSwaggerTypeToDelphiType(pSwaggerType: TSwagRequestParameter): TUnitTypeDefinition;
    function ConvertRefToExceptionType(const pRef: string): string;	
    function ConvertRefToType(const pRef: string): string;
    function ConvertRefToVarName(const pRef: string): string;
    function MakeDelphiSafeVariableName(const pName: string): string;

    procedure ChildType(pDelphiUnit: TDelphiUnit; pJson: TJSONPair);
    procedure HandleArray(pField: TUnitFieldDefinition; pJson: TJSONPair);
    procedure ConvertSwaggerDefinitionsToTypeDefinitions(pDelphiUnit: TDelphiUnit);
  public
    constructor Create(pSwagDoc: TSwagDoc); reintroduce;
    function Generate: string;
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.TypInfo,
  Json.Common.Helpers;

{ TSwagDocToDelphiMVCFrameworkBuilder }

constructor TSwagDocToDelphiMVCControllerBuilder.Create(pSwagDoc: TSwagDoc);
begin
  inherited Create;
  fSwagDoc := pSwagDoc;
end;

function TSwagDocToDelphiMVCControllerBuilder.RewriteUriToDelphiMVCFrameworkWay(const pUri: string): string;
begin
  Result := pUri.Replace('{','($').Replace('}',')');
end;

function TSwagDocToDelphiMVCControllerBuilder.OperationIdToFunctionName(pOperation: TSwagPathOperation): string;
begin
  Result := pOperation.OperationId.Replace('{','').Replace('}','').Replace('-','');
  if not CharInSet(Result[1], ['a'..'z','A'..'Z']) then
    Result := 'F' + Result;

  Result := CapitalizeFirstLetter(Result);
end;

function TSwagDocToDelphiMVCControllerBuilder.RewriteUriToSwaggerWay(const pUri: string): string;
begin
  Result := pUri.Replace('{','($').Replace('}',')');
end;

function TSwagDocToDelphiMVCControllerBuilder.CapitalizeFirstLetter(const pTypeName: string): string;
begin
  if pTypeName.Length > 2 then
    Result := Copy(pTypeName, 1, 1).ToUpper + Copy(pTypeName, 2, pTypeName.Length - 1)
  else
    Result := pTypeName;
end;

function TSwagDocToDelphiMVCControllerBuilder.MakeDelphiSafeVariableName(const pName: string): string;
begin
  Result := pName.Replace('/', '').Replace('-', '').Replace('.', '')
end;


function TSwagDocToDelphiMVCControllerBuilder.ConvertRefToType(const pRef: string): string;
begin
  Result := pRef.Replace('/','').Replace('#','').Replace('.','');
  Result := Copy(Result, 1, 1).ToUpper + Copy(Result,2).Replace('-', '');
  if Result.ToLower <> 'string' then
    Result := 'T' + Result;
end;

function TSwagDocToDelphiMVCControllerBuilder.ConvertRefToExceptionType(const pRef: string): string;
begin
  Result := pRef.Replace('/','').Replace('#','').Replace('.','');
  Result := Copy(Result, 1, 1).ToUpper + Copy(Result,2).Replace('-', '');
  if (Result.ToLower = 'string') or (Result.ToLower = 'integer') then
    raise Exception.Create('A simple type can not be an exception');
  Result := 'E' + Result;
end;


function TSwagDocToDelphiMVCControllerBuilder.ConvertRefToVarName(const pRef: string): string;
begin
  Result := Copy(pRef, pRef.LastIndexOf('/') + 2);
end;

function TSwagDocToDelphiMVCControllerBuilder.Generate: string;
var
  vPathIndex: Integer;
  vOperationIndex: Integer;
  vParameterIndex: Integer;
  vDelphiUnit: TDelphiUnit;
  vMVCControllerClient: TUnitTypeDefinition;
  vExceptionsFromClient: TUnitTypeDefinition;
  vMethod: TUnitMethod;
  vParam : TUnitParameter;
  vResponse: TPair<string, TSwagResponse>;
  vSchemaObj: TJsonObject;
  vResultParam: TUnitParameter;
  vField: TUnitFieldDefinition;
  vRef: String;
  vStatusCode : Integer;
begin
  vDelphiUnit := TDelphiUnit.Create;
  try
    vDelphiUnit.UnitFile := 'UnitFilenameMvcControllerClient';
    vDelphiUnit.AddInterfaceUnit('MVCFramework');
    vDelphiUnit.AddInterfaceUnit('MVCFramework.Commons');
    vDelphiUnit.AddImplementationUnit('Swag.Doc');

    vMVCControllerClient := TUnitTypeDefinition.Create;
    vMVCControllerClient.TypeName := 'TMyMVCControllerClient';
    vMVCControllerClient.TypeInherited := 'TMVCController';
    vMVCControllerClient.AddAttribute('  [MVCPath(' + RewriteUriToDelphiMVCFrameworkWay(fSwagDoc.BasePath).QuotedString + ')]');

    vDelphiUnit.AddType(vMVCControllerClient);
    ConvertSwaggerDefinitionsToTypeDefinitions(vDelphiUnit);

    for vPathIndex := 0 to fSwagDoc.Paths.Count - 1 do
    begin
      for vOperationIndex := 0 to fSwagDoc.Paths[vPathIndex].Operations.Count - 1 do
      begin
        vMethod := TUnitMethod.Create;
        if fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Description.Trim.Length > 0 then
          vMethod.AddAttribute('    [MVCDoc(' + SafeDescription(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Description) + ')]');
        vMethod.AddAttribute('    [MVCPath(' + RewriteUriToDelphiMVCFrameworkWay(fSwagDoc.Paths[vPathIndex].Uri).QuotedString + ')]');
        vMethod.AddAttribute('    [MVCHTTPMethod([http' + fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].OperationToString.ToUpper + '])]');
        vMethod.Name := OperationIdToFunctionName(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex]);

        for vParameterIndex := 0 to fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters.Count - 1 do
        begin
          vResultParam := TUnitParameter.Create;
          vResultParam.ParamName := CapitalizeFirstLetter(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Name);
          vResultParam.ParamType := ConvertSwaggerTypeToDelphiType(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex]);
          vMethod.AddParameter(vResultParam);
        end;

        for vResponse in fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Responses do
        begin
          vSchemaObj := vResponse.Value.Schema.JsonSchema;
          if vSchemaObj = nil then
            continue;
          if vSchemaObj.TryGetValue('$ref', vRef) then
          begin
            vMethod.AddAttribute('    [MVCResponse(' + vResponse.Key + ', ' +
                                                   QuotedStr(vResponse.Value.Description) + ', ' + ConvertRefToType(vRef) + ')]');
            if TryStrToInt(vResponse.Key, vStatusCode) then
            begin
              if vStatusCode >= 300 then
              begin
                vExceptionsFromClient := TUnitTypeDefinition.Create;
                vExceptionsFromClient.TypeName := ConvertRefToExceptionType(vRef);
                vExceptionsFromClient.TypeInherited := 'Exception';
                vDelphiUnit.AddType(vExceptionsFromClient);
                vMethod.Content.Add('//  raise ' + vExceptionsFromClient.TypeName + '.Create(' + vStatusCode.ToString + ', ' + QuotedStr(vResponse.Value.Description) + ');');
              end
              else
              begin
                vResultParam := TUnitParameter.Create;
                vResultParam.ParamName := ConvertRefToVarName(vRef);
                vResultParam.ParamType := TUnitTypeDefinition.Create;
                vResultParam.ParamType.TypeName := ConvertRefToType(vRef);
                vMethod.AddLocalVariable(vResultParam);
                vMethod.Content.Add('  ' + ConvertRefToVarName(vRef) + ' := ' + ConvertRefToType(vRef) + '.Create;');
               for vParameterIndex := 0 to fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters.Count - 1 do
                begin
                  vMethod.Content.Add('  ' + MakeDelphiSafeVariableName(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Name) + ' := Params[' + fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Name.QuotedString + '];');
                end;
                vMethod.Content.Add('');
                vMethod.Content.Add('');
                vMethod.Content.Add('  Render(' + vResultParam.ParamName + ');');
              end;
            end;
          end
          else  // Swagger file is using an inline type definition for Response type
          begin
            if not vSchemaObj.TryGetValue('properties', vSchemaObj) then
              continue;
            if not vSchemaObj.TryGetValue('employees', vSchemaObj) then
              continue;
            if not vSchemaObj.TryGetValue('items', vSchemaObj) then
              continue;
            if vSchemaObj.TryGetValue('$ref', vRef) then
            begin
              vMethod.AddAttribute('    [MVCResponseList(' + vResponse.Key + ', ' +
                                                     QuotedStr(vResponse.Value.Description) + ', ' + ConvertRefToType(vRef) + ')]');
              vResultParam := TUnitParameter.Create;
              vResultParam.ParamName := ConvertRefToVarName(vRef);
              vResultParam.ParamType := TUnitTypeDefinition.Create;
              vResultParam.ParamType.TypeName := 'TObjectList<' + ConvertRefToType(vRef) + '>';
              vMethod.AddLocalVariable(vResultParam);
              vDelphiUnit.AddInterfaceUnit('Generics.Collections');
              vMethod.Content.Add('  ' + ConvertRefToVarName(vRef) + ' := TObjectList<' + ConvertRefToType(vRef) + '>.Create;');
            end;
          end;
        end;

        vMVCControllerClient.Methods.Add(vMethod);
      end;
    end;

    Result := GenerateUnitText(vDelphiUnit);
  finally
    vDelphiUnit.Free;
  end;
end;

procedure TSwagDocToDelphiMVCControllerBuilder.HandleArray(pField : TUnitFieldDefinition; pJson: TJSONPair);
var
  vJsonObj: TJSONObject;
  vJsonVal: TJSONValue;
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
    vJsonVal := vJsonObj.Values['$ref'];
    OutputDebugString(PChar(vJsonVal.Value));
    pField.FieldType := 'array of ' + ConvertRefToType(vJsonVal.value);
  end;
end;


procedure TSwagDocToDelphiMVCControllerBuilder.ChildType(pDelphiUnit : TDelphiUnit; pJson: TJSONPair);
var
  vTypeInfo: TUnitTypeDefinition;
  vJsonProps: TJSONObject;
  vFieldInfo: TUnitFieldDefinition;
  vTypeObj: TJSONObject;
  vJsonPropIndex: Integer;
  vValue : string;
begin
  OutputDebugString(PChar('Child: ' + pJson.ToJSON));
  vTypeInfo := TUnitTypeDefinition.Create;
  vTypeInfo.TypeName := 'T' + CapitalizeFirstLetter(pJson.JSONString.Value);

  vJsonProps := (pJson.JSONValue as TJSONObject).Values['properties'] as TJSONObject;
  for vJsonPropIndex := 0 to vJsonProps.Count - 1 do
  begin
    OutputDebugString(PChar(vJsonProps.Pairs[vJsonPropIndex].ToJSON));
    vFieldInfo := TUnitFieldDefinition.Create;
    vFieldInfo.FieldName := vJsonProps.Pairs[vJsonPropIndex].JsonString.Value;
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
  pDelphiUnit.AddType(vTypeInfo);
end;

procedure TSwagDocToDelphiMVCControllerBuilder.ConvertSwaggerDefinitionsToTypeDefinitions(pDelphiUnit: TDelphiUnit);
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
    vTypeInfo.TypeName := 'TDefinitions' + CapitalizeFirstLetter(fSwagDoc.Definitions[DefinitionIndex].Name);
    vJsonProps := fSwagDoc.Definitions[DefinitionIndex].JsonSchema.Values['properties'] as TJSONObject;
    for vJsonPropIndex := 0 to vJsonProps.Count - 1 do
    begin
      OutputDebugString(PChar(vJsonProps.Pairs[vJsonPropIndex].ToJSON));
      vFieldInfo := TUnitFieldDefinition.Create;
      vFieldInfo.FieldName := vJsonProps.Pairs[vJsonPropIndex].JsonString.Value;
      vTypeObj := vJsonProps.Pairs[vJsonPropIndex].JsonValue as TJSONObject;
      if Assigned(vTypeObj.Values['type']) then
        vFieldInfo.FieldType := vTypeObj.Values['type'].Value
      else
        vFieldInfo.FieldType := ConvertRefToType(vTypeObj.Values['$ref'].Value);

      if vFieldInfo.FieldType = 'number' then
        vFieldInfo.FieldType := 'Double'
      else if vFieldInfo.FieldType = 'object' then
      begin
        vFieldInfo.FieldType := 'T' + CapitalizeFirstLetter(vJsonProps.Pairs[vJsonPropIndex].JsonString.Value);
        ChildType(pDelphiUnit, vJsonProps.Pairs[vJsonPropIndex]);
      end
      else if vFieldInfo.FieldType = 'array' then
      begin
        HandleArray(vFieldInfo, vJsonProps.Pairs[vJsonPropIndex]);
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

function TSwagDocToDelphiMVCControllerBuilder.ConvertSwaggerTypeToDelphiType(pSwaggerType: TSwagRequestParameter): TUnitTypeDefinition;
var
  vSwaggerType: TSwagTypeParameter;
  vJson: TJSONObject;
begin
  Result := TUnitTypeDefinition.Create;
  vSwaggerType := pSwaggerType.TypeParameter;
  case vSwaggerType of
    stpNotDefined:
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
        if Assigned(pSwaggerType.Items.Values['type']) then
        begin
          Result.TypeName := 'array of ' + pSwaggerType.Items.Values['type'].Value;
        end
        else
          Result.TypeName := 'array of ';
      end;
    end;
    stpFile: Result.TypeName := 'err File';
  end;
end;

function TSwagDocToDelphiMVCControllerBuilder.GenerateUnitText(pDelphiUnit: TDelphiUnit): string;
begin
  pDelphiUnit.Title := fSwagDoc.Info.Title;
  pDelphiUnit.Description := fSwagDoc.Info.Description;
  pDelphiUnit.License := fSwagDoc.Info.License.Name;
  Result := pDelphiUnit.Generate;
end;

end.
