
(** 
    Cette partie du programme NE DOIT EN AUCUN CAS être modifiée sous peine
    de voir votre code ne pas passer les tests 
*)
type instruction = (* représentation d'une instruction reçu *)
  | Left (* Déplacement du curseur vers la gauche *)
  | Right (* Déplacement du curseur vers la droite *)
  | Write of char (* Écriture du caractère sur le ruban *)
  | Repeat of (int * instruction list) (* Repeter n fois la liste d'instructions *)
  | Caesar of int (* Caesar n à partir de la phase 3Aiens *)
  | Delete of char (* Delete(a) suppression du caractère a du message à partir de la phase 3Aiens *)
  | Invert (* Invert : retournement du message  à partir de la phase 3Aiens *)
  
type program = instruction list (* Un programme est simplement une liste d'instruction *)

(**
   VOUS N'AVEZ PAS BESOIN DE LIRE OU DE COMPRENDRE CETTE PARTIE DU CODE (LES SIX FONCTIONS SUIVANTES). 
   ELLE EST VOLONTAIREMENT NON COMMENTÉE ET RÉDIGÉE DE MANIÈRE PEU CLAIRE 
 *)
let rec analyse_comment fd =
  let c = Scanf.bscanf fd "%c" (fun c -> c) in
  if c = '\n'
  then ()
  else analyse_comment fd
             
let rec analyse_program_aux =
  fun fd lvl  ->
  try 
    let c = Scanf.bscanf fd "%c" (fun a  -> a) in
    if c = '#'
    then
      let _ = analyse_comment fd in
      analyse_program_aux fd lvl
    else if c = ';' || c = '\n' || c = ' '
    then analyse_program_aux fd lvl
    else if c = ']'
    then
      if lvl > 0
      then []
      else raise (Invalid_argument "Error on char ]")
    else if c = 'W'
      then
        let i= Write(Scanf.bscanf fd "(%c)" (fun a -> a)) in
        let li = analyse_program_aux fd lvl in
        i::li
    else if c = 'C'
      then
        let i= Caesar(Scanf.bscanf fd "(%d)" (fun a -> a)) in
        let li = analyse_program_aux fd lvl in
        i::li
    else if c = 'D'
    then
      let a = Scanf.bscanf fd "(%c)" (fun a -> a) in 
      let i= Delete(a) in
      let li = analyse_program_aux fd lvl in
      i::li
    else if c = 'R'
    then let li = analyse_program_aux fd lvl in
         Right::li
    else if c = 'I'
    then Invert::analyse_program_aux fd lvl
    else if c = 'L'
    then Left::analyse_program_aux fd lvl
    else if c = 'F'
    then
      let n = Scanf.bscanf fd "(%d,[" (fun n -> n) in
      let l = analyse_program_aux fd (lvl + 1) in
      let c = Scanf.bscanf fd "%c" (fun a -> a) in
      if c <> ')' then raise (Invalid_argument ("Error found '"^String.make 1 c^"' instead of ')'"))
      else
        let li = analyse_program_aux fd lvl in
        Repeat(n,l)::li
    else
      let _ = Format.printf  "ERROR '%c' (%d)@." c (Char.code c) in
      assert false
  with End_of_file -> []

let rec read_file_aux =
  fun acc fd ->
  try
    let c = Scanf.bscanf fd "%c" (fun x -> x) in
    read_file_aux (c::acc) fd
  with End_of_file -> acc

let read_file file =
  try
    if Sys.is_directory file
    then raise (Invalid_argument "is a directory")
    else
      let fd = Scanf.Scanning.open_in file in 
      List.rev (read_file_aux [] fd)
  with exc ->
    Format.fprintf Format.err_formatter "Problème à l'ouverture du fichier %s (exception %s)@." file (Printexc.to_string exc);
    exit 127

                    
let rec fprintf_instruction fmt i =
  match i with
  | Write c -> Format.fprintf fmt "W(%c)" c
  | Right -> Format.fprintf fmt "R"
  | Left -> Format.fprintf fmt "L"
  | Repeat(n,li) ->
     Format.fprintf fmt "F(%d,[%a])" n (fun fmt li -> List.iter (fun i -> Format.fprintf fmt "%a;" fprintf_instruction i) li) li
  | Caesar n -> Format.fprintf fmt "C(%d)" n
  | Delete(a) -> Format.fprintf fmt "D(%c)" a
  | Invert -> Format.fprintf fmt "I"
            
let fprintf_program fmt l =
  List.iter (fun i -> Format.fprintf fmt "%a;" fprintf_instruction i) l

(*** 
     Retour au côté clair
*)


(* 
   [print_program] : program -> unit 
   affiche un [program] sur la sortie standard de l'executable
 *)  
let print_program p = Format.printf "%a" fprintf_program p

(*
  [analyse_program] : unit -> program
  Lit un programme 1Aien ou 2Aien, l'analyse et le retourne sous forme d'une valeur de type [program]
 *)                    
let analyse_program file =
  try
    if Sys.is_directory file
    then raise (Invalid_argument "is a directory")
    else
      let fd = Scanf.Scanning.open_in file in 
      analyse_program_aux fd 0
  with exc ->
    Format.fprintf Format.err_formatter "Problème à l'ouverture du fichier %s (exception %s)@." file (Printexc.to_string exc);
    exit 127

(** Votre code doit commencer à partir de ce point.

    NE MODIFIER RIEN AU DESSUS DE CE POINT 
*)

type ruban = { left  : char list; right : char list; }

           
let execute_program pr = 
  let rec execute_instruction i rub = match i with
  | Left -> { left = List.tl rub.left; right = List.hd rub.left::rub.right }
  | Right -> { left = List.hd rub.right::rub.left; right = List.tl rub.right }
  | Write c -> if rub.left = [] then { left = [c]; right = rub.right } else { left = c::(List.tl rub.left); right = rub.right }
  | Caesar n -> { left = (List.map (fun c -> Char.chr (((Char.code c) - 65 + n) mod 26 + 65)) rub.left) ; right = rub.right }
  | Delete c -> { left = List.filter (fun x -> x <> c) rub.left ;  right = List.filter (fun x -> x <> c) rub.right }
  | Invert ->{ left = List.rev rub.left; right = List.rev rub.right }
  | Repeat(n,li) -> begin
      let rec repeat n li rub = match n with
        | 0 -> rub
        | n -> repeat (n-1) li (execute_list li rub)
      in
        repeat n li rub
    end
and execute_list li rub = match li with
  | [] -> rub
  | i::li -> execute_list li (execute_instruction i rub)
in
  execute_list pr { left = []; right = ['0'] }

let rec fold_ruban f v0 r = match r with
  | { left = []; right = [] } -> v0
  | { left = []; right = c::r } -> fold_ruban f (f v0 c) { left = []; right = r }
  | { left = c::l; right = r } -> fold_ruban f (f v0 c) { left = l; right = r }

let generate_program msg = failwith "TODO"
                      
(** Votre code doit s'arreter à partir de ce point.

    NE MODIFIER RIEN EN DESSOUS DE CE POINT 
 *)              
                         
let die i = 
  let _ = Format.fprintf Format.err_formatter "Usage: %s <1|2|3> <file>@." Sys.argv.(0) in
  exit i
  
let main phase file =
  if phase = "1" || phase = "2"
  then
    let li = analyse_program file in
    let rub = execute_program li in
    let _ = fold_ruban (fun _ c -> Format.printf "%c" c) () rub in
    Format.printf "@."
  else if phase = "3"
  then
    let msg = read_file file in
    let p = generate_program msg in
    print_program p
  else die 1


let _ =
  if Array.length Sys.argv = 3 
  then
    main Sys.argv.(1) Sys.argv.(2)
  else die 2
