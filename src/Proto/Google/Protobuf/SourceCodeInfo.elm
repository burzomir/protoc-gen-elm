{- !!! DO NOT EDIT THIS FILE MANUALLY !!! -}

module Proto.Google.Protobuf.SourceCodeInfo exposing (..)

{-| 
This file was automatically generated by
- [`protoc-gen-elm`](https://www.npmjs.com/package/protoc-gen-elm) 3.0.0-beta.1
- `protoc` 3.19.4
- the following specification files: `google/protobuf/descriptor.proto`

To run it, add a dependency via `elm install` on [`elm-protocol-buffers`](https://package.elm-lang.org/packages/eriktim/elm-protocol-buffers/1.2.0) version 1.2.0 or higher.


-}

import Proto.Google.Protobuf.Internals_
import Protobuf.Decode
import Protobuf.Encode


{-| Default for Location. Should only be used for 'required' decoders as an initial value.


-}
defaultLocation : Location
defaultLocation =
    Proto.Google.Protobuf.Internals_.defaultProto__Google__Protobuf__SourceCodeInfo__Location


{-| Declares how to decode a `Location` from Bytes. To actually perform the conversion from Bytes, you need to use Protobuf.Decode.decode from eriktim/elm-protocol-buffers.


-}
decodeLocation : Protobuf.Decode.Decoder Location
decodeLocation =
    Proto.Google.Protobuf.Internals_.decodeProto__Google__Protobuf__SourceCodeInfo__Location


{-| Declares how to encode a `Location` to Bytes. To actually perform the conversion to Bytes, you need to use Protobuf.Encode.encode from eriktim/elm-protocol-buffers.


-}
encodeLocation : Location -> Protobuf.Encode.Encoder
encodeLocation =
    Proto.Google.Protobuf.Internals_.encodeProto__Google__Protobuf__SourceCodeInfo__Location


{-| `Location` message


-}
type alias Location =
    Proto.Google.Protobuf.Internals_.Proto__Google__Protobuf__SourceCodeInfo__Location
