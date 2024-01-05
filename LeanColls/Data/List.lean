/- Copyright (c) 2023 James Gallicchio.

Authors: James Gallicchio
-/

import Mathlib.Data.List.Lemmas

namespace List

theorem ofFn_def (f : Fin n → α)
  : ofFn f = (Array.ofFn f).data := by
  rw [←Array.toList_eq]; rfl

def getCons? : List α → Option (α × List α)
| [] => none
| x::xs => some (x,xs)

@[simp] theorem getCons?_eq_none (c : List α) : getCons? c = none ↔ c = [] := by
  cases c <;> simp [getCons?]

@[simp] theorem getCons?_eq_some (c : List α) : getCons? c = some (x,xs) ↔ c = x :: xs := by
  cases c <;> simp [getCons?]

@[simp] def snoc (L : List α) (x : α) := L ++ [x]

def getSnoc? : List α → Option (List α × α)
| [] => none
| x::xs =>
  match getSnoc? xs with
  | none => some ([],x)
  | some (xs',x') => some (x::xs', x')

@[simp] theorem getSnoc?_eq_none (c : List α) : getSnoc? c = none ↔ c = [] := by
  induction c <;> simp_all [getSnoc?]
  intro h; split at h <;> simp_all

@[simp] theorem getSnoc?_eq_some (c : List α) : getSnoc? c = some (xs,x) ↔ c = xs ++ [x] := by
  induction c generalizing xs x <;> simp_all [getSnoc?]
  case cons hd tl ih =>
  generalize ho : getSnoc? tl = o at ih
  cases o <;> simp_all
  · cases xs <;> simp
  · cases xs <;> simp_all
    · rintro rfl rfl; simp_all; apply ih; rfl
    · aesop; rw [←ih]; simp

theorem ext_get_iff (L₁ L₂ : List α) (h : L₁.length = L₂.length)
  : L₁ = L₂ ↔ ∀ i h1 h2, L₁.get ⟨i,h1⟩ = L₂.get ⟨i, h2⟩
  := by
  constructor
  · rintro rfl; simp
  · apply ext_get h

theorem get_eq_get (L1 L2 : List α) (i : Fin L1.length) (j : Fin L2.length) :
  L1 = L2 → i.val = j.val → L1.get i = L2.get j
  := by cases i; cases j; rintro rfl h; simp at h; cases h; rfl
