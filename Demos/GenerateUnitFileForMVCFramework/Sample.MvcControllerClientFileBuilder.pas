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
  DelphiSwaggerBuilder,
  Sample.DelphiUnit.Generate;

type
  TSwagDocToDelphiMVCControllerBuilder = class(TSwagDocToDelphiBuilderBase)
  strict private
    fSwagDoc: TSwagDoc;

    function RewriteUriToDelphiMVCFrameworkWay(const pUri: string): string;
    function GenerateUnitText(pDelphiUnit: TDelphiUnit): string;

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
  inherited Create(pSwagDoc);
  fSwagDoc := pSwagDoc;
end;

function TSwagDocToDelphiMVCControllerBuilder.RewriteUriToDelphiMVCFrameworkWay(const pUri: string): string;
begin
  Result := pUri.Replace('{','($').Replace('}',')');
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
  vSwagParam: TSwagRequestParameter;
  vResponse: TPair<string, TSwagResponse>;
  vSchemaObj: TJsonObject;
  vResultParam: TUnitParameter;
  vField: TUnitFieldDefinition;
  vRef: String;
  vStatusCode : Integer;
begin
  vResultParam := nil;
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
        vMethod.Name := OperationIdToFunctionName(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex], fSwagDoc.Paths[vPathIndex].Uri);

        for vParameterIndex := 0 to fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters.Count - 1 do
        begin
          vResultParam := TUnitParameter.Create;
          vResultParam.ParamName := CapitalizeFirstLetter(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Name);
          vResultParam.ParamType := ConvertSwaggerRequestParameterTypeToDelphiType(vDelphiUnit, fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex], fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex]);
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
              if vStatusCode >= 400 then
              begin
                vExceptionsFromClient := vDelphiUnit.LookupTypeByName(ConvertRefToType(vRef));
                if Assigned(vExceptionsFromClient) then
                begin
                  vExceptionsFromClient.TypeName := ConvertRefToExceptionType(vRef);
                  vExceptionsFromClient.TypeInherited := 'Exception';
                  vMethod.Content.Add('//  raise ' + vExceptionsFromClient.TypeName + '.Create(' + vStatusCode.ToString + ', ' + QuotedStr(vResponse.Value.Description) + ');');
                end
                else if not Assigned(vDelphiUnit.LookupTypeByName(ConvertRefToExceptionType(vRef))) then
                begin
                  { TODO : This probably means that it was an inline definition here.  Need to handle this }
                  raise Exception.Create('Inline Exception Decoding not implemented yet!');
                end;
              end
              else
              begin
                vResultParam := TUnitParameter.Create;
                vResultParam.ParamName := ConvertRefToVarName(vRef);
                vResultParam.ParamType := TUnitTypeDefinition.Create;
                vResultParam.ParamType.TypeName := ConvertRefToType(vRef);
                vMethod.AddLocalVariable(vResultParam);
                vMethod.Content.Add('  ' + ConvertRefToVarName(vRef) + ' := ' + ConvertRefToType(vRef) + '.Create;');
              end;
               for vParameterIndex := 0 to fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters.Count - 1 do
                begin
                  vRef := fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Ref;
                  vSwagParam := LookupParamRef(vRef);
                  if Assigned(vSwagParam) then
                  begin
                    vMethod.Content.Add('  ' + MakeDelphiSafeVariableName(vSwagParam.Name) + ' := Params[' + vSwagParam.Name.QuotedString + '];');
                  end
                  else
                    vMethod.Content.Add('  ' + MakeDelphiSafeVariableName(fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Name) + ' := Params[' + fSwagDoc.Paths[vPathIndex].Operations[vOperationIndex].Parameters[vParameterIndex].Name.QuotedString + '];');
                end;
                vMethod.Content.Add('');
                vMethod.Content.Add('');
                vMethod.Content.Add('  Render(' + vResultParam.ParamName + ');');
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


function TSwagDocToDelphiMVCControllerBuilder.GenerateUnitText(pDelphiUnit: TDelphiUnit): string;
begin
  pDelphiUnit.Title := fSwagDoc.Info.Title;
  pDelphiUnit.Description := fSwagDoc.Info.Description;
  pDelphiUnit.License := fSwagDoc.Info.License.Name;
  Result := pDelphiUnit.Generate;
end;

end.
