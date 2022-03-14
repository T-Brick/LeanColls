/-
Copyright (c) 2021 James Gallicchio.

Authors: James Gallicchio
-/

import LeanColls.Classes
import LeanColls.Range

namespace LeanColls

structure Slice (C) (τ : outParam (Type u)) [Indexed C τ] where
  c : C
  off : Nat
  len : Nat
  h_range : off + len ≤ Indexed.size c

instance [Indexed C τ] : Indexed (Slice C τ) τ where
  size S := S.len
  nth S (i : Fin S.len) := Indexed.nth S.c ⟨S.off + i, Nat.le_trans (Nat.add_lt_add_left i.isLt _) (Slice.h_range S)⟩

def IndexedEq [DecidableEq τ] [Indexed C₁ τ] [Indexed C₂ τ] (c₁ : C₁) (c₂ : C₂)
  {h : Indexed.size c₁ = Indexed.size c₂} : Prop :=
  ∀ i, Indexed.nth c₁ i = Indexed.nth c₂ ⟨i.val, by rw [←h]; exact i.isLt⟩

class IndexedOps (C) (τ : outParam (Type u)) where
  slice [Indexed C τ] (off len : Nat) (c : C)
    {h : off + len ≤ Indexed.size c} : Slice C τ

instance [Indexed C τ] : Inhabited (IndexedOps C τ) where
  default := {
    slice := λ off len c h => ⟨c,off,len,h⟩
  }

end LeanColls
