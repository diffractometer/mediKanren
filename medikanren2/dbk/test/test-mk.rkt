#lang racket/base
(require "../dbk.rkt" racket/function racket/list racket/pretty racket/set)
(print-as-expression #f)
(pretty-print-abbreviate-read-macros #f)

(define (sort/any xs) (sort xs any<?))

(define-syntax-rule (test name e expected)
  (begin (printf "Testing ~s:\n" name)
         (let ((answer e))
           (unless (equal? answer expected)
             (pretty-print 'e)
             (printf "FAILED ~s:\n" name)
             (printf "  ANSWER:\n")
             (pretty-print answer)
             (printf "  EXPECTED:\n")
             (pretty-print expected)))))

(test 'appendo.forward
  (run* z (appendo '(1 2 3) '(4 5) z))
  '((1 2 3 4 5)))
(test 'appendo.backward
  (run* (x y) (appendo x y '(1 2 3 4 5)))
  '((() (1 2 3 4 5))
    ((1) (2 3 4 5))
    ((1 2) (3 4 5))
    ((1 2 3) (4 5))
    ((1 2 3 4) (5))
    ((1 2 3 4 5) ())))
(test 'appendo.aggregate.1
  (run* (x y xsum)
    (appendo x y '(1 2 3 4 5))
    (:== xsum (x)
         (foldl + 0 x)))
  '((() (1 2 3 4 5)  0)
    ((1) (2 3 4 5)   1)
    ((1 2) (3 4 5)   3)
    ((1 2 3) (4 5)   6)
    ((1 2 3 4) (5)  10)
    ((1 2 3 4 5) () 15)))
(test 'appendo.aggregate.2
  (run* (x y xparts)
    (appendo x y '(1 2 3 4 5))
    (:== xparts (x)
         (run* (a b) (appendo a b x))))
  '((() (1 2 3 4 5) ((() ())))
    ((1) (2 3 4 5)  ((() (1))
                     ((1) ())))
    ((1 2) (3 4 5)  ((() (1 2))
                     ((1) (2))
                     ((1 2) ())))
    ((1 2 3) (4 5)  ((() (1 2 3))
                     ((1) (2 3))
                     ((1 2) (3))
                     ((1 2 3) ())))
    ((1 2 3 4) (5)  ((() (1 2 3 4))
                     ((1) (2 3 4))
                     ((1 2) (3 4))
                     ((1 2 3) (4))
                     ((1 2 3 4) ())))
    ((1 2 3 4 5) () ((() (1 2 3 4 5))
                     ((1) (2 3 4 5))
                     ((1 2) (3 4 5))
                     ((1 2 3) (4 5))
                     ((1 2 3 4) (5))
                     ((1 2 3 4 5) ())))))
(test 'appendo.aggregate.1.swapped
  (run* (x y xsum)
    (:== xsum (x)
         (foldl + 0 x))
    (appendo x y '(1 2 3 4 5)))
  '((() (1 2 3 4 5)  0)
    ((1) (2 3 4 5)   1)
    ((1 2) (3 4 5)   3)
    ((1 2 3) (4 5)   6)
    ((1 2 3 4) (5)  10)
    ((1 2 3 4 5) () 15)))
(test 'appendo.aggregate.2.swapped
  (run* (x y xparts)
    (:== xparts (x)
         (run* (a b) (appendo a b x)))
    (appendo x y '(1 2 3 4 5)))
  '((() (1 2 3 4 5) ((() ())))
    ((1) (2 3 4 5)  ((() (1))
                     ((1) ())))
    ((1 2) (3 4 5)  ((() (1 2))
                     ((1) (2))
                     ((1 2) ())))
    ((1 2 3) (4 5)  ((() (1 2 3))
                     ((1) (2 3))
                     ((1 2) (3))
                     ((1 2 3) ())))
    ((1 2 3 4) (5)  ((() (1 2 3 4))
                     ((1) (2 3 4))
                     ((1 2) (3 4))
                     ((1 2 3) (4))
                     ((1 2 3 4) ())))
    ((1 2 3 4 5) () ((() (1 2 3 4 5))
                     ((1) (2 3 4 5))
                     ((1 2) (3 4 5))
                     ((1 2 3) (4 5))
                     ((1 2 3 4) (5))
                     ((1 2 3 4 5) ())))))

(define-relation/table (tripleo i x y z)
  'key-name        'i
  'source-stream   '((a b c)
                     (d e f)
                     (g h i)))

(test 'tripleo.all
  (run* (i x y z) (tripleo i x y z))
  '((0 a b c) (1 d e f) (2 g h i)))
(test 'tripleo.filter-before
  (run* (i x y z)
    (conde ((== y 'e))
           ((== x 'g)))
    (tripleo i x y z))
  '((1 d e f) (2 g h i)))
(test 'tripleo.filter-before.key
  (run* (i x y z)
    (conde ((== y 'e))
           ((== x 'g))
           ((== i 3))
           ((== i 0)))
    (tripleo i x y z))
  '((1 d e f) (2 g h i) (0 a b c)))
(test 'tripleo.filter-before.key-only
  (run* (i x y z)
    (conde ((== y 'e))
           ((== x 'g))
           ((== i 3))
           ((== i 0)))
    (tripleo i x y z)
    (== i 0))
  '((0 a b c)))
(test 'tripleo.filter-after
  (run* (i x y z)
    (tripleo i x y z)
    (conde ((== i 0))
           ((== z 'i))))
  '((0 a b c) (2 g h i)))

(define-relation/table triple2o
  'attribute-names '(x y z)
  'tables          '((y z x))
  'indexes         '((x))
  'source-stream   '((a b  0)
                     (a b  1)
                     (a b  2)
                     (a b  3)
                     (a c  4)
                     (a c  5)
                     (a c  6)
                     (b a  7)
                     (b d  8)
                     (b f  9)
                     (b q 10)
                     (c a 11)
                     (c d 12)))

(test 'triple2o.all
  (run* (x y z) (triple2o x y z))
  '((0  a b)
    (1  a b)
    (2  a b)
    (3  a b)
    (4  a c)
    (5  a c)
    (6  a c)
    (7  b a)
    (8  b d)
    (9  b f)
    (10 b q)
    (11 c a)
    (12 c d)))

(test 'triple2o.filter
  (list->set
    (run* (x y z)
      (conde ((== y 'a) (== z 'c))
             ((== y 'a) (== z 'd))
             ((== x '8))
             ((== y 'b) (== x '12))
             ((== y 'b) (== z 'f) (== x '9))
             ((== y 'b) (== z 'g) (== x '9))
             ((== y 'c))
             ((== y 'd)))
      (triple2o x y z)))
  (list->set
    '((4 a c)
      (5 a c)
      (6 a c)
      (8 b d)
      (9 b f)
      (11 c a)
      (12 c d))))

(test '=/=.atom.1
  (run* x (=/= 1 x))
  '(#s(cx (term: #s(var 0)) (constraints: (=/= #s(var 0) 1)))))
(test '=/=.atom.2
  (run* x (=/= x 2))
  '(#s(cx (term: #s(var 0)) (constraints: (=/= #s(var 0) 2)))))

(test '=/=.atom.==.1
  (run* x (== x 1) (=/= x 1))
  '())
(test '=/=.atom.==.2
  (run* x (=/= x 2) (== x 2))
  '())
(test '=/=.atom.==.3
  (run* x (=/= x 3) (== x 'not-3))
  '(not-3))
(test '=/=.atom.==.4
  (run* x (== x 'not-4) (=/= x 4))
  '(not-4))

(test '=/=.var.==.1
  (run* x
    (fresh (y)
      (=/= x y)
      (== x 1)
      (== y 1)))
  '())
(test '=/=.var.==.2
  (run* x
    (fresh (y)
      (== x 2)
      (== y 2)
      (=/= x y)))
  '())
(test '=/=.var.==.3
  (run* x
    (fresh (y)
      (== x 3)
      (=/= x y)
      (== y 3)))
  '())
(test '=/=.var.==.4
  (run* x
    (fresh (y z)
      (=/= x 4)
      (== x y)
      (== y z)
      (== z 4)))
  '())
(test '=/=.var.==.5
  (run* x
    (fresh (y z)
      (=/= x 5)
      (== y z)
      (== x y)
      (== z 5)))
  '())
(test '=/=.var.==.6
  (run* x
    (fresh (y)
      (=/= x y)
      (== x y)))
  '())
(test '=/=.var.==.7
  (run* x
    (fresh (y)
      (=/= x y)
      (== y x)))
  '())

(test '=/=.pair.==.1
  (run* x
    (=/= x '(1 . 2))
    (==  x '(1 . 2)))
  '())
(test '=/=.pair.==.2
  (run* x
    (fresh (y)
      (=/= x `(1 . ,y))
      (==  x `(1 . 2))
      (==  y 2)))
  '())
(test '=/=.pair.==.3
  (run* x
    (fresh (y)
      (==  x `(1 . 2))
      (=/= x `(1 . ,y))
      (==  y 2)))
  '())
(test '=/=.pair.==.4
  (run* x
    (fresh (y)
      (==  x `(1 . 2))
      (==  y 2)
      (=/= x `(1 . ,y))))
  '())
(test '=/=.pair.==.5
  (run* x
    (fresh (y)
      (=/= x `(1 . ,y))
      (==  y 2)
      (==  x `(1 . 2))))
  '())
(test '=/=.pair.==.6
  (run* x
    (fresh (y)
      (=/= `(,x .  1) `(0 . ,y))
      (==  `(,x . ,y) '(0 .  1))))
  '())
(test '=/=.pair.==.7
  (run* x
    (fresh (y)
      (==  `(,x . ,y) '(0 .  1))
      (=/= `(,x .  1) `(0 . ,y))))
  '())

(test '=/=.pair.=/=.1
  (run* x
    (=/= x '(1 . 2))
    (==  x '(0 . 2)))
  '((0 . 2)))
(test '=/=.pair.=/=.2
  (run* x
    (fresh (y)
      (=/= x `(1 . ,y))
      (==  x `(1 . 2))
      (==  y 0)))
  '((1 . 2)))
(test '=/=.pair.=/=.3
  (run* x
    (fresh (y)
      (==  x `(1 . 2))
      (=/= x `(1 . ,y))
      (==  y 0)))
  '((1 . 2)))
(test '=/=.pair.=/=.4
  (run* x
    (fresh (y)
      (==  x `(1 . 2))
      (==  y 0)
      (=/= x `(1 . ,y))))
  '((1 . 2)))
(test '=/=.pair.=/=.5
  (run* x
    (fresh (y)
      (=/= x `(1 . ,y))
      (==  y 0)
      (==  x `(1 . 2))))
  '((1 . 2)))
(test '=/=.pair.=/=.6
  (run* x
    (fresh (y)
      (=/= `(,x .  1) `(0 . ,y))
      (==  `(,x . ,y) '(0 .  2))))
  '(0))
(test '=/=.pair.=/=.7
  (run* x
    (fresh (y)
      (==  `(,x . ,y) '(0 .  2))
      (=/= `(,x .  1) `(0 . ,y))))
  '(0))

(test '=/=.fresh.1
  (run* x
    (fresh (y)
      (=/= y 1)))
  '(#s(cx (term: #s(var 0)) (constraints:))))
(test '=/=.fresh.2
  (run* x
    (fresh (y)
      (=/= x 0)
      (=/= y 1)))
  '(#s(cx (term: #s(var 0)) (constraints: (=/= #s(var 0) 0)))))
(test '=/=.fresh.3
  (run* x
    (fresh (y)
      (=/= x 0)
      (=/= x y)))
  '(#s(cx (term: #s(var 0)) (constraints: (=/= #s(var 0) #s(var 1))
                                  (=/= #s(var 0) 0)))))
(test '=/=.fresh.4
  (run* (x y)
    (fresh (z)
      (=/= `(,x . ,y) '(0 . 2))
      (=/= z 1)))
  '(#s(cx (term: (#s(var 0) #s(var 1))) (constraints: (=/= #s(var 0) 0)))
    #s(cx (term: (#s(var 0) #s(var 1))) (constraints: (=/= #s(var 1) 2)))))
(test '=/=.fresh.5
  (run* (x y)
    (fresh (z)
      (=/= `(,x ,y ,z) '(0 1 2))))
  '(#s(cx (term: (#s(var 0) #s(var 1))) (constraints: (=/= #s(var 0) 0)))
    #s(cx (term: (#s(var 0) #s(var 1))) (constraints: (=/= #s(var 1) 1)))
    #s(cx (term: (#s(var 0) #s(var 1))) (constraints:))))

(test 'membero.forward
  (run* () (membero 3 '(1 2 3 4 3 5)))
  '(()))
(test 'membero.backward
  (run* x (membero x '(1 2 3 4 3 5)))
  '(1 2 3 4 5))
(test 'not-membero.forward
  (run* () (not-membero 0 '(1 2 3 4 5)))
  '(()))
(test 'not-membero.backward
  (run* x (not-membero x '(1 2 3 4 5)) (== x 0))
  '(0))
(test 'uniqueo.1
  (run* () (uniqueo '(1 2 3 4 5)))
  '(()))
(test 'uniqueo.2
  (run* () (uniqueo '(1 2 3 4 2)))
  '())
(test 'removeo.forward
  (run* x (removeo '3 '(1 2 3 4 5) x))
  '((1 2 4 5)))
(test 'removeo.backward
  (run* x (removeo x '(1 2 3 4 5) '(1 2 4 5)))
  '(3))


;; More table testing

(define intersected-lists
  '(((-1 0 no)
     (-1 1 no)
     (-1 2 no)
     (-1 3 no)
     (-1 4 no)
     (-1 5 no)
     (-1 6 no)
     (-1 7 no)
     (-1 8 no)
     (-1 9 no)

     (1 1 a0)
     (1 2 b0)
     (1 5 c0)
     (3 4 d0)
     (3 8 e0)
     (3 8 e0.1)
     (3 8 e0.2)

     (4 0 no)
     (4 1 no)
     (4 2 no)
     (4 3 no)
     (4 4 no)
     (4 5 no)
     (4 6 no)
     (4 7 no)
     (4 8 no)
     (4 9 no)

     (6 0 f0)
     (6 3 g0)
     (6 5 h0)
     (7 0 i0)
     (7 2 j0)
     (7 4 k0)
     (7 6 l0)
     (7 8 m0)
     (7 9 n0)
     (9 1 0)
     (9 1 o0)
     (9 2 p0)
     (9 5 q0))
    ((-1 0 no)
     (-1 1 no)
     (-1 2 no)
     (-1 3 no)
     (-1 4 no)
     (-1 5 no)
     (-1 6 no)
     (-1 7 no)
     (-1 8 no)
     (-1 9 no)

     (1 1 a1)
     (1 2 b1)
     (2 5 c1)  ; 0
     (2 4 d1)  ; 0
     (3 8 e1)
     (3 8 e1.1)
     (6 0 f1)
     (6 3 g1)
     (6 5 h1)
     (7 0 i1)
     (7 3 j1)  ; 1
     (7 4 k1)
     (7 6 l1)
     (8 8 m1)  ; 0
     (8 9 n1)  ; 0
     (9 1 o1)
     (9 1 o1.1)
     (9 4 p1)  ; 1
     (9 5 q1))
    (;(-1 0 no)
     ;(-1 1 no)
     ;(-1 2 no)
     ;(-1 3 no)
     ;(-1 4 no)
     ;(-1 5 no)
     ;(-1 6 no)
     ;(-1 7 no)
     ;(-1 8 no)
     ;(-1 9 no)

     (0 1 a2)  ; 0
     (1 3 b2)  ; 1
     (1 5 c2)  ; 1
     (2 4 d2)
     (3 8 e2)
     (5 0 f2)  ; 0
     (6 3 g2)
     (6 5 h2)
     (7 0 i2)
     (7 3 j2)
     (7 4 k2)
     (7 4 k2.1)
     (7 6 l2)
     (8 8 m2)
     (8 9 n2)
     (9 1 o2)
     (9 4 p2)
     (9 5 q2)

     (10 1 no)
     (10 0 no)
     (10 2 no)
     (10 3 no)
     (10 4 no)
     (10 5 no)
     (10 6 no)
     (10 7 no)
     (10 8 no)
     (10 9 no)
     )))

(define intersected-tables
  (map (lambda (i s)
         (relation/table
           'relation-name   (string->symbol (format "intersected-table.~v" i))
           'attribute-names '(i n m x)
           'key-name        'i
           'source-stream   s))
       (range (length intersected-lists))
       intersected-lists))

(test 'table-ref
  (map (lambda (R) (run* (n m x) (R 0 n m x))) intersected-tables)
  '(((-1 0 no)) ((-1 0 no)) ((0 1 a2))))

(test 'table-intersection
  (sort/any
    (run* (n m a b c)
      (foldl (lambda (g0 g) (fresh () g g0)) (== #t #t)
             (map (lambda (v R) (fresh (i) (R i n m v))) (list a b c)
                  intersected-tables))))
  (sort/any
    '((3 8 e0   e1   e2)
      (3 8 e0   e1.1 e2)
      (3 8 e0.1 e1   e2)
      (3 8 e0.1 e1.1 e2)
      (3 8 e0.2 e1   e2)
      (3 8 e0.2 e1.1 e2)
      (6 3 g0   g1   g2)
      (6 5 h0   h1   h2)
      (7 0 i0   i1   i2)
      (7 4 k0   k1   k2)
      (7 4 k0   k1   k2.1)
      (7 6 l0   l1   l2)
      (9 1 0    o1   o2)
      (9 1 0    o1.1 o2)
      (9 1 o0   o1   o2)
      (9 1 o0   o1.1 o2)
      (9 5 q0   q1   q2))))

(test '<=.1
  (run* n
    (membero n '(0 1 2 3 4 5 6 7 8 9))
    (<=o 2 n)
    (<o  n 8))
  '(2 3 4 5 6 7))
(test '<=.2
  (run* n
    (<=o 2 n)
    (<o  n 8)
    (membero n '(0 1 2 3 4 5 6 7 8 9)))
  '(2 3 4 5 6 7))
(test '<=.3
  (run* n
    (<o  n 8)
    (<=o 2 n)
    (membero n '(0 1 2 3 4 5 6 7 8 9)))
  '(2 3 4 5 6 7))
(test 'any<=.fd.1
  (run* x
    (any<=o '(#t . #f) x)
    (any<=o x '#(())))
  '((#t . #f)
    (#t . #t)
    #()
    #(())))
(test 'any<=.fd.2
  (run* x
    (any<=o '(#f . #f) x)
    (any<=o x '(#t . ())))
  '((#f . #f)
    (#f . #t)
    (#t . ())))
(test 'any<=.fd.3
  (run* x
    (any<=o '#(5 #f #f #f) x)
    (any<=o x '#(5 #f #t ())))
  '(#(5 #f #f #f)
    #(5 #f #f #t)
    #(5 #f #t ())))
(test 'any<=.fd.4
  (run* x
    (any<=o '#(#f #t #f) x)
    (any<=o x '#(#t () ())))
  '(#(#f #t #f)
    #(#f #t #t)
    #(#t () ())))
(test 'any<=.fd.5
  (run* x
    (any<=o '#(#t #t #f) x)
    (any<=o x '#(() () () ())))
  '(#(#t #t #f)
    #(#t #t #t)
    #(() () () ())))
(test 'any<=.cycle.0
  (run* (a b c)
    (any<=o a b)
    (any<=o b c)
    (any<=o c a))
  '(#s(cx (term: (#s(var 0) #s(var 0) #s(var 0))) (constraints:))))
(test 'any<=.cycle.1
  (run* (a b c d e)
    (any<=o a b)
    (any<=o b c)
    (any<=o c d)
    (any<=o d e)
    (any<=o e a))
  '(#s(cx (term: (#s(var 0) #s(var 0) #s(var 0) #s(var 0) #s(var 0))) (constraints:))))
(test 'any<=.cycle.2
  (run* (a b c d e)
    (=/= b d)
    (any<=o a b)
    (any<=o b c)
    (any<=o c d)
    (any<=o d e)
    (any<=o e a))
  '())
(test 'any<=.cycle.3
  (run* (a b c d e)
    (any<=o a b)
    (any<=o b c)
    (any<=o c d)
    (any<=o d e)
    (any<=o e a)
    (=/= b d))
  '())
(test 'any<=.cycle.4
  (run* (a b c d e f)
    (any<=o a b)
    (any<=o b c)
    (any<=o c d)
    (any<=o d e)
    (any<=o e f)
    (any<=o d b))
  '(#s(cx (term: (#s(var 0) #s(var 1) #s(var 1) #s(var 1) #s(var 2) #s(var 3)))
          (constraints:
            (any<=o #s(var 0) #s(var 1))
            (any<=o #s(var 1) #s(var 2))
            (any<=o #s(var 2) #s(var 3))))))
(test 'any<.transitive.1
  (run* (x y z)
    (any<=o x y)
    (any<=o y z)
    (=/= x y)
    (=/= y z))
  '(#s(cx (term: (#s(var 0) #s(var 1) #s(var 2)))
          (constraints:
            (() <  #s(var 1) <= #f)
            (() <  #s(var 2) <= #t)
            (() <= #s(var 0) <  #f)
            (=/= #s(var 0) #s(var 1))
            (=/= #s(var 1) #s(var 2))
            (any<=o #s(var 0) #s(var 1))
            (any<=o #s(var 1) #s(var 2))))))
(test 'any<.transitive.2
  (run* (x y z)
    (=/= x y)
    (=/= y z)
    (any<=o x y)
    (any<=o y z))
  '(#s(cx (term: (#s(var 0) #s(var 1) #s(var 2)))
          (constraints:
            (() <  #s(var 1) <= #f)
            (() <  #s(var 2) <= #t)
            (() <= #s(var 0) <  #f)
            (=/= #s(var 0) #s(var 1))
            (=/= #s(var 1) #s(var 2))
            (any<=o #s(var 0) #s(var 1))
            (any<=o #s(var 1) #s(var 2))))))
(test 'any<.transitive.3
  (run* (x y z)
    (any<=o y z)
    (any<=o x y)
    (=/= x y)
    (=/= y z))
  '(#s(cx (term: (#s(var 0) #s(var 1) #s(var 2)))
          (constraints:
            (() <  #s(var 1) <= #f)
            (() <  #s(var 2) <= #t)
            (() <= #s(var 0) <  #f)
            (=/= #s(var 0) #s(var 1))
            (=/= #s(var 1) #s(var 2))
            (any<=o #s(var 0) #s(var 1))
            (any<=o #s(var 1) #s(var 2))))))
(test 'any<.transitive.4
  (run* (x y z)
    (=/= x y)
    (=/= y z)
    (any<=o y z)
    (any<=o x y))
  '(#s(cx (term: (#s(var 0) #s(var 1) #s(var 2)))
          (constraints:
            (() <  #s(var 1) <= #f)
            (() <  #s(var 2) <= #t)
            (() <= #s(var 0) <  #f)
            (=/= #s(var 0) #s(var 1))
            (=/= #s(var 1) #s(var 2))
            (any<=o #s(var 0) #s(var 1))
            (any<=o #s(var 1) #s(var 2))))))

(define-relation/table (edge a b)
  'source-stream '((1 2)
                   (2 4)
                   (1 3)
                   (3 5)
                   (2 6)
                   (1 1)
                   (3 6)
                   (6 4)))
(define-relation (path* a c)
  (conde ((edge a c))
         ((fresh (b)
            (edge a b)
            (path* b c)))))
(define-relation (path2* a c)
  (conde ((edge a c))
         ((fresh (b)
            (edge b c)
            (path2* a b)))))
(define-relation (path3* a c)
  (conde ((edge a c))
         ((fresh (b)
            (=/= b c)
            (=/= a b)  ; this filters out some duplicates
            (edge b c)
            (path3* a b)))))

(test 'edge.0
  (run* (x y) (edge x y))
  '((1 1) (1 2) (1 3) (2 4) (2 6) (3 5) (3 6) (6 4)))
(test 'edge.1
  (run* y (edge 2 y))
  '(4 6))
(test 'edge.2
  (run* x (edge x 6))
  '(2 3))

(test 'path*.0
  (run* (x y) (path* x y))
  '((1 1)
    (1 2)
    (1 3)
    (2 4)
    (2 6)
    (3 5)
    (3 6)
    (6 4)
    (1 4)
    (1 6)
    (1 5)
    (1 6)
    (2 4)
    (3 4)
    (1 4)
    (1 4)))
(test 'path*.1
  (run* x (path* x 6))
  '(2 3 1))
(test 'path*.2
  (run* y (path* 3 y))
  '(5 6 4))

(test 'path2*.0
  (run* (x y) (path2* x y))
  '((1 1)
    (1 2)
    (1 3)
    (2 4)
    (2 6)
    (3 5)
    (3 6)
    (6 4)
    (1 2)
    (1 3)
    (1 4)
    (1 6)
    (1 5)
    (1 6)
    (2 4)
    (3 4)
    (1 4)
    (1 6)
    (1 5)
    (1 6)
    (1 4)
    (1 4)
    (1 4)
    (1 4)))
(test 'path2*.1
  (run* x (path2* x 6))
  '(2 3 1 1 1 1))
(test 'path2*.2
  (run* y (path2* 3 y))
  '(5 6 4))

(test 'path2*.set.0
  (run*/set (x y) (path2* x y))
  (list->set '((1 1)
               (1 2)
               (1 3)
               (2 4)
               (2 6)
               (3 5)
               (3 6)
               (6 4)
               (1 2)
               (1 3)
               (1 4)
               (1 6)
               (1 5)
               (1 6)
               (2 4)
               (3 4)
               (1 4)
               (1 6)
               (1 5)
               (1 6)
               (1 4)
               (1 4)
               (1 4)
               (1 4))))
(test 'path2*.set.1
  (run*/set x (path2* x 6))
  (list->set '(2 3 1 1 1 1)))
(test 'path2*.set.2
  (run*/set y (path2* 3 y))
  (list->set '(5 6 4)))

(test 'path3*.0
  (run* (x y) (path3* x y))
  '((1 1)
    (1 2)
    (1 3)
    (2 4)
    (2 6)
    (3 5)
    (3 6)
    (6 4)
    (1 4)
    (1 6)
    (1 5)
    (1 6)
    (2 4)
    (3 4)
    (1 4)
    (1 4)))
(test 'path3*.1
  (run* x (path3* x 6))
  '(2 3 1 1))
(test 'path3*.2
  (run* y (path3* 3 y))
  '(5 6 4))

(define-relation (edge/cycle a b)
  (conde ((== a 5) (== b 1))
         ((edge a b))))
(define-relation (path/cycle* a c)
  (conde ((edge/cycle a c))
         ((fresh (b)
            (=/= a b)
            (edge/cycle a b)
            (path/cycle* b c)))))
(test 'path/cycle*.0
  (run* (x y) (path/cycle* x y))
  '((5 1)
    (1 1)
    (1 2)
    (1 3)
    (2 4)
    (2 6)
    (3 5)
    (3 6)
    (6 4)
    (5 1)
    (5 2)
    (5 3)
    (3 1)
    (5 4)
    (5 6)
    (5 5)
    (5 6)
    (1 4)
    (1 6)
    (1 5)
    (1 6)
    (2 4)
    (3 4)
    (5 4)
    (5 4)
    (3 1)
    (3 2)
    (3 3)
    (1 1)
    (3 4)
    (3 6)
    (1 4)
    (1 4)
    (3 4)))
(test 'path/cycle*.1
  (run* x (path/cycle* x 6))
  '(2 3 5 1 3))
(test 'path/cycle*.2
  (run* y (path/cycle* 3 y))
  '(5 6 1 4 1 2 3 4 6 4))

(test 'path/cycle*.set.0
  (run*/set (x y) (path/cycle* x y))
  (list->set '((5 1)
               (1 1)
               (1 2)
               (1 3)
               (2 4)
               (2 6)
               (3 5)
               (3 6)
               (6 4)
               (5 1)
               (5 2)
               (5 3)
               (3 1)
               (5 4)
               (5 6)
               (5 5)
               (5 6)
               (1 4)
               (1 6)
               (1 5)
               (1 6)
               (2 4)
               (3 4)
               (5 1)
               (5 4)
               (5 4)
               (1 1)
               (5 1)
               (5 2)
               (5 3)
               (3 1)
               (3 2)
               (3 3)
               (1 4)
               (1 4))))
(test 'path/cycle*.set.1
  (run*/set x (path/cycle* x 6))
  (list->set '(2 3 1 5 5 3 3)))
(test 'path/cycle*.set.2
  (run*/set y (path/cycle* 3 y))
  (list->set '(5 6 1 4 1 2 3 4 6 5 6 1 4 4 1 2 3 4 6 5 6 1 4 4 1 2 3)))

;; Using list->set on a run result is not the same as using run/set:
;; run/set guarantees that the result has 10 unique answers before stopping
(test 'path/cycle*.set.n.0
  (list->set (run 10 (x y) (path/cycle* x y)))
  (list->set '((1 1) (1 2) (1 3) (3 6) (6 4) (2 4) (5 1) (3 5) (2 6))))
(test 'path/cycle*.set.n.1
  (run/set 10 (x y) (path/cycle* x y))
  (list->set '((1 1) (1 2) (1 3) (5 2) (3 6) (6 4) (2 4) (5 1) (3 5) (2 6))))

;; Simple relational interpreter tests

(define-relation (eval-expo expr env value)
  (conde
    ((fresh (body)
       (== `(lambda ,body) expr)
       (== `(closure ,body ,env) value)))
    ((== `(quote ,value) expr))
    ((fresh (a*)
       (== `(list . ,a*) expr)
       (eval-listo a* env value)))
    ((fresh (a d va vd)
       (== `(cons ,a ,d) expr)
       (== `(,va . ,vd) value)
       (eval-expo a env va)
       (eval-expo d env vd)))
    ((fresh (index)
       (== `(var ,index) expr)
       (lookupo index env value)))
    ((fresh (rator rand arg env^ body)
       (== `(app ,rator ,rand) expr)
       (eval-expo rator env `(closure ,body ,env^))
       (eval-expo rand env arg)
       (eval-expo body `(,arg . ,env^) value)))))

(define-relation (lookupo index env value)
  (fresh (arg e*)
    (== `(,arg . ,e*) env)
    (conde
      ((== '() index) (== arg value))
      ((fresh (i* a d)
         (== `(s . ,i*) index)
         (== `(,a . ,d) e*)
         (lookupo i* e* value))))))

(define-relation (eval-listo e* env value)
  (conde
    ((== '() e*) (== '() value))
    ((fresh (ea ed va vd)
       (== `(,ea . ,ed) e*)
       (== `(,va . ,vd) value)
       (eval-expo ea env va)
       (eval-listo ed env vd)))))

(define (evalo expr value) (eval-expo expr '() value))

(test 'evalo-literal
  (run 1 e (evalo e 5))
  '((quote 5)))

;; ~600 ms
(test 'evalo-quine
  (time (run 1 e (evalo e e)))
  '((app (lambda (list (quote app) (var ())
                       (list (quote quote) (var ()))))
         (quote (lambda (list (quote app) (var ())
                              (list (quote quote) (var ()))))))))

;; ~5500 ms
;(test 'evalo-twine
;  (time (run 1 (p q) (evalo p q) (evalo q p)))
;  '(((quote (app (lambda (list (quote quote)
;                               (list (quote app) (var ())
;                                     (list (quote quote) (var ())))))
;                 (quote (lambda (list (quote quote)
;                                      (list (quote app) (var ())
;                                            (list (quote quote) (var ()))))))))
;     (app (lambda (list (quote quote)
;                        (list (quote app) (var ())
;                              (list (quote quote) (var ())))))
;          (quote (lambda (list (quote quote)
;                               (list (quote app) (var ())
;                                     (list (quote quote) (var ()))))))))))

;; ~24000 ms
;(test 'evalo-thrine
;  (time (run 1 (p q r) (evalo p q) (evalo q r) (evalo r p)))
;  '(((quote (quote (app (lambda (list (quote quote)
;                                      (list (quote quote)
;                                            (list (quote app) (var ())
;                                                  (list (quote quote) (var ()))))))
;                        (quote (lambda (list (quote quote)
;                                             (list (quote quote)
;                                                   (list (quote app) (var ())
;                                                         (list (quote quote) (var ()))))))))))
;     (quote (app (lambda (list (quote quote)
;                               (list (quote quote)
;                                     (list (quote app) (var ())
;                                           (list (quote quote) (var ()))))))
;                 (quote (lambda (list (quote quote)
;                                      (list (quote quote)
;                                            (list (quote app) (var ())
;                                                  (list (quote quote) (var ())))))))))
;     (app (lambda (list (quote quote)
;                        (list (quote quote)
;                              (list (quote app) (var ())
;                                    (list (quote quote) (var ()))))))
;          (quote (lambda (list (quote quote)
;                               (list (quote quote)
;                                     (list (quote app) (var ())
;                                           (list (quote quote) (var ())))))))))))
