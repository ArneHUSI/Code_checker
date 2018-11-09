; This file contains various errors that are to be detected by the code checker

(define var 4)

(define VAR 5)

(define-struct bla [x y z])

(define Bla (make-bla 1 2 3))

(define BLA (make-bla 1 2 3))

(define B_L_A (make-bla 1 2 3))

(define bla (make-bla 1 2 3))

; Interpretation: Some other struct Blubb

(define-struct blubb [r s])

(define (func_without_sign r) (* 4 5 ))

; number -> number
(define (func_with_sign r) (* 4 5 ))

; func_withWrong_sign: number -> number
(define (func_withWrong_sign r s) (* 4 5 ))

; func_withWrong_sign: number number -> number
(define (func_withWrong_sign r) (* 4 5 ))

; func_withWrong_sign: number number --> number
(define (func_withWrong_sign r s) (* 4 5 ))

; func: [T1 -> T2] T1 -> T2
(define (f g h) (g h))

; List<City> View -> List<CityPlot>
; The position is scaled using the given view window.
; For example, if the view is (make-view 10 10 20 20) then a city at
; (make-city 10 10 ...) is drawn at 0,HEIGHT
(define (rescale-cities cities view) ())

; Zoom View -> View
; Returns a new view resulting from zooming into the given view.
; Here it's important that zoom-x1 < zoom-x2 so we use the min and max functions.
; Notice that y pixel coordinates (in the zoom) grow down and
; latitudes (in the view) grow up.
(define (zoom-view zoom view)
  (local [(define zx1 (min (zoom-x1 zoom) (zoom-x2 zoom)))
          (define zx2 (max (zoom-x1 zoom) (zoom-x2 zoom)))
          (define zy1 (min (zoom-y1 zoom) (zoom-y2 zoom)))
          (define zy2 (max (zoom-y1 zoom) (zoom-y2 zoom)))]
         (make-view ; order of y2,y1 is diff then x1,x2 because y2 < y1
           (screen->long zx1 view)
           (screen->lat zy2 view)
           (screen->long zx2 view)
           (screen->lat zy1 view))))
