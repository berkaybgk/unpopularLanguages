;berkay bugra gok
;2021400258
;compiling: yes
;complete: yes
#lang racket

(provide (all-defined-out))

;;1;;
(define (binary_to_decimal binary)
  (define (char->digit c)
    (cond ((char=? c #\0) 0)
          ((char=? c #\1) 1)
          (else (error))))
  (let loop ((chars (string->list binary)) (result 0) (length 0))
    (if (null? chars)
        result
        (let* ((last-char (car (reverse chars)))
               (remaining-chars (reverse (cdr (reverse chars))))
               (digit (char->digit last-char)))
          (loop remaining-chars (+ result (* digit (expt 2 length))) (+ length 1))))))


;;2;;
(define (relocator args limit base)
  (define (map-address address)
    (let ((decimal-address (binary_to_decimal address)))
      (if (> decimal-address limit)
          -1
          (+ decimal-address base))))
  (map map-address args))


;;3;;
(define (divide_address_space num page_size)
  (let* ((page_size_bytes (* page_size 1024))
         (page_bits (inexact->exact (ceiling (/ (log page_size_bytes) (log 2)))))
         (address-length (string-length num))
         (page-number (substring num 0 (- address-length page_bits)))
         (page-offset (substring num (- address-length page_bits) address-length)))
    (list page-number page-offset)))


;;4;;
(define (page args page_table page_size)
  (map (lambda (logical_address)
         (let* ((divided-address (divide_address_space logical_address page_size))
                (page-number (car divided-address))
                (page-offset (cadr divided-address))
                (page-index (binary_to_decimal page-number))
                (frame-number (list-ref page_table page-index)))
           (string-append frame-number page-offset)))
       args))


;;5;;
(define (factorial n)
  (if (= n 0)
      1
      (* n (factorial (- n 1)))))

(define (radians degrees)
  (* (/ degrees 180) pi))

(define (find_sin value num)
  (define (term x n)
    (let ((exp (expt x (+ (* 2 n) 1)))
          (fact (factorial (+ (* 2 n) 1))))
      (/ (* (expt -1 n) exp) fact)))
  
  (let* ((angle-radians (radians value))
         (x angle-radians))
    (let loop ((n 0) (result 0))
      (if (>= n num)
          result
          (let* ((next-term (term x n))
                 (new-result (+ result next-term)))
            (loop (+ n 1) new-result))))))


;;6;;
(define (char->digit c)
  (- (char->integer c) (char->integer #\0)))

(define (sum_first_ten_digits value)
  (let* ((str (number->string value))
         (index-of-dot (string-index str #\.)))
    (if index-of-dot
        (let ((after-decimal (substring str (+ index-of-dot 1))))
          (let loop ((chars (string->list after-decimal)) (count 0) (sum 0))
            (if (or (null? chars) (>= count 10))
                sum
                (let ((digit (char->digit (car chars))))
                  (loop (cdr chars) (+ count 1) (+ sum digit))))))
        0)))

(define (string-index str char)
  (let loop ((chars (string->list str)) (index 0))
    (cond ((null? chars) #f)
          ((char=? (car chars) char) index)
          (else (loop (cdr chars) (+ index 1))))))

(define (myhash arg table_size)
  (let* ((decimal (binary_to_decimal arg))
         (n (+ (modulo decimal 5) 1))
         (sin-value (find_sin decimal n))
         (sum-digits (sum_first_ten_digits sin-value)))
    (modulo sum-digits table_size)))


;;7;;
(define (hashed_page arg table_size page_table page_size)
  (let* ((divided (divide_address_space arg page_size))
         (page-number (car divided))
         (page-offset (cadr divided))
         (hash-index (myhash page-number table_size))
         (bucket (list-ref page_table hash-index))
         (frame-number (cadr (assoc page-number bucket))))
    (string-append frame-number page-offset)))
 

;;8;;
(define (split_addresses args size)
  (define (loop args)
    (if (<= (string-length args) 0)
        '()
        (let ((chunk-size (min size (string-length args))))
          (cons (substring args 0 chunk-size)
                (loop (substring args chunk-size))))))
  (loop args))


;;9;;
(define (map_addresses args table_size page_table page_size address_space_size)
  (let ((logical-addresses (split_addresses args address_space_size)))
    (map (lambda (addr) (hashed_page addr table_size page_table page_size))
         logical-addresses)))

