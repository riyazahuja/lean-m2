import LeanM2.defs
import LeanM2.parser
import LeanM2.toM2
import LeanM2.M2Type
import Lean.PrettyPrinter.Delaborator.Basic
import Mathlib.Tactic.Use
import Mathlib.Tactic.Polyrith
import LeanM2.Expr2Expr
import Mathlib.FieldTheory.Finite.GaloisField
import Mathlib.Algebra.Algebra.ZMod
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.RingTheory.Ideal.Quotient.Defs
import Mathlib.LinearAlgebra.ExteriorAlgebra.Basic

open Lean Meta Elab Tactic Conv Qq
open Std.Internal.Parsec Std.Internal.Parsec.String



namespace ZModM2


-- alias M2ZMod := ZMod

structure M2ZMod (p : Nat) where
  val : ZMod p



instance {p} : M2Type (ZMod p) (M2ZMod p) where
  toLean e := (e.val : (ZMod p))


-- #check M2Type (ZMod 3) _




instance {p} : M2Repr (M2ZMod p) where
  repr := s!"ZZ/{p}"

def toString' {p} (r : M2ZMod p) : String := --MIGHT NEED TO UPDATE WITH ++"_R"
  match p with
  | 0 =>
    let r' : ℤ := r.val
    ToString.toString r'
  | n+1 =>
    let r' : Fin (n+1) := r.val
    ToString.toString r'

instance {p} : ToString (M2ZMod p) where
  toString r :=  toString' r




open Qq in
def M2ZMod.toLeanExpr {p} : (M2ZMod p) → Lean.Expr → MetaM Lean.Expr := fun r => fun f =>
  match p with
  | 0 => do
    let r' : ℤ := r.val
    pure q($r')
  | n+1 => do
    let r' : Fin (n+1) := r.val
    pure q($r')

instance {p} : ToLeanExpr (M2ZMod p) where
  toLeanExpr := M2ZMod.toLeanExpr

#check ((7 : ℤ) :ZMod 6)

def M2ZMod.parse {p}: (Parser (M2ZMod p)) := do
    let s ← manyChars (satisfy fun c => c.isDigit || c == '-')
    match s.toInt? with
    | some i =>
      let i' :ZMod p:= @Int.cast (ZMod p) AddGroupWithOne.toIntCast i
      pure (⟨i'⟩ : M2ZMod p)
    | none => fail s!"Could not parse '{s}' as an integer"


instance {p} : Unrepr (M2ZMod p) where
  parse := M2ZMod.parse

instance {p : Nat}: parseableRepr s!"ZZ/{p}" where
  R := ZMod p
  M2R := M2ZMod p
  inst_M2Type := inferInstance
  parse := M2ZMod.parse


end ZModM2



open Polynomial
variable (x y : ℚ)
#check (x^2 : (ℚ ⧸ (Ideal.span {x^2} : Ideal ℚ)))

namespace QuotM2




structure M2Ideal (R : Type)  where
  generators : List R

instance : Inhabited (M2Ideal R) where
  default := ⟨[]⟩

def M2Ideal.toIdeal {R M2R} [Ring R] [DecidableEq R] [M2Type R M2R] (I : M2Ideal M2R) : Ideal R :=
  Ideal.span ((I.generators.map (fun e => M2Type.toLean e)).toFinset.toSet)

@[data_synth out M2I]
structure LiftM2Ideal {R M2R} [Ring R] [DecidableEq R] [M2Type R M2R] (I : Ideal R) (M2I : M2Ideal M2R) : Prop where
  to_ideal : M2I.toIdeal = I


section
variable {R M2R : Type} [Ring R] [DecidableEq R] [typeInst : M2Type R M2R] [liftInst :M2LifterInv R M2R]

@[data_synth out generators]
structure IsM2Ideal (I : Ideal R) (generators : List M2R) : Prop where
  eq : I = Ideal.span (generators.map (fun g => M2Type.toLean g)).toFinset.toSet


@[data_synth]
theorem isM2Ideal_nil : IsM2Ideal (Ideal.span ({} : Set R)) ([] : List M2R) := by
  constructor
  congr
  simp



@[data_synth]
theorem isM2Id_singleton (g : R) --(hg : M2Type.toLean ge = g)
  : IsM2Ideal (Ideal.span (Singleton.singleton g)) [M2LifterInv.fromLean g] := by
  constructor
  congr
  simp
  have duh (f : R → R) : (f = id) → f g = g := by
    intro h
    rw [h]
    simp
  specialize duh (M2Type.toLean ∘ M2LifterInv.fromLean) (@M2LifterInv.fact R M2R typeInst liftInst)
  exact id (Eq.symm duh)


  --exact id (Eq.symm hg)



@[data_synth]
theorem isM2Id_insert (g : R) --(hg : M2Type.toLean ge = g)
(rest : Set R) (hrest : IsM2Ideal (Ideal.span rest) restList)
  : IsM2Ideal (Ideal.span (insert g rest)) ((M2LifterInv.fromLean g) :: restList) := by
  constructor
  simp only [List.map_cons, List.toFinset_cons,Finset.coe_insert,Ideal.span_insert, hrest.1]
  congr
  have duh (f : R → R) : (f = id) → f g = g := by
    intro h
    rw [h]
    simp
  specialize duh (M2Type.toLean ∘ M2LifterInv.fromLean) (@M2LifterInv.fact R M2R typeInst liftInst)
  exact id (Eq.symm duh)





open Classical in
@[data_synth]
theorem lift_M2Ideal (I : Ideal R) {generators} (hI : IsM2Ideal I generators) :
    LiftM2Ideal I ⟨generators⟩ where
  to_ideal := by
    simp_all[IdExpr.toIdeal,hI.1, M2Type.toLean, M2Ideal.toIdeal]







def M2Ideal.toString [ToString M2R] (I : M2Ideal M2R) : String :=
  s!"ideal({",".intercalate (I.generators.map (fun e => ToString.toString e))})"

instance [ToString M2R] : ToString (M2Ideal M2R) where
  toString I := I.toString

def toM2Ideal (I : Ideal R) {M2I} (hx : LiftM2Ideal I M2I := by data_synth) :
  M2Ideal M2R := M2I

--Need to make/synthesize inverse fn s.t. for an m2type R,M2R
-- we have an inverse of toLean that goes R -> M2R.
-- Then we can explicitly synthesize/construct "ge" and this will work

set_option trace.Meta.Tactic.data_synth true
#check toM2Ideal (Ideal.span {(1:ℚ)})



-- class M2Ideal' (I : Ideal R) (M2I : M2Ideal M2R) where
--   toLean : M2I → I

-- instance (I : Ideal R) {M2I} (hx :  LiftM2Ideal I M2I := by data_synth) : M2Ideal' I M2I where
--   toLean := sorry

end


def M2Quot (R:Type*) {M2R} [CommRing R] (I:Ideal R)
  [DecidableEq R] [M2Type R M2R] --{M2I} [LiftM2Ideal I M2I]
  : Type :=
  M2R


-- variable (R:Type*) {M2R} [CommRing R] (I:Ideal R)
--   [DecidableEq R] [M2Type R M2R] --{M2I} [LiftM2Ideal I M2I]

def M2Quot.toLean {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] (e : M2Quot R I) : R ⧸ I :=
  let e' : R := M2Type.toLean (e : M2R)
  (Ideal.Quotient.mk I) e'



instance {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] : M2Type (R ⧸ I) (M2Quot R I) where
  toLean e := e.toLean


instance {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R]
  [M2Repr M2R] [ToString M2R] {M2I} (hx :  LiftM2Ideal I M2I := by data_synth)
  : M2Repr (M2Quot R I) where
  repr :=
    let repr_M2R := M2Repr.repr M2R
    let repr_M2I := M2I.toString
    s!"({repr_M2R})/({repr_M2I})"




instance {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] [ToString M2R] : ToString (M2Quot R I) where
  toString r :=
    let r' : M2R := r
    ToString.toString r'


open Qq in
partial def M2Quot.toLeanExpr {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] [ToLeanExpr M2R]: (M2Quot R I) → Lean.Expr → MetaM Lean.Expr := fun r => fun f => do
  -- i think we just need to convert r into R ⧸ I in leanExpr?
  let r' ← toLeanExpr r f
  mkAppM ``M2Quot.toLean #[r'] -- double check coecersion rules on this, might need r' to be of M2Quot not M2R


instance {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] [ToLeanExpr M2R] : ToLeanExpr (M2Quot R I) where
  toLeanExpr := M2Quot.toLeanExpr


def M2Quot.parse {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] [inst : Unrepr M2R]
  : (Parser (M2Quot R I)) := @Unrepr.parse M2R inst


instance {R:Type*} {M2R} [CommRing R] {I:Ideal R}
  [DecidableEq R] [M2Type R M2R] [Unrepr M2R] : Unrepr (M2Quot R I) where
  parse := M2Quot.parse

-- instance {p : Nat}: parseableRepr s!"ZZ/{p}" where
--   R := ZMod p
--   M2R := M2ZMod p
--   inst_M2Type := inferInstance
--   parse := M2ZMod.parse

--should work sufficiently for

end QuotM2
