
(*
  * Project: Spike ver 0.1
   * File: misc.ml
   * Content: miscellaneous classes and functions.
*)

(*
   * This abstract class provides an equality predicate.
   * All other classes will inherit from this one.
   * We recall that neither p = q nor p == q when q = Oo.copy p
*)

open Values;;

open Io;;

(* This dummy function can be inserted in the code to trigger
   breakpoints. Defined but not used *)
let dummybreak () = ();;

(* Insertion of an element at the end of a list*)
let list_insert eq_f v =
  let rec fn =
    function
      [] -> [v]
    | h :: t as l -> if eq_f v h then l else h :: fn t
  in
  fn
;;

assert (list_insert ( = ) 3 [1; 2; 4] = [1; 2; 4; 3]);;

assert (list_insert ( = ) 3 [1; 2; 3] = [1; 2; 3]);;

(* Union by eliminating the occurrences. The elements of the first
   list are reversed *)
let list_union eq_f l l' = List.fold_right (list_insert eq_f) l l';;

assert (list_union ( = ) [1; 2; 3] [3; 4; 5] = [3; 4; 5; 2; 1]);;

  (* defined but never used *)
let generic_list_union l l' = list_union ( = ) l l';;

assert (generic_list_union [1; 2; 3] [3; 4; 5] = [3; 4; 5; 2; 1]);;

(* assoc function for sorted lists *)
let ord_assoc eq_f inf_f n l =
  let rec fn =
    function
      [] -> raise Not_found
    | (n', t) :: l ->
        if eq_f n' n then t else if inf_f n n' then raise Not_found else fn l
  in
  fn l
;;

assert (ord_assoc ( = ) ( < ) 3 [1, 2; 2, 4; 3, 5; 4, 6] = 5);;

  (* generic assoc2: assoc for objects on the second projection of a pair  *)

let rec generic_assoc2 eq_f n = function 
    [] -> raise Not_found
  | (c, m) :: t -> if eq_f n m then c
    else generic_assoc2 eq_f n t;;
  
assert (generic_assoc2 (=) 3 [1, 2; 2, 3; 3, 5; 4, 6] = 2);;

(*
   * Insertion in a sorted list.
   * Uses kernel-defined = and < operators
*)
let insert_sorted eq_f inf_f el =
  let rec fn =
    function
      [] -> [el]
    | h :: t as l ->
        if inf_f el h then el :: l else if eq_f el h then l else h :: fn t
  in
  fn
;;

assert (insert_sorted ( = ) ( < ) 3 [1; 2; 3; 4; 5] = [1; 2; 3; 4; 5]);;

assert
  (insert_sorted ( = ) ( < ) 6 [1; 2; 3; 4; 5; 7] = [1; 2; 3; 4; 5; 6; 7]);;

(* Merge sorted lists and eliminates the duplicates *)
let merge_sorted_lists inf_f l1 l2 =
  let rec fn =
    function
      l, [] -> l
    | [], l -> l
    | (h :: t as l), (h' :: t' as l') ->
        if inf_f h h' then h :: fn (t, l')
        else if inf_f h' h then h' :: fn (l, t')
        else h :: fn (t, t')
  in
  fn (l1, l2)
;;

assert (merge_sorted_lists ( < ) [1; 3] [2; 4] = [1; 2; 3; 4]);;

(* The same merge function for multisets. The multiplicity is incremented each time *)
let multiset_merge_sorted_lists eq_f inf_f l1 l2 =
  let rec fn =
    function
      l, [] -> l
    | [], l -> l
    | ((n, h) :: t as l), ((n', h') :: t' as l') ->
        if inf_f h h' then (n, h) :: fn (t, l')
        else if eq_f h h' then (n + n', h) :: fn (t, t')
        else (n', h') :: fn (l, t')
  in
  fn (l1, l2)
;;

assert
  (multiset_merge_sorted_lists ( = ) ( < ) [1, 1; 1, 2; 1, 3] [1, 2; 1, 4] =
     [1, 1; 2, 2; 1, 3; 1, 4]);;

(* Same merge function for (key, val list) sorted list. The argument
   eq_f was not used *)
let assoc_merge_sorted_lists inf_f l1 l2 =
  let rec fn =
    function
      l, [] -> l
    | [], l -> l
    | ((h, n) :: t as l), ((h', n') :: t' as l') ->
        if inf_f h h' then (h, n) :: fn (t, l')
        else if inf_f h' h then (h', n') :: fn (l, t')
        else (h, n @ n') :: fn (t, t')
  in
  fn (l1, l2)
;;

assert
  (assoc_merge_sorted_lists ( < ) [1, [1]; 1, [2]; 1, [3]] [1, [2]; 1, [4]] =
     [1, [1; 2]; 1, [2; 4]; 1, [3]]);;

      (* Same for insertion *)

(* eliminates the duplicates *)
let assoc_insert_sorted eq_f inf_f (k, v) l =
  let rec fn =
    function
      [] -> [k, [v]]
    | (k', l') :: t as l ->
        if inf_f k k' then (k, [v]) :: l
        else if eq_f k k' then (k, v :: l') :: t
        else (k', l') :: fn t
  in
  fn l
;;

assert
  (assoc_insert_sorted ( = ) ( < ) (2, 5) [1, [1]; 2, [2]; 3, [3]] =
     [1, [1]; 2, [5; 2]; 3, [3]]);;

(* For sorted lists and basic keys *)
let assoc_insert eq_f (k, v) l =
  let rec fn =
    function
      [] -> [k, v]
    | (k', l') :: t as l ->
        if k < k' then (k, v) :: l
        else if k = k' then (k, list_union eq_f v l') :: t
        else (k', l') :: fn t
  in
  fn l
;;

assert
  (assoc_insert ( = ) (2, [5]) [1, [1]; 2, [2]; 3, [3]] =
     [1, [1]; 2, [2; 5]; 3, [3]]);;

(* Remove element el from l *)
let remove_sorted equiv_f inf_f el =
  let rec fn =
    function
      [] -> raise Not_found
    | h :: t ->
        if equiv_f el h then t
        else if inf_f el h then raise Not_found
        else let t' = fn t in h :: t'
  in
  fn
;;

assert (remove_sorted ( = ) ( < ) 3 [1; 2; 3; 4; 5] = [1; 2; 4; 5]);;

(* Remove from l elements also in l' *)
let remove_sorted_lists equiv_f inf_f l l' =
  let rec fn =
    function
      l, [] -> l
    | [], _ -> []
    | (h :: t as l), (h' :: t' as l') ->
        if inf_f h h' then h :: fn (t, l')
        else if equiv_f h h' then fn (t, t')
        else fn (l, t')
  in
  fn (l, l')
;;

assert (remove_sorted_lists ( = ) ( < ) [1; 2; 3] [2; 3; 4] = [1]);;

(* Same but fail if an element of l' is not in l *)
let setminus equiv_f inf_f l l' =
  let rec fn =
    function
      l, [] -> l
    | [], _ -> failwith "setminus"
    | (h :: t as l), (h' :: t' as l') ->
        if inf_f h h' then h :: fn (t, l')
        else if equiv_f h h' then fn (t, t')
        else failwith "setminus"
  in
  fn (l, l')
;;

assert (setminus ( = ) ( < ) [1; 2; 3; 4] [2; 3; 4] = [1]);;

(* Remove element el from l according to equivalence predicate equiv_f *)
let remove_el equiv_f el set =
  let rec fn =
    function
      [] -> raise Not_found
    | h :: t -> if equiv_f el h then t else h :: fn t
  in
  fn set
;;

assert (remove_el ( = ) 3 [1; 5; 3; 4] = [1; 5; 4]);;

let unsorted_setminus equiv_f l l' =
  List.fold_left (fun l el -> remove_el equiv_f el l) l l'
;;

assert (unsorted_setminus ( = ) [1; 2; 3; 4] [2; 3; 4] = [1]);;

let unsorted_sloppy_setminus equiv_f l l' =
  List.fold_left
    (fun l el ->
       try remove_el equiv_f el l with
         Not_found -> l)
    l l'
;;

assert (unsorted_sloppy_setminus ( = ) [1; 2; 3; 4] [2; 7; 4; 6; 3] = [1]);;

(* Remove all occurrences of element el from l according to equivalence predicate equiv_f *)
let remove_all_el equiv_f el set =
  let rec fn =
    function
      [] -> []
    | h :: t -> if equiv_f el h then fn t else let t' = fn t in h :: t'
  in
  fn set
;;

assert (remove_all_el ( = ) 5 [1; 3; 4; 5; 3; 5] = [1; 3; 4; 3]);;

(* Intersection of sorted lists *)
let intersection_sorted_lists equiv_f inf_f v v' =
  let rec fn =
    function
      _, [] -> []
    | [], _ -> []
    | (h :: t as l), (h' :: t' as l') ->
        if inf_f h h' then fn (t, l')
        else if equiv_f h h' then h :: fn (t, t')
        else fn (l, t')
  in
  fn (v, v')
;;

assert
  (intersection_sorted_lists ( = ) ( < ) [1; 2; 3; 4] [2; 7; 4; 6; 3] = [2]);;

  (* returns the dif   *)
let what_is_new fn_equiv l l' =  
  let rec member el = function 
      [] -> false
    | h :: t -> if fn_equiv el h then true else member el t
  in
  let subset l l' = 
    List.for_all (fun x -> member x l') l
  in
  (l = []) or not (subset l l')


  (* computes l \ l'  *)
let difference equiv_f l l' = 
  let rec member el = function 
      [] -> false
    | h :: t -> if equiv_f el h then true else member el t
  in
  let _,pnot = List.partition (fun x -> member x l') l in
  pnot
;;

assert (difference (=) [1;2] [3;1;2] = []);;

(* Intersection of sorted lists. We also keep the remaining part of
   the union of the  list. *)
let intersection_and_rest_sorted_lists equiv_f inf_f v v' =
  let rec fn =
    function
      _, [] -> [], []
    | [], l' -> [], l'
    | (h :: t as l), (h' :: t' as l') ->
        if inf_f h h' then let (u, u') = fn (t, l') in u, h :: u'
        else if equiv_f h h' then let (u, u') = fn (t, t') in h :: u, u'
        else let (u, u') = fn (l, t') in u, h' :: u'
  in
  fn (v, v')
;;

assert
  (intersection_and_rest_sorted_lists ( = ) ( < ) [1; 2; 3; 4]
     [2; 7; 4; 6; 3] =
     ([2], [1; 3; 4; 7; 4; 6; 3]));;

(* Subset: based on sublist for sorted lists. is_sublist a b = a \subseteq b *)
let is_subset equiv_f v v' =
  let rec fn =
    function
      [], _ -> true
    | _, [] -> false
    | (h :: t as l), h' :: t' ->
        if equiv_f h h' then fn (t, t') or fn (l, t') else fn (l, t')
  in
  fn (v, v')
;;

assert (is_subset ( = ) [1; 2] [0; 1; 2; 3] = true);;

(* Maximum value over a list *)
let list_max max_f l =
  let fn v =
    let rec fn2 =
      function
        [] -> v
      | h :: t -> max_f h (fn2 t)
    in
    fn2
  in
  match l with
    [] -> failwith "list_max"
  | h :: t -> fn h t
;;

assert (list_max max [1; 5; 3; 3] = 5);;

(* List.member  predicate *)
let rec list_member eq_f e =
  function
    [] -> false
  | h :: t -> if eq_f h e then true else list_member eq_f e t
;;

assert (list_member ( = ) 5 [1; 2; 3; 4; 5] = true);;

(* Remove multiple occurences of an element from a list*)
let rec list_remove_doubles f =
  let rec fn h =
    function
      [] -> []
    | h' :: t' -> if f h h' then fn h t' else h' :: fn h t'
  in
  function
    [] -> []
  | h :: t -> let t' = fn h t in h :: list_remove_doubles f t'
;;

assert (list_remove_doubles ( = ) [1; 2; 2; 3; 3] = [1; 2; 3]);;

(* Same functions for generic operators *)
let generic_ord_assoc l l' = ord_assoc ( = ) ( < ) l l';;

let generic_insert_sorted l l' = insert_sorted ( = ) ( < ) l l';;

let generic_merge_sorted_lists l l' = merge_sorted_lists ( < ) l l';;


(* the lists of pairs l and l' should be sorted on the first component*)
let subst_compose l l' =
  merge_sorted_lists (fun (x, _) (x', _) -> x < x') l l'
;;

assert (subst_compose [1, 2; 1, 3] [1, 2; 2, 5] = [1, 2; 1, 3; 2, 5]);;

let generic_multiset_merge_sorted_lists l l' = merge_sorted_lists ( < ) l l';;

let generic_assoc_merge_sorted_lists l l' =
  assoc_merge_sorted_lists ( = ) l l'
;;

let generic_assoc_insert_sorted el l = assoc_insert_sorted ( = ) ( < ) el l;;

let generic_remove_sorted l l' = remove_sorted ( = ) ( < ) l l';;

let generic_remove_sorted_lists l l' = remove_sorted_lists ( = ) ( < ) l l';;

let generic_setminus l l' = setminus ( = ) ( < ) l l';;

let generic_remove_el l l' = remove_el ( = ) l l';;

let generic_intersection_sorted_lists l l' =
  intersection_sorted_lists ( = ) ( < ) l l'
;;

let generic_intersection_and_rest_sorted_lists l l' =
  intersection_and_rest_sorted_lists ( = ) ( < ) l l'
;;

let generic_is_subset l l' = is_subset ( = ) l l';;

let generic_list_max l = list_max max l;;

let generic_merge_set_of_lists l =
  List.fold_left generic_merge_sorted_lists [] l
;;

let generic_list_object_member e l = list_member (fun x -> x#equal) e l;;

let generic_list_object_remove_doubles l =
  list_remove_doubles (fun x -> x#equal) l
;;

let rec generic_list_sorted_mem i =
  function
    [] -> false
  | h :: t ->
      if i > h then generic_list_sorted_mem i t
      else if i = h then true
      else false
;;

assert (generic_list_sorted_mem 4 [1; 3; 5] = false);;

(* Prints a list into a string:
   elements are s-printed thru dispfun, sep is a separator to be put after all but the last elements *)
let sprint_list sep dispfun l =
  let rec fn =
    function
      [] -> ""
    | [h] -> dispfun h
    | h :: t -> dispfun h ^ sep ^ fn t
  in
  fn l
;;

assert (sprint_list ", " string_of_int [1; 2; 3] = "1, 2, 3");;

let print_list sep dispfun l =
  let rec fn =
    function
      [] -> ()
    | [h] -> dispfun h
    | h :: t -> dispfun h; print_string sep; fn t
  in
  fn l
;;

(* print_list ", " print_int [1;2;3];;
1, 2, 3- : unit = ()  
*)


let print_tab_list l =
  let rec fn i =
    function
      [] -> ()
    | [h] -> print_string (" " ^ string_of_int i ^ ") " ^ h)
    | h :: t ->
        print_string (" " ^ string_of_int i ^ ") " ^ h);
        buffered_output "";
        fn (i + 1) t
  in
  fn 1 l
;;


(* # print_tab_list ["1sdf" ; "asfasd"];;
 1) 1sdf
 2) asfasd- : unit = ()
  *)

let sprint_string_list sep l =
  let rec fn =
    function
      [] -> ""
    | [h] -> h
    | h :: t -> h ^ sep ^ fn t
  in
  fn l
;;

let sprint_int_list = sprint_list ", " string_of_int;;

(* group equivalent terms of a list. The list is sorted *)
let rec list_group eq_f =
  function
    [] -> []
  | h :: t ->
      match list_group eq_f t with
        [] -> [[h]]
      | (hd :: tl as l) :: tl2 ->
          if eq_f h hd then (h :: l) :: tl2 else [h] :: l :: tl2
      | [] :: tl -> [h] :: tl
;;

assert (list_group ( = ) [1; 1; 4; 3] = [[1; 1]; [4]; [3]]);;

  (* defined but not used  *)
let rec lists_sync eq_f inf_f l l' =
  match l, l' with
    [], _ -> [], l'
  | _, [] -> l, []
  | h :: t, h' :: t' ->
      if inf_f h h' then
        let (u, u') = lists_sync eq_f inf_f t l' in h :: u, [] :: u'
      else if eq_f h h' then
        let (u, u') = lists_sync eq_f inf_f t t' in h :: u, h' :: u'
      else let (u, u') = lists_sync eq_f inf_f l t' in [] :: u, h' :: u'
;;

(* Given two lists and a binary predicate p on their elements,
   checks whether a permutation of one of the lists
   fullfills List.for_all2 p l (perm l').
   We do NOT generate all permutations in general

   Make it easier ?
*)
let check_on_permutations pred l l' =
  let rec fn h t l =
    let rec fn2 acc =
      function
        [] -> false
      | h' :: t' ->
          if pred h h' then fn3 (acc @ t') t or fn2 (acc @ [h']) t'
          else fn2 (acc @ [h']) t'
    in
    fn2 [] l
  and fn3 l l' =
    match l, l' with
      [], [] -> true
    | h :: t, _ -> fn h t l'
    | _ -> false
  in
  fn3 l l'
;;

assert (check_on_permutations ( = ) [1; 2; 3] [3; 2; 1] = true);;

(* The same function dedicated to the interface with a matching
   function (carrying a substitution).
   ex is the exception raised when matching fails.
*)
let ac_eq matchfun ex =
  let rec fn s h t l =
    let rec fn2 acc =
      function
        [] -> failwith "ac_eq"
      | h' :: t' ->
          try
            let s' = matchfun s h h' in
            try fn3 s' t (acc @ t') with
              e -> if e = ex then fn2 (acc @ [h']) t' else raise e
          with
            e -> if e = ex then fn2 (acc @ [h']) t' else raise e
    in
    fn2 [] l
  and fn3 s l l' =
    match l, l' with
      [], [] -> s
    | h :: t, _ -> fn s h t l'
    | _ -> failwith "ac_eq"
  in
  fn3
;;

(* We will check whether there exists a partition into 'n' subsets
   that satisfies proceed_fun: 'a list -> sigma 

Defined but not used
*)
let check_on_subsets proceed_fun =
  let rec fn l1 l2 =
    function
      [] -> invalid_arg "check_on_subsets"
    | [h] ->
        let l = (h :: l1) :: l2 in
        let () = buffered_output (sprint_list "\n" sprint_int_list l) in
        let () =
          buffered_output
            "-----------------------------------------------------------"
        in
        let () = flush stdout in failwith "check_on_subsets"
    | h :: t ->
        try fn [] ((h :: l1) :: l2) t with
          Failure "check_on_subsets" -> fn (h :: l1) l2 t
  in
  fn [] []
;;

(* We have a list of list and wish to pick one element of each list to
   satisfy proceed_fun : 'a list -> 'a list 

*)

let check_on_variants proceed_fun =
  let rec fn l =
    function
      [] -> proceed_fun l
    | h :: t -> fn2 l t h
  and fn2 l tl =
    function
      [] -> failwith "check_on_variants"
    | h :: t ->
        try fn (h :: l) tl with
          Failure "check_on_variants" -> fn2 l tl t
  in
  fn []
;;

let rec list_special_exists f ex =
  function
    [] -> raise ex
  | h :: t ->
      try f h with
        e -> if e = ex then list_special_exists f ex t else raise e
;;

(* The same function dedicated to subsumption. Uses idempotency of logical operators. *)
let subsumes proceed_fun matchfun sigma l l' =
  let rec fn s =
    function
      [] -> proceed_fun s
    | h :: t ->
        let proceed_fun' s' = proceed_fun (fn s' t) in
        list_special_exists (matchfun proceed_fun' s h) (Failure "matching")
          l'
  in
  fn sigma l
;;

(* The same function dedicated to the interface with a matching
   function (carrying a substitution). We provide the remaining of the second list
   ex is the exception raised when matching fails. *)
let subsumes_w_rest matchfun ex =
  let rec fn s h t l =
    let rec fn2 acc =
      function
        [] -> failwith "ac_eq"
      | h' :: t' ->
          try let s' = matchfun s h h' in fn3 s' t (acc @ t') with
            e -> if e = ex then fn2 (acc @ [h']) t' else raise e
    in
    fn2 [] l
  and fn3 s l l' =
    match l, l' with
      [], _ -> s, l'
    | h :: t, _ -> fn s h t l'
  in
  fn3
;; 

(* Apply function f to element n of list. The first element has index 0 *)
let apply_f_to_element_n f n =
  let rec fn i =
    function
      [] ->
        if i = 0 then []
        else if i > 0 then failwith "apply_f_to_element_n"
        else invalid_arg "apply_f_to_element_n"
    | h :: t -> if i = 0 then f h :: t else h :: fn (i - 1) t
  in
  fn n
;;

assert (apply_f_to_element_n (fun x -> x + 1) 1 [1; 5] = [1; 6]);;

(* is_included l l' = l C= l'
   Lists are sorted 
   Defined but not used
*)
let is_included eq_f inf_f l l' =
  let rec fn =
    function
      [], [] -> true
    | [], _ -> true
    | _, [] -> false
    | (h :: t as v), h' :: t' ->
        if inf_f h h' then false
        else if eq_f h h' then fn (t, t')
        else fn (v, t')
  in
  fn (l, l')
;;

assert (is_included ( = ) ( < ) [2; 4] [1; 2; 3; 4] = true);;

(* Produces all lists minus one element *)
let extract l =
  let rec fn =
    function
      _, [] -> []
    | p, h :: t -> (h, p @ t) :: fn (p @ [h], t)
  in
  fn ([], l)
;;

assert (extract [1; 2; 3] = [1, [2; 3]; 2, [1; 3]; 3, [1; 2]]);;

(* Returns all couples (x, y) (pos x <> pos y) from a list *)
let all_couples_from_list l =
  let rec fn =
    function
      x, [] -> invalid_arg "all_couples_from_list"
    | x, l -> List.map (fun y -> x, y) l
  in
  List.flatten (List.map fn (extract l))
;;

assert
  (all_couples_from_list [1; 2; 3] = [1, 2; 1, 3; 2, 1; 2, 3; 3, 1; 3, 2]);;

  (* Returns all combinations (x, y) from a list  *)
let rec all_combinations_from_list = 
  function 
      [] -> []
    | [x] -> []
    | h :: t -> (List.map (fun x -> (h, x)) t) @
	all_combinations_from_list t
;;

assert (all_combinations_from_list [1;2;3] = [1, 2; 1, 3; 2, 3]);; 


(* Last element of a list *)
let rec last_el =
  function
    [] -> failwith "last_el"
  | [h] -> h
  | _ :: t -> last_el t
;;

let rec list_all_but_last_el =
  function
    [] -> invalid_arg "list_all_but_last_el"
  | [h] -> []
  | h :: t -> h :: list_all_but_last_el t
;;

assert (list_all_but_last_el [1; 2; 3] = [1; 2]);;

let list_all_but i l =
  let rec fn =
    function
      _, [] -> failwith "list_all_but"
    | 0, h :: t -> t
    | i, h :: t -> h :: fn (i - 1, t)
  in
  if i < 0 then invalid_arg "list_all_but" else fn (i, l)
;;

assert (list_all_but 1 [1; 2; 3; 4] = [1; 3; 4]);;

(* Truncate a list at position n 
Defined, but not used 
*)
let rec list_truncate l n =
  match l, n with
    _, 0 -> []
  | [], _ -> failwith "list_truncate"
  | h :: t, n ->
      if n < 0 then invalid_arg "list_truncate"
      else h :: list_truncate t (n - 1)
;;

assert (list_truncate [1; 2; 3; 4; 5] 3 = [1; 2; 3]);;


(* Transforms a list [ (x0, y0) ; (x1, y1) ... ] into [ x0 ; y0 ; x1 ; y1 ... ] *)
let rec uncouple_list =
  function
    [] -> []
  | (h, h') :: t -> h :: h' :: uncouple_list t
;;

assert (uncouple_list [1, 2; 3, 4] = [1; 2; 3; 4]);;

(* Takes a couple (x, n) and a list. If List.assoc l x = n' then replace n by max n n'
   othewise cons new couple.
   We operate on a sorted list *)
let max_assoc v i =
  let rec fn =
    function
      [] -> [v, i]
    | (h, h') :: t as l ->
        if v = h then (h, max h' i) :: t
        else if v < h then (v, i) :: l
        else (h, h') :: fn t
  in
  fn
;;

assert (max_assoc 1 3 [1, 2; 3, 4] = [1, 3; 3, 4]);;

assert (max_assoc 5 6 [1, 2; 3, 4] = [1, 2; 3, 4; 5, 6]);;

let rec max_assoc_merge l l' =
  match l, l' with
    [], _ -> l'
  | _, [] -> l
  | (h, n) :: t, (h', n') :: t' ->
      if h < h' then (h, n) :: max_assoc_merge t l'
      else if h = h' then (h, max n n') :: max_assoc_merge t t'
      else (h', n') :: max_assoc_merge l t'
;;

assert (max_assoc_merge [1, 2; 2, 3] [1, 3; 2, 5] = [1, 3; 2, 5]);;


(* Takes a list of lists.
   Returns all lists containing one element of each
   Incidentally, it is a naive way to transform dnf into cnf *)
let megamix =
  let rec fn =
    function
      [] -> []
    | [] :: t -> []
    | (hd :: tl) :: t -> fn2 hd t @ fn (tl :: t)
  and fn2 hd =
    function
      [] -> [[hd]]
    | l -> let l' = fn l in List.map (fun x -> hd :: x) l'
  in
  fn
;;

assert
  (megamix [[1; 2]; [3; 4; 5]] =
     [[1; 3]; [1; 4]; [1; 5]; [2; 3]; [2; 4]; [2; 5]]);;

(* We takes two ('a * 'b) sorted lists.
   If two bindings exist for a given key, we keep the greatest.
   We insert all non-shared bindings 
It is identical with max_assoc_merge*)
(* let rec max_on_assoc_lists l l' =
  match l, l' with
    [], _ -> l'
  | _, [] -> l
  | (h, v) :: t, (h', v') :: t' ->
      if h < h' then (h, v) :: max_on_assoc_lists t l'
      else if h = h' then (h, max v v') :: max_on_assoc_lists t t'
      else (h', v') :: max_on_assoc_lists l t'
*)


(* Hack !
   Takes a string. Returns (outside-underscore-free substring, number of left underscores, number of right underscores) *)
let process_underscores s =
  let i = ref 0
  and d = String.length s - 1 in
  let fn () = i := 0; while String.get s !i = '_' do incr i done; !i
  and fn2 () = i := d; while String.get s !i = '_' do decr i done; !i in
  let l_ar = fn ()
  and r_ar = fn2 () in
  let sym = String.sub s l_ar (r_ar - l_ar + 1) in sym, l_ar, d - r_ar
;;

assert (process_underscores "__ArbitraryText___" = ("ArbitraryText", 2, 3));;

(* A type for input files: either stdin or a plain file *)
type ginput = string * in_channel;;

(* Open relevant file descriptor *)
let openin =
  function
    "" -> "", stdin
  | s ->
      s,
      (let () = Printf.printf "Opening %s\n" s in
       let () = flush stdout in open_in s)
;;

(* Close relevant file descriptor *)
let closein (s, fd) =
  match s with
    "" -> ()
  | _ ->
      let () = Printf.printf "Closing %s\n" s in
      let () = flush stdout in close_in fd
;;

(* A general type for pointers *)
type 'a pointer = Undefined | Defined of 'a;;

let pointer_is_defined =
  function
    Undefined -> false
  | Defined _ -> true
;;

let pointer_is_undefined =
  function
    Undefined -> true
  | Defined _ -> false
;;

let defined_content =
  function
    Defined h -> h
  | Undefined -> failwith "defined_content"
;;

let pointer_max v v' =
  match v, v' with
    Defined n, Defined n' -> Defined (max n n')
  | Defined _, _ -> v
  | _, Defined _ -> v'
  | _ -> Undefined
;;

assert (pointer_max (Defined 3) (Defined 5) = Defined 5);;

let pointer_incr =
  function
    Defined n -> Defined (n + 1)
  | Undefined -> Undefined
;;

(* Create a list [ el ; el ; ... el (n times) ] just like Array.init *)
let list_init n el =
  let rec fn =
    function
      0 -> []
    | i -> el :: fn (i - 1)
  in
  if n < 0 then invalid_arg "create_list" else fn n
;;

assert (list_init 5 4 = [4; 4; 4; 4; 4]);;

(* Pop n elements from a stack, puts them in a list (first out is last in the list) *)
let pop_n_times n s =
  let l = ref [] in for i = 1 to n do l := Stack.pop s :: !l done; !l
;;

(* split_list i [ 0 ; 1... i + 1 ; ... n ] -> [ 0 ; 1... i + 1 ], [ ... n ] *)
let rec list_split_at_n n l =
  match n, l with
    0, _ -> [], l
  | _, [] -> failwith "split_list_at_n"
  | n, h :: t -> let (l', l'') = list_split_at_n (n - 1) t in h :: l', l''
;;

assert (list_split_at_n 4 [1; 2; 3; 4; 5; 6; 7] = ([1; 2; 3; 4], [5; 6; 7]));;

(* Same as List.exists 
Defined but not used 
*)
let array_exists p a =
  let len = Array.length a in
  let rec fn i =
    if i = len then false else if p a.(i) then true else fn (i + 1)
  in
  fn 0
;;

(* Checks if l' is a suffix of l in list_suffix l l' *)
let list_is_suffix l l' =
  let rec chop_n_first n l =
    match n, l with
      0, _ -> l
    | _, h :: t -> chop_n_first (n - 1) t
    | _ -> failwith "chop_n_first"
  in
  let len = List.length l
  and len' = List.length l' in
  if len' > len then false
  else
    let () = assert (len - len' <= len = true) in
    chop_n_first (len - len') l = l'
;;

assert (list_is_suffix [1; 2; 3] [2; 3] = true);;

(* Same as map2, but the other way: 1 list and a function produce a couple of lists *)
let rec list_2_2_map f =
  let rec fn =
    function
      [] -> [], []
    | (h, h') :: t ->
        let (h1, h2) = f h h'
        and (l, l') = fn t in
        h1 :: l, h2 :: l'
  in
  fn
;;

assert
  (list_2_2_map (fun x y -> x + 1, y) [1, 1; 2, 2; 3, 3; 4, 4] =
     ([2; 3; 4; 5], [1; 2; 3; 4]));;

(* Replaces element n of list l with el 
Defined but not used
*)
let list_replace_element n el =
  let rec fn i =
    function
      [] -> failwith "list_replace_element"
    | h :: t -> if i = n then el :: t else h :: fn (i + 1) t
  in
  fn 0
;;

(* Replaces element n of list l with list l' 
Defined but not used 
*)
let list_replace_element_w_list n els =
  let rec fn i =
    function
      [] -> failwith "list_replace_element"
    | h :: t -> if i = n then els @ t else h :: fn (i + 1) t
  in
  fn 0
;;

(* Insert element el at place n 
Defined but not used 
*)
let list_insert_at_position n el =
  let rec fn i l =
    match i, l with
      0, [] -> [el]
    | _, [] -> failwith "list_insert_at_position"
    | _, h :: t -> if i = n then el :: l else h :: fn (i + 1) t
  in
  fn 0
;;

(* Takes a list [a;b;c;d;e;f;...] and returns [(a,b);(b,c);...] *)
let rec list_2_list_of_couples =
  function
    h :: h' :: t -> (h, h') :: list_2_list_of_couples (h' :: t)
  | _ -> []
;;

assert (list_2_list_of_couples [1; 2; 3; 4] = [1, 2; 2, 3; 3, 4]);;

(* First returned list contains the maximal elements, second contains the rest. Order is partial. *)
let rec list_select_maximal_elements sup_f =
  let rec fn e =
    function
      [] -> e, [], []
    | h :: t ->
        if sup_f e h then let (m, u, o) = fn e t in m, u, h :: o
        else if sup_f h e then failwith "fn"
        else let (m, u, o) = fn e t in m, h :: u, o
  in
  function
    [] -> [], []
  | h :: t ->
      try
        let (m, u, o) = fn h t in
        let (m', o') = list_select_maximal_elements sup_f u in m :: m', o @ o'
      with
        Failure "fn" ->
          let (m', o') = list_select_maximal_elements sup_f t in m', h :: o'
;;

assert
  (list_select_maximal_elements ( > ) [1; 2; 4; 3; 4; 3; 1] =
     ([4; 4], [1; 2; 3; 3; 1]));;

(* Create a list [ 0 ; 1 ; ... ; (n - 1) ] *)
let list_create n =
  let rec fn i = if i = n then [] else i :: fn (i + 1) in
  if n < 0 then invalid_arg "list_create" else fn 0
;;

assert (list_create 3 = [0; 1; 2]);;

(* Checks that a list contains n times the same element 
Defined but not used 
*)
let list_singleton =
  function
    [] -> true
  | h :: t -> List.for_all (fun x -> x = h) t
;;

(* Gets all leading elements in a list equal to el *)
let rec get_leading_el eq_f el =
  function
    [] -> [], []
  | h :: t as l ->
      if eq_f h el then let (l1, l2) = get_leading_el eq_f el t in h :: l1, l2
      else [], l
;;

assert (get_leading_el ( = ) 3 [3; 2; 3; 4] = ([3], [2; 3; 4]));;

assert (get_leading_el ( = ) 3 [2; 3; 4] = ([], [2; 3; 4]));;

(* Attempt f on the whole list. Also returns true if it succeeded at least once. ex is the exception raised by f
   Mix between List.map and List.exists *)
let list_exists_and_proceed f ex =
  let rec fn =
    function
      [] -> false, []
    | h :: t ->
        try
          let h' = f h
          and (_, t') = fn t in
          true, h' :: t'
        with
          e -> if e = ex then let (b, t') = fn t in b, h :: t' else raise e
  in
  fn
;;

assert
  (list_exists_and_proceed succ (Failure "succ") [0; 0; 0] =
     (true, [1; 1; 1]));;

(* f returns a list now *)
let list_exists_and_proceed_2 f ex =
  let rec fn =
    function
      [] -> false, []
    | h :: t ->
        try
          let h' = f h
          and (_, t') = fn t in
          true, h' @ t'
        with
          e -> if e = ex then let (b, t') = fn t in b, h :: t' else raise e
  in
  fn
;;

assert
  (list_exists_and_proceed_2 (fun x -> [x + 1]) (Failure "succ") [0; 0; 0] =
     (true, [1; 1; 1]));;

(* Remove all elements of the list where f returned true.
   We also have a deletion boolean value *)
let list_remove_true f =
  let rec fn =
    function
      [] -> false, []
    | h :: t ->
        let b = f h
        and (b', t') = fn t in
        if b then true, t' else b', h :: t'
  in
  fn
;;

assert
  (list_remove_true (fun x -> x / 2 * 2 = x) [1; 2; 3; 4] = (true, [1; 3]));;

assert
  (list_remove_true (fun x -> x / 2 * 2 = x) [1; 5; 3; 5] =
     (false, [1; 5; 3; 5]));;

(* Number elements of a list 
Defined but not used 
*)
let list_number_els l =
  let rec fn i =
    function
      [] -> []
    | h :: t -> (i, h) :: fn (i + 1) t
  in
  fn 0 l
;;

(* Get the position of the minimal element in a list *)
let list_position_smallest_el inf_f l =
  let l' = list_number_els l in
  let l'' = Sort.list (fun (_, x) (_, x') -> inf_f x x') l' in
  try fst (List.hd l'') with
    Failure "hd" -> raise Not_found
;;

assert (list_position_smallest_el ( < ) [3; 2; 1; 5] = 2);;

(* Types for jumps within clauses *)
type goto_type = Goto_number of int | Goto_smallest | Goto_greatest;;

(* Existence test, with a predicate using the number of the element *)
let list_exists_w_number p =
  let rec fn i =
    function
      [] -> false
    | h :: t -> p i h or fn (i + 1) t
  in
  fn 0
;;

(* defined but not used  *)
let mstring x = x#string;;

(* prints the binary value of i  *)
let rec print_bitstream i =
  match i with
    0 -> print_int 0
  | 1 -> print_int 1
  | _ -> let i' = i / 2 in print_bitstream i'; let d = i mod 2 in print_int d
;;

let rec power i =
  function
    0 -> 1
  | j -> i * power i (j - 1)
;;

let get_bitstream l =
  let rec fn i =
    function
      [] -> 0
    | h :: t ->
        match h with
          0 -> fn (i + 1) t
        | 1 -> power 2 i + fn (i + 1) t
        | _ -> invalid_arg "get_bitstream"
  in
  let l' = List.rev l in fn 0 l'
;;

assert (get_bitstream [1; 0; 0; 0] = 8);;

(* Put head element of l in last position 
Defined but not used
*)
let list_head_to_tail =
  function
    [] -> failwith "list_head_to_tail"
  | h :: t -> t @ [h]
;;

(* Print a string list in a tabulation box 
Defied but not used 
*)
let rec print_list_tbox =
  function
    [] -> ()
  | [h] -> Format.print_string h
  | h :: t -> Format.print_string h; Format.print_tab (); print_list_tbox t
;;

(* List.assoc, where we provide the second element of the tuple and get the first *)
let rec list_assoc_2 el =
  function
    [] -> raise Not_found
  | (h, h') :: t -> if el = h' then h else list_assoc_2 el t
;;

(* Defined but not used  *)
let repeat f ex t =
  let rec fn t =
    try let t' = f t in fn t' with
      e -> if e = ex then t else raise e
  in
  fn t
;;

let queue_forall f q =
  let rec fn () =
    try
      let t = Queue.take q in if f t then fn () else !continue_mode && fn ()
    with
      Queue.Empty -> true
  in
  fn ()
;;

class virtual generic =
  object ((self : 'a)) method virtual equal : 'a -> bool end;;

class virtual printable_object =
  object ((self : 'a))
    val mutable string = (Undefined : string pointer)
    method string =
      match string with
        Undefined ->
          let s = self#compute_string in let () = string <- Defined s in s
      | Defined s -> s
  end;;

let subset l l' =
  let rec fn x =
    function
      [] -> false
    | h :: t -> if x#syntactic_equal h then true else fn x t
  in
  List.for_all (fun x -> fn x l') l
;;

let do_nothing (s : string) = ();;

let rec n_spaces =
  function
    0 -> ""
  | n -> " " ^ n_spaces (n - 1)
;;

let syntactic_equal x = x#syntactic_equal;;

let matrix_exists f =
  let rec fn =
    function
      [] -> false
    | h :: t -> List.exists f h or fn t
  in
  fn
;;

assert (matrix_exists (fun x -> x / 2 * 2 = x) [[1; 2]; [3; 4]] = true);;

assert (matrix_exists (fun x -> x / 2 * 2 = x) [[1; 3]; [3; 5]] = false);;

let matrix_map f =
  let rec fn =
    function
      [] -> []
    | h :: t -> List.map f h :: fn t
  in
  fn
;;
  

(* Similar to map but raise an exception if the catched exception is 
   different of ex *)
let list_special_map f ex =
  let rec fn =
    function
      [] -> []
    | h :: t ->
        try f h :: fn t with
          e -> if e = ex then (print_string ("\nThe inconsistency has
been produced while treating " ^ h#string ^ "\n\n"); fn t ) else raise e
  in
  fn
;;


(* replaces the even strings in the list with "\n" *)
let rec cat_nonempty_strings =
  function
    [] -> ""
  | [h] -> h
  | h :: h' :: t ->
      let s =
        (match h with
           "" -> ""
         | _ -> h) ^
          (match h' with
             "" -> ""
           | _ -> "\n")
      in
      s ^ cat_nonempty_strings t
;;

assert (cat_nonempty_strings ["1"; "sdfsd"; "r3f"] = "1\nr3f");;

  (* gcd computes the greatest common divisor of two integers *)
let rec gcd x y = 
  if x * y = 0 then failwith "gcd"
  else
    let max_xy = max x y in
    let min_xy = min x y in 
    if max_xy - min_xy = 0 then min_xy
    else gcd (max_xy - min_xy) min_xy;;

(* lcm computes the least common multiplier of two integers  *)
let lcm x y = x * y / gcd x y;;

  (* tests if s is a substring of s'  *)
let substring s s' =
  let ls = String.length s in
  let ls' = String.length s' in
  let rec fn = function
    | n -> 
	if n < ls then false
      	else 
	  if s = String.sub s' (ls' - n) ls 
      	  then true 
	  else fn (n - 1)
  in
  if ls > ls' then false else fn ls' 
;;


assert (substring "asd" "fasdasf" = true);;

let print_indent_string s = 
  if !maximal_output
  then buffered_output (!indent_string ^ s)
  else ()
