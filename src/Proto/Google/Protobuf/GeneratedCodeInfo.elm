{- !!! DO NOT EDIT THIS FILE MANUALLY !!! -}

module Proto.Google.Protobuf.GeneratedCodeInfo exposing (Annotation, decodeAnnotation, defaultAnnotation, encodeAnnotation, fieldNumbersAnnotation)

{-| 
This file was automatically generated by
- [`protoc-gen-elm`](https://www.npmjs.com/package/protoc-gen-elm) 3.1.0
- `protoc` 3.19.4
- the following specification files: `google/protobuf/descriptor.proto`

To run it, add a dependency via `elm install` on [`elm-protocol-buffers`](https://package.elm-lang.org/packages/eriktim/elm-protocol-buffers/1.2.0) version 1.2.0 or higher.


@docs Annotation, decodeAnnotation, defaultAnnotation, encodeAnnotation, fieldNumbersAnnotation
-}

import Proto.Google.Protobuf.Internals_
import Protobuf.Decode
import Protobuf.Encode


{-| The field numbers for the fields of `Annotation`. This is mostly useful for internals, like documentation generation.


-}
fieldNumbersAnnotation : { path : Int, sourceFile : Int, begin : Int, end : Int }
fieldNumbersAnnotation =
    Proto.Google.Protobuf.Internals_.fieldNumbersProto__Google__Protobuf__GeneratedCodeInfo__Annotation


{-| Default for Annotation. Should only be used for 'required' decoders as an initial value.


-}
defaultAnnotation : Annotation
defaultAnnotation =
    Proto.Google.Protobuf.Internals_.defaultProto__Google__Protobuf__GeneratedCodeInfo__Annotation


{-| Declares how to decode a `Annotation` from Bytes. To actually perform the conversion from Bytes, you need to use Protobuf.Decode.decode from eriktim/elm-protocol-buffers.


-}
decodeAnnotation : Protobuf.Decode.Decoder Annotation
decodeAnnotation =
    Proto.Google.Protobuf.Internals_.decodeProto__Google__Protobuf__GeneratedCodeInfo__Annotation


{-| Declares how to encode a `Annotation` to Bytes. To actually perform the conversion to Bytes, you need to use Protobuf.Encode.encode from eriktim/elm-protocol-buffers.


-}
encodeAnnotation : Annotation -> Protobuf.Encode.Encoder
encodeAnnotation =
    Proto.Google.Protobuf.Internals_.encodeProto__Google__Protobuf__GeneratedCodeInfo__Annotation


{-| ## Fields


### path


 Identifies the element in the original source .proto file. This field
 is formatted the same as SourceCodeInfo.Location.path.



### sourceFile


 Identifies the filesystem path to the original source .proto.



### begin


 Identifies the starting offset in bytes in the generated code
 that relates to the identified object.



### end


 Identifies the ending offset in bytes in the generated code that
 relates to the identified offset. The end offset should be one past
 the last relevant byte (so the length of the text = end - begin).



-}
type alias Annotation =
    Proto.Google.Protobuf.Internals_.Proto__Google__Protobuf__GeneratedCodeInfo__Annotation
