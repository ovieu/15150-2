(* ---------------------------------------------------------------------- *)
(* Optional Block World Tasks

   In the following code there are some TODO's. For each of these TODO's, you
   need to replace the exceptions and english text with your datatype
   constructor.
*)

fun stepMany (moves : move list, s : state) : state option =
    case moves of
        [] => SOME s
      | m :: ms => (case step (m,s) of NONE => NONE | SOME s' => stepMany (ms , s'))

local

fun parseBlock (s : string) : block option =
    case s of
        (* Replace raise Fail "block _" with your block constructors *)
        "X" => SOME (X)
      | "Y" => SOME (Y)
      | "Z" => SOME (Z)
      | _ => NONE

fun parseMove (s : string) : move option =
    case String.tokens (fn x => x = #" ") s of
        [ "pickup" , x , "from" , "table" ] =>
            (case parseBlock x of
                 (* Replace raise Fail "_" with the constructor that
                  * represents the specified move
                  *)
                 SOME b => SOME (Pickup_from_table b)
               | NONE => NONE)
      | [ "put" , x , "on" , "table" ] =>
            (case parseBlock x of
                 SOME b => SOME (Put_on_table b)
               | NONE => NONE)
      | [ "pickup" , x , "from" , y ] =>
             (case (parseBlock x,parseBlock y) of
                 (SOME a,SOME b) => SOME (Pickup_from_block (a, b))
               | _ => NONE)
      | [ "put" , x , "on" , y ] =>
            (case (parseBlock x,parseBlock y) of
                 (SOME a,SOME b) => SOME(Put_on_block (a, b))
               | _ => NONE)
      | _ => NONE

local
    fun enumerateBlocksOnTable (s : state) : block list =
        List.map (fn f => case f of
                    On_table b => b
                  (* TODO add a case for fact 'b is on the table' => b *)
                   |_ => raise Fail "impossible")
        (List.filter (fn f => case f of
                       On_table b => true
                      (* TODO add a case for fact 'b is on the table' => true *)
                      |_ => false) s)

    type tower = block list
    fun tower (s : state, sofar : block list, cur : block) : tower =
        case extract ((fn f => case f of
                              On (a, b) => b = cur
                               (* TODO add a case for fact 'a is on b' => b = cur *)
                             |_ => false), s) of
            NONE => sofar
          | SOME (On (a, b), s') => tower(s', a::sofar, a)
          (* TODO add a case for SOME ('a is on b',s') => tower (s' , a :: sofar , a) *)
          | SOME _ => raise Fail "impossible"

    fun getBlockInHand (s : state) : block option =
        case List.find (fn x => case x of
                                   (* TODO add a case for fact 'the hand holds b' => true *)
                                   Hand_holding b => true
                                   |_ => false) s of
            (*TODO add a case for SOME ('the hand holds b') => SOME b *)
           SOME (Hand_holding b) => SOME b
          | SOME _ => raise Fail "impossible"
          | NONE => NONE

    fun showBlock (b : block) : string list =
        let fun square s = ["---",
                           "|"^s^"|",
                            "---"]
        in
            case b of
                X => square "X"
              | Y => square "Y"
              | Z => square "Z"
        end

    (********** Do not modify code below **********)

    (* each elt of the resulting list has length 3 *)
    fun showTower (t : tower) : string list = List.foldr (fn (b,y) => showBlock b @ y) [] t

    (* output is rectangular *)
    fun showTowers (ts : tower list, inhand : block option) : string list list =
        let val tstrings = List.map showTower ts
            val maxlen = List.foldr Int.max 0 (List.map List.length tstrings)

            val (tstrings',maxlen') = case inhand of
                                       NONE => (tstrings,maxlen)
                                     | SOME b => ((("/|\\" :: showBlock b) @ (List.tabulate (maxlen, fn _ => "   ")))
                                                  :: tstrings, maxlen + 4)
            fun pad t = (List.tabulate (maxlen' - List.length t, fn _ => "   ")) @ t
        in
            List.foldr (fn (t,tstrs) => pad t :: List.tabulate (maxlen', fn _ => "   ") :: tstrs) [] tstrings'
        end

in
    fun showState (s : state) : string =
        let val towers = (List.map (fn b => tower (s,[b],b)) (enumerateBlocksOnTable s))
            val lines = (List.map String.concat (transpose (showTowers (towers, getBlockInHand s))))
        in
            "\n" ^ (List.foldr (fn (s,s') => s ^ "\n" ^ s')
                               (String.concat (List.tabulate (25, fn _ => "-")))
                               lines) ^ "\n"
        end
end

fun loop (s : state) : unit =
    let val () = print (showState s)
        val () = print "Next move: "
    in
        case (TextIO.inputLine TextIO.stdIn) of
            NONE => (print "no input\n"; loop s)
          | SOME "quit\n" => ()
          | SOME input =>
                (case parseMove (String.substring (input,0,String.size input - 1)) of
                     NONE => (print "Move did not parse\n"; loop s)
                   | SOME m => (case step (m,s) of
                                    NONE => (print "Cannot make that move\n"; loop s)
                                  | SOME s' => loop s'))
    end

val help = "\nPossible moves:\n" ^
           "  pickup <block> from table\n" ^
           "  put <block> on table\n" ^
           "  pickup <block> from <block>\n" ^
           "  put <block> on <block>\n" ^
           "  quit\n"
in
    fun playBlocks() = let val () = print help in loop initial end
end
