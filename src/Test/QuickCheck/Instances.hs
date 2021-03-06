{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleContexts #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
{-| 
Instances are provided for the types in the packages:

 * array

 * bytestring

 * text

 * containers

 * old-time

 * time

Since all of these instances are provided as orphans, I recommend that
you do not use this library within another library module, so that you
don't impose these instances on down-stream consumers of your code.

For information on writing a test-suite with Cabal see
<http://www.haskell.org/cabal/users-guide/#test-suites>
-}
module Test.QuickCheck.Instances () where

import Control.Applicative
import Data.Foldable (toList)
import Data.Int (Int32)
import Test.QuickCheck

import qualified Data.Array.IArray as Array
import qualified Data.Array.Unboxed as Array
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.Fixed as Fixed
import qualified Data.IntMap as IntMap
import qualified Data.IntSet as IntSet
import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as TS
import qualified Data.Text.Lazy as TL
import qualified Data.Time as Time
import qualified Data.Time.Clock.TAI as Time
import qualified Data.Tree as Tree
import qualified System.Time as OldTime

import Test.QuickCheck.Instances.LegacyNumeric()

-- Array

instance (Array.Ix i, Arbitrary i, Arbitrary e) => Arbitrary (Array.Array i e) where
    arbitrary = arbitraryArray
    shrink    = shrinkArray

instance (Array.IArray Array.UArray e, Array.Ix i, Arbitrary i, Arbitrary e)
        => Arbitrary (Array.UArray i e) where
    arbitrary = arbitraryArray
    shrink    = shrinkArray

instance (Array.Ix i, CoArbitrary i, CoArbitrary e) => CoArbitrary (Array.Array i e) where
    coarbitrary = coarbitraryArray

instance (Array.IArray Array.UArray e, Array.Ix i, CoArbitrary i, CoArbitrary e)
        => CoArbitrary (Array.UArray i e) where
    coarbitrary = coarbitraryArray

arbitraryArray :: (Array.IArray a e, Array.Ix i, Arbitrary i, Arbitrary e) => Gen (a i e)
arbitraryArray = do
      b1 <- arbitrary
      b2 <- arbitrary
      let bounds =
              if b1 < b2 then (b1,b2) else (b2,b1)
      elms <- vector (Array.rangeSize bounds)
      return $ Array.listArray bounds elms

shrinkArray :: (Array.IArray a e, Array.Ix i, Arbitrary i, Arbitrary e) => a i e -> [a i e]
shrinkArray a =
    -- Shrink each elements but don't change the size of array.
    let bounds = Array.bounds a
        elmss  = shrink <$> Array.elems a
    in Array.listArray bounds <$> elmss

coarbitraryArray :: (Array.IArray a e, Array.Ix i, CoArbitrary i, CoArbitrary e)
                    => a i e -> Gen c -> Gen c
coarbitraryArray = coarbitrary . Array.assocs

-- ByteString
instance Arbitrary BS.ByteString where
    arbitrary = BS.pack <$> arbitrary
    shrink xs = BS.pack <$> shrink (BS.unpack xs)

instance Arbitrary BL.ByteString where
    arbitrary = BL.pack <$> arbitrary
    shrink xs = BL.pack <$> shrink (BL.unpack xs)

instance CoArbitrary BS.ByteString where
    coarbitrary = coarbitrary . BS.unpack

instance CoArbitrary BL.ByteString where
    coarbitrary = coarbitrary . BL.unpack

-- Text
instance Arbitrary TS.Text where
    arbitrary = TS.pack <$> arbitrary
    shrink xs = TS.pack <$> shrink (TS.unpack xs)

instance Arbitrary TL.Text where
    arbitrary = TL.pack <$> arbitrary
    shrink xs = TL.pack <$> shrink (TL.unpack xs)

instance CoArbitrary TS.Text where
    coarbitrary = coarbitrary . TS.unpack

instance CoArbitrary TL.Text where
    coarbitrary = coarbitrary . TL.unpack

-- Containers
instance Arbitrary a => Arbitrary (IntMap.IntMap a) where
    arbitrary = IntMap.fromList <$> arbitrary
    shrink m = IntMap.fromList <$> shrink (IntMap.toList m)

instance CoArbitrary a => CoArbitrary (IntMap.IntMap a) where
    coarbitrary = coarbitrary . IntMap.toList

instance Arbitrary IntSet.IntSet where
    arbitrary = IntSet.fromList <$> arbitrary
    shrink set = IntSet.fromList <$> shrink (IntSet.toList set)

instance CoArbitrary IntSet.IntSet where
    coarbitrary = coarbitrary . IntSet.toList

instance (Ord k, Arbitrary k, Arbitrary v) => Arbitrary (Map.Map k v) where
    arbitrary = Map.fromList <$> arbitrary
    shrink m = Map.fromList <$> shrink (Map.toList m)

instance (CoArbitrary k, CoArbitrary v) => CoArbitrary (Map.Map k v) where
    coarbitrary = coarbitrary . Map.toList

instance Arbitrary a => Arbitrary (Seq.Seq a) where
    arbitrary = Seq.fromList <$> arbitrary
    shrink xs = Seq.fromList <$> shrink (toList xs)

instance CoArbitrary a => CoArbitrary (Seq.Seq a) where
    coarbitrary = coarbitrary . toList

instance (Ord a, Arbitrary a) => Arbitrary (Set.Set a) where
    arbitrary = Set.fromList <$> arbitrary
    shrink set = Set.fromList <$> shrink (Set.toList set)

instance CoArbitrary a => CoArbitrary (Set.Set a) where
    coarbitrary = coarbitrary . Set.toList

instance Arbitrary a => Arbitrary (Tree.Tree a) where
    arbitrary = sized $ \n ->
      do val <- arbitrary
         let n' = n `div` 2
         nodes <- 
             if n' > 0
              then do
                k <- choose (0,n')
                resize n' $ sequence [ arbitrary | _ <- [1..k] ]
              else return []
         return $ Tree.Node val nodes
    shrink (Tree.Node val forest) =
        Tree.Node <$> shrink val <*> shrink forest

instance CoArbitrary a => CoArbitrary (Tree.Tree a) where
    coarbitrary (Tree.Node val forest) =
        coarbitrary val >< coarbitrary forest

-- old-time
instance Arbitrary OldTime.Month where
    arbitrary = arbitraryBoundedEnum

instance CoArbitrary OldTime.Month where
    coarbitrary = coarbitraryEnum

instance Arbitrary OldTime.Day where
    arbitrary = arbitraryBoundedEnum

instance CoArbitrary OldTime.Day where
    coarbitrary = coarbitraryEnum

instance Arbitrary OldTime.ClockTime where
    arbitrary =
        OldTime.TOD <$> choose (0, fromIntegral (maxBound :: Int32))
                    <*> choose (0, 1000000000000 - 1)
    shrink (OldTime.TOD s p) =
        [ OldTime.TOD s' p  | s' <- shrink s ] ++
        [ OldTime.TOD s  p' | p' <- shrink p ]

instance CoArbitrary OldTime.ClockTime where
    coarbitrary (OldTime.TOD s p) =
        coarbitrary s >< coarbitrary p

instance Arbitrary OldTime.TimeDiff where
    -- a bit of a cheat ...
    arbitrary =
        OldTime.normalizeTimeDiff <$>
           (OldTime.diffClockTimes <$> arbitrary <*> arbitrary)
    shrink td@(OldTime.TimeDiff year month day hour minute second picosec) =
        [ td { OldTime.tdYear    = y' } | y' <- shrink year    ] ++
        [ td { OldTime.tdMonth   = m' } | m' <- shrink month   ] ++
        [ td { OldTime.tdDay     = d' } | d' <- shrink day     ] ++
        [ td { OldTime.tdHour    = h' } | h' <- shrink hour    ] ++
        [ td { OldTime.tdMin     = m' } | m' <- shrink minute  ] ++
        [ td { OldTime.tdSec     = s' } | s' <- shrink second  ] ++
        [ td { OldTime.tdPicosec = p' } | p' <- shrink picosec ]

instance CoArbitrary OldTime.TimeDiff where
    coarbitrary (OldTime.TimeDiff year month day hour minute second picosec) =
        coarbitrary year    ><
        coarbitrary month   ><
        coarbitrary day     ><
        coarbitrary hour    ><
        coarbitrary minute  ><
        coarbitrary second  ><
        coarbitrary picosec

-- UTC only
instance Arbitrary OldTime.CalendarTime where
    arbitrary = OldTime.toUTCTime <$> arbitrary

instance CoArbitrary OldTime.CalendarTime where
    coarbitrary (OldTime.CalendarTime
                        year month day hour minute second picosec
                        wDay yDay tzName tz isDST) =
        coarbitrary year    ><
        coarbitrary month   ><
        coarbitrary day     ><
        coarbitrary hour    ><
        coarbitrary minute  ><
        coarbitrary second  ><
        coarbitrary picosec ><
        coarbitrary wDay    ><
        coarbitrary yDay    ><
        coarbitrary tzName  ><
        coarbitrary tz      ><
        coarbitrary isDST

-- time
instance Arbitrary Time.Day where
    arbitrary = Time.ModifiedJulianDay <$> (2000 +) <$> arbitrary
    shrink    = (Time.ModifiedJulianDay <$>) . shrink . Time.toModifiedJulianDay

instance CoArbitrary Time.Day where
    coarbitrary = coarbitrary . Time.toModifiedJulianDay

instance Arbitrary Time.UniversalTime where
    arbitrary = Time.ModJulianDate <$> (2000 +) <$> arbitrary
    shrink    = (Time.ModJulianDate <$>) . shrink . Time.getModJulianDate

instance CoArbitrary Time.UniversalTime where
    coarbitrary = coarbitrary . Time.getModJulianDate

instance Arbitrary Time.DiffTime where
    arbitrary = arbitrarySizedFractional
#if MIN_VERSION_time(1,3,0)
    shrink    = shrinkRealFrac
#else
    shrink    = (fromRational <$>) . shrink . toRational
#endif

instance CoArbitrary Time.DiffTime where
    coarbitrary = coarbitraryReal

instance Arbitrary Time.UTCTime where
    arbitrary =
        Time.UTCTime
        <$> arbitrary
        <*> (fromRational . toRational <$> choose (0::Double, 86400))
    shrink ut@(Time.UTCTime day dayTime) =
        [ ut { Time.utctDay     = d' } | d' <- shrink day     ] ++
        [ ut { Time.utctDayTime = t' } | t' <- shrink dayTime ]

instance CoArbitrary Time.UTCTime where
    coarbitrary (Time.UTCTime day dayTime) =
        coarbitrary day >< coarbitrary dayTime

instance Arbitrary Time.NominalDiffTime where
    arbitrary = arbitrarySizedFractional
    shrink    = shrinkRealFrac

instance CoArbitrary Time.NominalDiffTime where
    coarbitrary = coarbitraryReal

instance Arbitrary Time.TimeZone where
    arbitrary =
        Time.TimeZone
         <$> choose (-12*60*60,12*60*60) -- utc offset (s)
         <*> arbitrary -- is summer time
         <*> (sequence . replicate 4 $ choose ('A','Z'))
    shrink tz@(Time.TimeZone minutes summerOnly name) =
        [ tz { Time.timeZoneMinutes    = m' } | m' <- shrink minutes    ] ++
        [ tz { Time.timeZoneSummerOnly = s' } | s' <- shrink summerOnly ] ++
        [ tz { Time.timeZoneName       = n' } | n' <- shrink name       ]

instance CoArbitrary Time.TimeZone where
    coarbitrary (Time.TimeZone minutes summerOnly name) =
        coarbitrary minutes >< coarbitrary summerOnly >< coarbitrary name

instance Arbitrary Time.TimeOfDay where
    arbitrary =
        Time.TimeOfDay
         <$> choose (0, 23) -- hour
         <*> choose (0, 59) -- minute
         <*> (fromRational . toRational <$> choose (0::Double, 60)) -- picoseconds, via double
    shrink tod@(Time.TimeOfDay hour minute second) =
        [ tod { Time.todHour = h' } | h' <- shrink hour   ] ++
        [ tod { Time.todMin  = m' } | m' <- shrink minute ] ++
        [ tod { Time.todSec  = s' } | s' <- shrink second ]

instance CoArbitrary Time.TimeOfDay where
    coarbitrary (Time.TimeOfDay hour minute second) =
        coarbitrary hour >< coarbitrary minute >< coarbitrary second

instance Arbitrary Time.LocalTime where
    arbitrary =
        Time.LocalTime
         <$> arbitrary
         <*> arbitrary
    shrink lt@(Time.LocalTime day tod) =
        [ lt { Time.localDay       = d' } | d' <- shrink day ] ++
        [ lt { Time.localTimeOfDay = t' } | t' <- shrink tod ]

instance CoArbitrary Time.LocalTime where
    coarbitrary (Time.LocalTime day tod) =
        coarbitrary day >< coarbitrary tod

instance Arbitrary Time.ZonedTime where
    arbitrary =
        Time.ZonedTime
         <$> arbitrary
         <*> arbitrary
    shrink zt@(Time.ZonedTime lt zone) =
        [ zt { Time.zonedTimeToLocalTime = l' } | l' <- shrink lt   ] ++
        [ zt { Time.zonedTimeZone        = z' } | z' <- shrink zone ]

instance CoArbitrary Time.ZonedTime where
    coarbitrary (Time.ZonedTime lt zone) =
        coarbitrary lt >< coarbitrary zone

instance Arbitrary Time.AbsoluteTime where
    arbitrary =
        Time.addAbsoluteTime
         <$> arbitrary
         <*> return Time.taiEpoch
    shrink at =
        (`Time.addAbsoluteTime` at) <$> shrink (Time.diffAbsoluteTime at Time.taiEpoch)

instance CoArbitrary Time.AbsoluteTime where
    coarbitrary = coarbitrary . flip Time.diffAbsoluteTime Time.taiEpoch

-- WARNING: from base, should be moved to QC library
instance Arbitrary Ordering where
    arbitrary = arbitraryBoundedEnum

instance CoArbitrary Ordering where
    coarbitrary = coarbitraryEnum

instance Fixed.HasResolution a => Arbitrary (Fixed.Fixed a) where
    arbitrary = arbitrarySizedFractional
    shrink    = shrinkRealFrac

instance Fixed.HasResolution a => CoArbitrary (Fixed.Fixed a) where
    coarbitrary = coarbitraryReal

-- WARNING: should be moved to QC library
arbitraryBoundedEnum :: (Bounded a, Enum a) => Gen a
arbitraryBoundedEnum =
  do let mn = minBound
         mx = maxBound `asTypeOf` mn
     n <- choose (fromEnum mn, fromEnum mx)
     return (toEnum n `asTypeOf` mn)

coarbitraryEnum :: Enum a => a -> Gen c -> Gen c
coarbitraryEnum = variant . fromEnum
