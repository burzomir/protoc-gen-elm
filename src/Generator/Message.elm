module Generator.Message exposing (..)

import Elm.CodeGen as C exposing (ModuleName)
import Generator.Common as Common
import Mapper.Name
import Meta.Basics
import Meta.Decode
import Meta.Encode
import Meta.Type
import Model exposing (Cardinality(..), DataType, Field(..), FieldName, FieldType(..), Map, Message, TypeKind(..))


reexportAST : ModuleName -> ModuleName -> Message -> List C.Declaration
reexportAST internalsModule moduleName msg =
    let
        documentation =
            if List.isEmpty msg.docs then
                messageDocumentation msg.dataType

            else
                Common.renderDocs msg.docs

        type_ =
            C.aliasDecl (Just documentation) msg.dataType [] <|
                C.fqTyped internalsModule (Mapper.Name.internalize ( moduleName, msg.dataType )) []

        encoder =
            C.valDecl (Just <| Common.encoderDocumentation msg.dataType)
                (Just <| Meta.Encode.encoder (C.typed msg.dataType []))
                (Common.encoderName msg.dataType)
                (C.fqVal internalsModule <| Common.encoderName <| Mapper.Name.internalize ( moduleName, msg.dataType ))

        decoder =
            C.valDecl (Just <| Common.decoderDocumentation msg.dataType)
                (Just <| Meta.Decode.decoder (C.typed msg.dataType []))
                (Common.decoderName msg.dataType)
                (C.fqVal internalsModule <| Common.decoderName <| Mapper.Name.internalize ( moduleName, msg.dataType ))

        default =
            C.valDecl (Just <| Common.defaultDocumentation msg.dataType)
                (Just <| C.typed msg.dataType [])
                (Common.defaultName msg.dataType)
                (C.fqVal internalsModule <| Common.defaultName <| Mapper.Name.internalize ( moduleName, msg.dataType ))

        fieldDeclarationsReexport : ( FieldName, Field ) -> List C.Declaration
        fieldDeclarationsReexport ( _, field ) =
            case field of
                NormalField _ _ (Embedded embedded) ->
                    case embedded.typeKind of
                        Alias ->
                            []

                        Type ->
                            let
                                recursiveWrapperName =
                                    recursiveDataTypeName embedded.dataType

                                wrappedAnn =
                                    C.typed embedded.dataType []

                                recursiveTypeWrapper : C.Declaration
                                recursiveTypeWrapper =
                                    C.aliasDecl (Just <| recursiveDataTypeDocumentation embedded.dataType)
                                        recursiveWrapperName
                                        []
                                        (C.fqTyped internalsModule
                                            (Mapper.Name.internalize
                                                ( embedded.moduleName, recursiveDataTypeName embedded.dataType )
                                            )
                                            []
                                        )

                                wrapper : C.Declaration
                                wrapper =
                                    C.valDecl (Just <| recursiveWrapDocumentation embedded.dataType)
                                        (Just <| C.funAnn wrappedAnn (C.typed recursiveWrapperName []))
                                        (recursiveWrapName embedded.dataType)
                                        (C.fqVal internalsModule
                                            (Mapper.Name.internalize
                                                ( embedded.moduleName, recursiveDataTypeName embedded.dataType )
                                            )
                                        )

                                unwrapper : C.Declaration
                                unwrapper =
                                    C.valDecl (Just <| recursiveUnwrapDocumentation embedded.dataType)
                                        (Just <| C.funAnn (C.typed recursiveWrapperName []) wrappedAnn)
                                        (recursiveUnwrapName embedded.dataType)
                                        (C.fqVal internalsModule <| recursiveUnwrapName <| Mapper.Name.internalize ( embedded.moduleName, embedded.dataType ))
                            in
                            [ recursiveTypeWrapper, wrapper, unwrapper ]

                NormalField _ _ _ ->
                    []

                MapField _ _ _ ->
                    []

                OneOfField _ ->
                    []

        fieldNumbersDecl : C.Declaration
        fieldNumbersDecl =
            C.valDecl (Just <| Common.fieldNumbersDocumentation msg.dataType)
                (Just <| C.recordAnn <| List.map (Tuple.mapSecond fieldNumberTypeForField) msg.fields)
                (Common.fieldNumbersName msg.dataType)
                (C.fqVal internalsModule <| Common.fieldNumbersName <| Mapper.Name.internalize ( moduleName, msg.dataType ))
    in
    [ type_, encoder, decoder, default, fieldNumbersDecl ] ++ List.concatMap fieldDeclarationsReexport msg.fields


toAST : Message -> List C.Declaration
toAST msg =
    let
        type_ : C.Declaration
        type_ =
            C.aliasDecl (Just <| messageDocumentation msg.dataType)
                msg.dataType
                []
                (C.recordAnn <| List.map (Tuple.mapSecond fieldToTypeAnnotation) msg.fields)

        encoder : C.Declaration
        encoder =
            C.funDecl (Just <| Common.encoderDocumentation msg.dataType)
                (Just <| Meta.Encode.encoder (C.typed msg.dataType []))
                (Common.encoderName msg.dataType)
                [ if msg.fields == [] then
                    C.allPattern

                  else
                    C.varPattern "value"
                ]
                (Meta.Encode.message
                    (List.map toEncoder msg.fields)
                )

        decoder : C.Declaration
        decoder =
            C.valDecl (Just <| Common.decoderDocumentation msg.dataType)
                (Just <| Meta.Decode.decoder (C.typed msg.dataType []))
                (Common.decoderName msg.dataType)
                (C.apply
                    [ Meta.Decode.message
                    , C.val <| Common.defaultName msg.dataType
                    , C.list <| List.map toDecoder msg.fields
                    ]
                )

        default : C.Declaration
        default =
            C.valDecl (Just <| Common.defaultDocumentation msg.dataType)
                (Just <| C.typed msg.dataType [])
                (Common.defaultName msg.dataType)
                (C.record <| List.map (Tuple.mapSecond toDefaultValue) msg.fields)

        fieldNumbersDecl : C.Declaration
        fieldNumbersDecl =
            C.valDecl (Just <| Common.fieldNumbersDocumentation msg.dataType)
                (Just <| C.recordAnn <| List.map (Tuple.mapSecond fieldNumberTypeForField) msg.fields)
                (Common.fieldNumbersName msg.dataType)
                (C.record <| List.map (Tuple.mapSecond fieldNumberForField) msg.fields)
    in
    [ type_, encoder, decoder, default, fieldNumbersDecl ]
        ++ List.concatMap fieldDeclarations msg.fields


mapComment : Map -> C.Comment C.DocComment
mapComment map =
    C.emptyDocComment
        |> C.markdown ("Dict for " ++ map.dataType)


getter : FieldName -> C.Expression
getter fieldName =
    C.accessFun <| "." ++ fieldName


fieldDeclarations : ( FieldName, Field ) -> List C.Declaration
fieldDeclarations ( _, field ) =
    case field of
        NormalField _ _ (Embedded embedded) ->
            case embedded.typeKind of
                Alias ->
                    []

                Type ->
                    let
                        recursiveWrapperName =
                            recursiveDataTypeName (Mapper.Name.internalize ( embedded.moduleName, embedded.dataType ))

                        wrappedAnn =
                            C.typed (Mapper.Name.internalize ( embedded.moduleName, embedded.dataType )) []

                        recursiveTypeWrapper : C.Declaration
                        recursiveTypeWrapper =
                            C.customTypeDecl (Just <| recursiveDataTypeDocumentation embedded.dataType) recursiveWrapperName [] [ ( recursiveWrapperName, [ wrappedAnn ] ) ]

                        unwrapper : C.Declaration
                        unwrapper =
                            C.funDecl (Just <| recursiveUnwrapDocumentation embedded.dataType)
                                (Just <| C.funAnn (C.typed recursiveWrapperName []) wrappedAnn)
                                (recursiveUnwrapName <| Mapper.Name.internalize ( embedded.moduleName, embedded.dataType ))
                                [ C.namedPattern recursiveWrapperName [ C.varPattern "wrapped" ] ]
                                (C.val "wrapped")
                    in
                    [ recursiveTypeWrapper, unwrapper ]

        NormalField _ _ _ ->
            []

        MapField _ _ _ ->
            []

        OneOfField _ ->
            []


fieldTypeToDefaultValue : FieldType -> C.Expression
fieldTypeToDefaultValue fieldType =
    case fieldType of
        Primitive _ defaultValue ->
            defaultValue

        Embedded _ ->
            Meta.Basics.nothing

        Enumeration enum ->
            C.fqVal (Common.internalsModule enum.rootPackage) (Common.defaultName <| Mapper.Name.internalize ( enum.package, enum.name ))


toDefaultValue : Field -> C.Expression
toDefaultValue field =
    case field of
        NormalField _ cardinality fieldType ->
            case ( cardinality, fieldType ) of
                ( Proto3Optional, _ ) ->
                    Meta.Basics.nothing

                ( Optional, Primitive _ defaultValue ) ->
                    defaultValue

                ( Repeated, _ ) ->
                    C.list []

                ( Required, Primitive _ defaultValue ) ->
                    defaultValue

                ( Optional, Embedded _ ) ->
                    Meta.Basics.nothing

                ( Required, Embedded e ) ->
                    C.fqVal (Common.internalsModule e.rootModuleName) (Common.defaultName <| Mapper.Name.internalize ( e.moduleName, e.dataType ))
                        |> (\val ->
                                case e.typeKind of
                                    Alias ->
                                        val

                                    Type ->
                                        C.apply
                                            [ C.fqVal
                                                (Common.internalsModule e.rootModuleName)
                                                (recursiveDataTypeName <| Mapper.Name.internalize ( e.moduleName, e.dataType ))
                                            , val
                                            ]
                           )

                ( _, Enumeration enum ) ->
                    fieldTypeToDefaultValue (Enumeration enum)

        MapField _ _ _ ->
            C.fqFun [ "Dict" ] "empty"

        OneOfField _ ->
            Meta.Basics.nothing


toDecoder : ( FieldName, Field ) -> C.Expression
toDecoder ( fieldName, field ) =
    case field of
        NormalField number cardinality fieldType ->
            case cardinality of
                Optional ->
                    C.apply
                        [ Meta.Decode.optional
                        , C.int number
                        , fieldTypeToDecoder fieldType cardinality
                        , Common.setter fieldName
                        ]

                Proto3Optional ->
                    C.apply
                        [ Meta.Decode.optional
                        , C.int number
                        , fieldTypeToDecoder fieldType cardinality
                        , Common.setter fieldName
                        ]

                Required ->
                    C.apply
                        [ Meta.Decode.required
                        , C.int number
                        , fieldTypeToDecoder fieldType cardinality
                        , Common.setter fieldName
                        ]

                Repeated ->
                    C.apply
                        [ Meta.Decode.repeated
                        , C.int number
                        , fieldTypeToDecoder fieldType cardinality
                        , getter fieldName
                        , Common.setter fieldName
                        ]

        MapField number key value ->
            C.apply
                [ Meta.Decode.mapped
                , C.int number
                , C.tuple [ fieldTypeToDefaultValue key, fieldTypeToDefaultValue value ]
                , fieldTypeToDecoder key Optional
                , fieldTypeToDecoder value Optional
                , C.accessFun <| "." ++ fieldName
                , Common.setter fieldName
                ]

        OneOfField ref ->
            C.apply
                [ C.fqFun (Common.internalsModule ref.rootPackage) (Common.decoderName <| Mapper.Name.internalize ( ref.package, ref.name ))
                , Common.setter fieldName
                ]


embeddedDecoder : { dataType : DataType, moduleName : C.ModuleName, rootModuleName : C.ModuleName, typeKind : TypeKind } -> C.Expression
embeddedDecoder e =
    (case e.typeKind of
        Alias ->
            identity

        Type ->
            C.parens
                << C.applyBinOp
                    (C.apply
                        [ Meta.Decode.map
                        , C.fqVal (Common.internalsModule e.rootModuleName) <|
                            recursiveDataTypeName <|
                                Mapper.Name.internalize ( e.moduleName, e.dataType )
                        ]
                    )
                    C.pipel
                << C.applyBinOp Meta.Decode.lazy C.pipel
                << C.lambda [ C.allPattern ]
    )
        (C.fqFun (Common.internalsModule e.rootModuleName) (Common.decoderName <| Mapper.Name.internalize ( e.moduleName, e.dataType )))


fieldTypeToDecoder : FieldType -> Cardinality -> C.Expression
fieldTypeToDecoder fieldType cardinality =
    case ( cardinality, fieldType ) of
        ( Proto3Optional, Primitive dataType _ ) ->
            C.parens
                (C.apply
                    [ Meta.Decode.map
                    , Meta.Basics.just
                    , Meta.Decode.forPrimitive dataType
                    ]
                )

        ( _, Primitive dataType _ ) ->
            Meta.Decode.forPrimitive dataType

        ( Required, Embedded e ) ->
            embeddedDecoder e

        ( Repeated, Embedded e ) ->
            embeddedDecoder e

        ( _, Embedded e ) ->
            C.parens
                (C.apply
                    [ Meta.Decode.map
                    , Meta.Basics.just
                    , embeddedDecoder e
                    ]
                )

        ( Proto3Optional, Enumeration enum ) ->
            C.parens
                (C.apply
                    [ Meta.Decode.map
                    , Meta.Basics.just
                    , C.fqFun
                        (Common.internalsModule enum.rootPackage)
                        (Common.decoderName <| Mapper.Name.internalize ( enum.package, enum.name ))
                    ]
                )

        ( _, Enumeration enum ) ->
            C.fqFun (Common.internalsModule enum.rootPackage)
                (Common.decoderName <| Mapper.Name.internalize ( enum.package, enum.name ))


toEncoder : ( FieldName, Field ) -> C.Expression
toEncoder ( fieldName, field ) =
    case field of
        NormalField number cardinality fieldType ->
            C.tuple [ C.int number, C.apply [ fieldTypeToEncoder cardinality fieldType, C.access (C.val "value") fieldName ] ]

        MapField number key value ->
            C.tuple
                [ C.int number
                , C.apply
                    [ Meta.Encode.dict
                    , fieldTypeToEncoder Optional key
                    , fieldTypeToEncoder Optional value
                    , C.access (C.val "value") fieldName
                    ]
                ]

        OneOfField ref ->
            C.apply
                [ C.fqFun (Common.internalsModule ref.rootPackage)
                    (Common.encoderName <|
                        Mapper.Name.internalize ( ref.package, ref.name )
                    )
                , C.access (C.val "value") fieldName
                ]


embeddedEncoder : { dataType : DataType, moduleName : C.ModuleName, rootModuleName : C.ModuleName, typeKind : TypeKind } -> C.Expression
embeddedEncoder e =
    (case e.typeKind of
        Alias ->
            identity

        Type ->
            C.parens
                << C.applyBinOp
                    (C.fqFun (Common.internalsModule e.rootModuleName) <|
                        recursiveUnwrapName <|
                            Mapper.Name.internalize ( e.moduleName, e.dataType )
                    )
                    C.composer
    )
        (C.fqFun (Common.internalsModule e.rootModuleName) (Common.encoderName <| Mapper.Name.internalize ( e.moduleName, e.dataType )))


fieldTypeToEncoder : Cardinality -> FieldType -> C.Expression
fieldTypeToEncoder cardinality fieldType =
    case ( cardinality, fieldType ) of
        ( Proto3Optional, Primitive dataType _ ) ->
            C.parens <|
                C.applyBinOp
                    (C.apply [ Meta.Basics.mapMaybe, Meta.Encode.forPrimitive dataType ])
                    C.composer
                    (C.apply [ Meta.Basics.withDefault, Meta.Encode.none ])

        ( Optional, Primitive dataType _ ) ->
            Meta.Encode.forPrimitive dataType

        ( Required, Primitive dataType _ ) ->
            Meta.Encode.forPrimitive dataType

        ( Required, Embedded e ) ->
            embeddedEncoder e

        ( Required, Enumeration enum ) ->
            C.fqFun (Common.internalsModule enum.rootPackage) (Common.encoderName <| Mapper.Name.internalize ( enum.package, enum.name ))

        ( Repeated, Primitive dataType _ ) ->
            C.apply [ Meta.Encode.list, Meta.Encode.forPrimitive dataType ]

        ( Repeated, Embedded e ) ->
            C.apply [ Meta.Encode.list, embeddedEncoder e ]

        ( Repeated, Enumeration enum ) ->
            C.apply
                [ Meta.Encode.list
                , C.fqFun (Common.internalsModule enum.rootPackage)
                    (Common.encoderName <| Mapper.Name.internalize ( enum.package, enum.name ))
                ]

        ( _, Embedded e ) ->
            C.parens <|
                C.applyBinOp
                    (C.apply [ Meta.Basics.mapMaybe, embeddedEncoder e ])
                    C.composer
                    (C.apply [ Meta.Basics.withDefault, Meta.Encode.none ])

        ( Proto3Optional, Enumeration enum ) ->
            C.parens <|
                C.applyBinOp
                    (C.apply
                        [ Meta.Basics.mapMaybe
                        , C.fqFun (Common.internalsModule enum.rootPackage) (Common.encoderName <| Mapper.Name.internalize ( enum.package, enum.name ))
                        ]
                    )
                    C.composer
                    (C.apply [ Meta.Basics.withDefault, Meta.Encode.none ])

        ( Optional, Enumeration enum ) ->
            C.fqFun (Common.internalsModule enum.rootPackage) (Common.encoderName <| Mapper.Name.internalize ( enum.package, enum.name ))


fieldTypeToTypeAnnotation : FieldType -> C.TypeAnnotation
fieldTypeToTypeAnnotation fieldType =
    case fieldType of
        Primitive dataType _ ->
            Meta.Type.forPrimitive dataType

        Embedded e ->
            C.fqTyped (Common.internalsModule e.rootModuleName)
                (Mapper.Name.internalize
                    ( e.moduleName
                    , case e.typeKind of
                        Alias ->
                            e.dataType

                        Type ->
                            recursiveDataTypeName e.dataType
                    )
                )
                []

        Enumeration enum ->
            C.fqTyped (Common.internalsModule enum.rootPackage) (Mapper.Name.internalize ( enum.package, enum.name )) []


fieldToTypeAnnotation : Field -> C.TypeAnnotation
fieldToTypeAnnotation field =
    let
        cardinalityModifier cardinality fieldType =
            case ( cardinality, fieldType ) of
                ( Optional, Primitive _ _ ) ->
                    identity

                ( Optional, Enumeration _ ) ->
                    identity

                ( Required, _ ) ->
                    identity

                ( Optional, _ ) ->
                    C.maybeAnn

                ( Repeated, _ ) ->
                    C.listAnn

                ( Proto3Optional, _ ) ->
                    C.maybeAnn
    in
    case field of
        NormalField _ cardinality fieldType ->
            cardinalityModifier cardinality
                fieldType
                (fieldTypeToTypeAnnotation fieldType)

        MapField _ key value ->
            Meta.Type.dict (fieldTypeToTypeAnnotation key)
                (cardinalityModifier Optional value <| fieldTypeToTypeAnnotation value)

        OneOfField ref ->
            C.maybeAnn <| C.fqTyped (Common.internalsModule ref.rootPackage) (Mapper.Name.internalize ( ref.package, ref.name )) []


fieldNumberTypeForField : Field -> C.TypeAnnotation
fieldNumberTypeForField field =
    case field of
        NormalField _ _ _ ->
            C.intAnn

        MapField _ _ _ ->
            C.intAnn

        OneOfField ref ->
            C.fqTyped
                (Common.internalsModule ref.rootPackage)
                (Common.fieldNumbersTypeName <| Mapper.Name.internalize ( ref.package, ref.name ))
                []


fieldNumberForField : Field -> C.Expression
fieldNumberForField field =
    case field of
        NormalField n _ _ ->
            C.int n

        MapField n _ _ ->
            C.int n

        OneOfField ref ->
            C.fqVal (Common.internalsModule ref.rootPackage) (Common.fieldNumbersName <| Mapper.Name.internalize ( ref.package, ref.name ))


recursiveDataTypeName : String -> String
recursiveDataTypeName wrappedDataType =
    wrappedDataType ++ "_"


recursiveUnwrapName : String -> String
recursiveUnwrapName wrappedDataType =
    "unwrap" ++ wrappedDataType


recursiveWrapName : String -> String
recursiveWrapName wrappedDataType =
    "wrap" ++ wrappedDataType


messageDocumentation : String -> C.Comment C.DocComment
messageDocumentation msgName =
    C.emptyDocComment |> C.markdown ("`" ++ msgName ++ "` message")


oneofDocumentation : String -> C.Comment C.DocComment
oneofDocumentation msgName =
    C.emptyDocComment |> C.markdown ("`" ++ msgName ++ "` options")


recursiveDataTypeDocumentation : String -> C.Comment C.DocComment
recursiveDataTypeDocumentation wrappedDataType =
    C.emptyDocComment
        |> C.markdown
            ("Type wrapper for alias type `"
                ++ wrappedDataType
                ++ "` to avoid unlimited recursion."
            )
        |> C.markdown
            ("For a more in-depth explanation why we need this, read this: " ++ recursiveExplanationLink ++ ".")


recursiveExplanationLink : String
recursiveExplanationLink =
    "https://github.com/elm/compiler/blob/master/hints/recursive-alias.md"


recursiveUnwrapDocumentation : String -> C.Comment C.DocComment
recursiveUnwrapDocumentation wrappedDataType =
    C.emptyDocComment |> C.markdown ("Unwrap a `" ++ wrappedDataType ++ "` from its wrapper `" ++ recursiveDataTypeName wrappedDataType ++ ".`")


recursiveWrapDocumentation : String -> C.Comment C.DocComment
recursiveWrapDocumentation wrappedDataType =
    C.emptyDocComment |> C.markdown ("Wrap a `" ++ wrappedDataType ++ "` into its wrapper `" ++ recursiveDataTypeName wrappedDataType ++ ".`")
