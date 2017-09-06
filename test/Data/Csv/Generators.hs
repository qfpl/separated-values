module Data.Csv.Generators (
  genCsv
  , genNewline
  , genSep
  , genFinalRecord
  , genBetween
  , genEscaped
  , genQuote
  , genField
  , genRecord
  , genRecords
  , genNonEmptyRecord
  , genPesarated
  , genSeparated
) where

import Control.Applicative ((<$>), liftA2, liftA3)
import Data.Separated      (Pesarated (Pesarated), Separated (Separated))
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Data.Csv.Csv        (Csv (Csv))
import Data.Csv.Field      (Field (QuotedF, UnquotedF), MonoField (MonoField))
import Data.Csv.Record     (Record (Record), NonEmptyRecord (SingleFieldNER, MultiFieldNER), FinalRecord (FinalRecord), Records (Records))
import Text.Between        (Between (Between))
import Text.Escaped        (Escaped (SeparatedByEscapes))
import Text.Newline        (Newline (CRLF, LF))
import Text.Quote          (Quote (SingleQuote, DoubleQuote), Quoted (Quoted))

genCsv :: Gen Char -> Gen spc -> Gen s1 -> Gen s2 -> Gen (Csv spc s1 s2)
genCsv sep spc s1 s2 =
  let rs = genRecords spc s2
      e  = genFinalRecord spc s1 s2
  in  liftA3 Csv sep rs e

genNewline :: Gen Newline
genNewline =
  -- TODO put CR back in
  Gen.element [CRLF, LF]

genSep :: Gen Char
genSep =
  Gen.element ['|', ',']

genFinalRecord :: Gen spc -> Gen s1 -> Gen s2 -> Gen (FinalRecord spc s1 s2)
genFinalRecord spc s1 s2 =
  FinalRecord <$> Gen.maybe (genNonEmptyRecord spc s1 s2)

genBetween :: Gen spc -> Gen str -> Gen (Between spc str)
genBetween spc str =
  liftA3 Between spc str spc

genQuote :: Gen Quote
genQuote =
  Gen.element [SingleQuote, DoubleQuote]

genEscaped :: Gen a -> Gen (Escaped a)
genEscaped a =
  SeparatedByEscapes <$> Gen.nonEmpty (Range.linear 1 5) a

genQuoted :: Gen a -> Gen (Quoted a)
genQuoted =
  liftA2 Quoted genQuote . genEscaped

genField :: Gen spc -> Gen s1 -> Gen s2 -> Gen (Field spc s1 s2)
genField spc s1 s2 =
  Gen.choice [
    UnquotedF <$> s1
  , QuotedF <$> genBetween spc (genQuoted s2)
  ]

genRecord :: Gen spc -> Gen s -> Gen (Record spc s)
genRecord spc s =
  Record <$> Gen.nonEmpty (Range.linear 1 10) (MonoField <$> genField spc s s)

genNonEmptyRecord :: Gen spc -> Gen s1 -> Gen s2 -> Gen (NonEmptyRecord spc s1 s2)
genNonEmptyRecord spc s1 s2 =
  let f  = genField spc s1 s2
      f' = MonoField <$> genField spc s2 s2
  in  Gen.choice [
    SingleFieldNER <$> f
  , MultiFieldNER <$> f' <*> Gen.nonEmpty (Range.linear 1 10) f'
  ]

genRecords :: Gen spc -> Gen str -> Gen (Records spc str)
genRecords spc str =
  Records <$> genPesarated spc str

genPesarated :: Gen spc -> Gen s -> Gen (Pesarated Newline (Record spc s))
genPesarated spc s =
  let r = genRecord spc s
  in  Pesarated <$> genSeparated r genNewline

genSeparated :: Gen a -> Gen b -> Gen (Separated a b)
genSeparated a b =
  Separated <$> Gen.list (Range.linear 0 100) (liftA2 (,) a b)
