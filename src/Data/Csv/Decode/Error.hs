{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Data.Csv.Decode.Error where

import Data.Semigroup
import Data.Validation
import Data.List.NonEmpty

import Data.Csv.Field

-- TODO eventually give this type a much better show
data DecodeError e =
  UnexpectedEndOfRow
  | ExpectedEndOfRow [Field e]
  | UnknownCanonicalValue e [(e, [e])]
  | BadDecode e
  deriving (Eq, Ord, Show)

newtype DecodeErrors e =
  DecodeErrors (NonEmpty (DecodeError e))
  deriving (Eq, Ord, Show, Semigroup)

type DecodeValidation e = AccValidation (DecodeErrors e)

decodeError :: DecodeError e -> DecodeValidation e a
decodeError = AccFailure . DecodeErrors . pure

unexpectedEndOfRow :: DecodeValidation e a
unexpectedEndOfRow = decodeError UnexpectedEndOfRow

expectedEndOfRow :: [Field e] -> DecodeValidation e a
expectedEndOfRow = decodeError . ExpectedEndOfRow

unknownCanonicalValue :: e -> [(e, [e])] -> DecodeValidation e a
unknownCanonicalValue unknown valids = decodeError (UnknownCanonicalValue unknown valids)

badDecode :: e -> DecodeValidation e a
badDecode = decodeError . BadDecode
