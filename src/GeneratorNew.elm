module GeneratorNew exposing (requestToResponse)

import Dict
import Elm.CodeGen as C
import Elm.Pretty
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node
import Internal.Google.Protobuf exposing (FileDescriptorProto)
import Internal.Google.Protobuf.Compiler exposing (CodeGeneratorRequest, CodeGeneratorResponse, CodeGeneratorResponseFile)
import List.Extra
import MapperNew as Mapper
import Mapping.Common as Common
import Mapping.Dependencies as Dependencies exposing (Dependencies)
import Mapping.Enum as Enum
import Mapping.Import as Import
import Mapping.Message as Message
import Mapping.Struct as Struct exposing (Struct)
import Mapping.Syntax as Syntax
import Model exposing (Field(..))
import Set
import String.Extra


requestToResponse : CodeGeneratorRequest -> CodeGeneratorResponse
requestToResponse req =
    let
        filesToResponse file =
            { error = "", supportedFeatures = 3, file = file }
    in
    convert req.fileToGenerate req.protoFile |> List.map generate |> filesToResponse


generate : C.File -> CodeGeneratorResponseFile
generate file =
    { name = (Node.value file.moduleDefinition |> Module.moduleName |> String.join "/") ++ ".elm"
    , content = "{- !!! DO NOT EDIT THIS FILE MANUALLY !!! -}\n\n" ++ Elm.Pretty.pretty 120 file
    , insertionPoint = ""
    , generatedCodeInfo = Nothing
    }


convert : List String -> List FileDescriptorProto -> List C.File
convert fileNames descriptors =
    let
        files : List ( C.ModuleName, ( Struct, FileDescriptorProto ) )
        files =
            descriptors
                |> List.filter (.name >> (\name -> List.member name fileNames))
                |> List.map
                    (\descriptor ->
                        ( moduleName descriptor.name
                        , let
                            syntax =
                                Syntax.parseSyntax descriptor.syntax

                            subStructs =
                                List.map (Mapper.message syntax Nothing) descriptor.messageType
                          in
                          ( List.foldl Struct.append
                                { messages = []
                                , enums = List.map (Mapper.enum syntax Nothing) descriptor.enumType
                                , maps = []
                                }
                                subStructs
                          , descriptor
                          )
                        )
                    )

        allDependencies : Dependencies
        allDependencies =
            List.foldl (\( modName, ( struct, _ ) ) -> Dependencies.addModule modName (getAllExposedTypes struct)) Dependencies.empty files

        getDependencies : FileDescriptorProto -> Dependencies
        getDependencies descriptor =
            allDependencies |> Dict.filter (\modName _ -> List.map moduleName descriptor.dependency |> List.member modName)

        getExposedUnionTypes struct =
            struct.enums |> List.filter .isTopLevel |> List.map .dataType

        getOneOfs struct =
            struct.messages
                |> List.concatMap .fields
                |> List.filterMap
                    (\( _, field ) ->
                        case field of
                            OneOfField dataType _ ->
                                Just dataType

                            _ ->
                                Nothing
                    )

        getExposedOtherTypes struct =
            struct.messages |> List.filter .isTopLevel |> List.map .dataType

        getAllExposedTypes struct =
            getExposedUnionTypes struct ++ getExposedOtherTypes struct
    in
    files
        |> List.map
            (\( modName, ( struct, descriptor ) ) ->
                let
                    exposedUnionTypes =
                        struct.enums |> List.filter .isTopLevel |> List.map .dataType

                    otherExposedTypes =
                        struct.messages |> List.filter .isTopLevel |> List.map .dataType

                    exposedFunctions =
                        (exposedUnionTypes ++ otherExposedTypes)
                            |> List.concatMap (\t -> [ Common.decoderName t, Common.encoderName t ])

                    declarations =
                        List.concatMap Enum.toAST struct.enums
                            ++ List.concatMap (Message.toAST (getDependencies descriptor)) struct.messages
                in
                C.file
                    (C.normalModule modName
                        (List.map C.openTypeExpose exposedUnionTypes
                            ++ List.map C.openTypeExpose (getOneOfs struct)
                            ++ List.map C.typeOrAliasExpose otherExposedTypes
                            ++ List.map C.funExpose exposedFunctions
                        )
                    )
                    (List.map (\importedModule -> C.importStmt importedModule Nothing Nothing) (Set.toList <| Import.extractImports declarations))
                    declarations
                    (C.emptyFileComment |> fileComment descriptor |> Just)
            )


fileComment : FileDescriptorProto -> C.Comment C.FileComment -> C.Comment C.FileComment
fileComment descriptor =
    C.markdown <| """
This file was automatically generated by
- [`protoc-gen-elm`](https://www.npmjs.com/package/protoc-gen-elm) 1.0.0-beta-2
- `protoc` 3.14.0
- the following specification file: `""" ++ descriptor.name ++ """`

To run it, add a dependency via `elm install` on [`elm-protocol-buffers`](https://package.elm-lang.org/packages/eriktim/elm-protocol-buffers/1.1.0) version 1.1.0 or higher."""


moduleName : String -> C.ModuleName
moduleName descriptorName =
    let
        defaultName =
            String.split "/" descriptorName
                |> List.Extra.unconsLast
                |> Maybe.map (\( name, segments ) -> segments ++ [ removeExtension name ])
                |> Maybe.withDefault []
                |> List.map String.Extra.classify
    in
    case defaultName of
        [ singleSegment ] ->
            [ "Proto", singleSegment ]

        _ ->
            defaultName


removeExtension : String -> String
removeExtension =
    String.split "."
        >> List.Extra.init
        >> Maybe.withDefault []
        >> String.join "."


moduleDefinition : FileDescriptorProto -> C.Module
moduleDefinition descriptor =
    C.normalModule (moduleName descriptor.name) []
