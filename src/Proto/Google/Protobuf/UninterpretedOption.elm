{- !!! DO NOT EDIT THIS FILE MANUALLY !!! -}

module Proto.Google.Protobuf.UninterpretedOption exposing (NamePart, decodeNamePart, defaultNamePart, encodeNamePart, fieldNumbersNamePart)

{-| 
This file was automatically generated by
- [`protoc-gen-elm`](https://www.npmjs.com/package/protoc-gen-elm) 3.1.0
- `protoc` 3.19.4
- the following specification files: `google/protobuf/descriptor.proto`

To run it, add a dependency via `elm install` on [`elm-protocol-buffers`](https://package.elm-lang.org/packages/eriktim/elm-protocol-buffers/1.2.0) version 1.2.0 or higher.


@docs NamePart, decodeNamePart, defaultNamePart, encodeNamePart, fieldNumbersNamePart
-}

import Proto.Google.Protobuf.Internals_
import Protobuf.Decode
import Protobuf.Encode


{-| The field numbers for the fields of `NamePart`. This is mostly useful for internals, like documentation generation.


-}
fieldNumbersNamePart : { namePart : Int, isExtension : Int }
fieldNumbersNamePart =
    Proto.Google.Protobuf.Internals_.fieldNumbersProto__Google__Protobuf__UninterpretedOption__NamePart


{-| Default for NamePart. Should only be used for 'required' decoders as an initial value.


-}
defaultNamePart : NamePart
defaultNamePart =
    Proto.Google.Protobuf.Internals_.defaultProto__Google__Protobuf__UninterpretedOption__NamePart


{-| Declares how to decode a `NamePart` from Bytes. To actually perform the conversion from Bytes, you need to use Protobuf.Decode.decode from eriktim/elm-protocol-buffers.


-}
decodeNamePart : Protobuf.Decode.Decoder NamePart
decodeNamePart =
    Proto.Google.Protobuf.Internals_.decodeProto__Google__Protobuf__UninterpretedOption__NamePart


{-| Declares how to encode a `NamePart` to Bytes. To actually perform the conversion to Bytes, you need to use Protobuf.Encode.encode from eriktim/elm-protocol-buffers.


-}
encodeNamePart : NamePart -> Protobuf.Encode.Encoder
encodeNamePart =
    Proto.Google.Protobuf.Internals_.encodeProto__Google__Protobuf__UninterpretedOption__NamePart


{-|  The name of the uninterpreted option.  Each string represents a segment in
 a dot-separated name.  is_extension is true iff a segment represents an
 extension (denoted with parentheses in options specs in .proto files).
 E.g.,{ ["foo", false], ["bar.baz", true], ["qux", false] } represents
 "foo.(bar.baz).qux".



-}
type alias NamePart =
    Proto.Google.Protobuf.Internals_.Proto__Google__Protobuf__UninterpretedOption__NamePart
